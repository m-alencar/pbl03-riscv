// ============================================================
// genius_tb.sv — Testbench que JOGA o Genius no nosso processador
//
// Instancia o SoC (nucleo + memorias + perifericos) e faz o papel
// do jogador: mexe nos switches e aperta o D-Pad. Para cada cenario
// confere (1) a sequencia de cores que o jogo mostrou nos LEDs contra
// um modelo de referencia (LFSR), (2) a pontuacao impressa no ecall
// e (3) o tamanho maximo da sequencia (registrador s3).
//
// NAO e o ambiente UVM (Frente 2); e a validacao funcional do nucleo
// rodando o programa real do PBL02.
//
// Enderecos dos labels = genius/genius.sym (gerados por build_genius.sh)
// ============================================================
`timescale 1ns/1ps

module genius_tb;
    localparam [31:0] ADDR_NOVA_LUZ = 32'h0000_0050;  // label nova_luz
    localparam [31:0] ADDR_ESPERA   = 32'h0000_0088;  // label espera_jogador
    localparam int    MAXC          = 2000000;        // limite de ciclos por cenario

    logic        clk = 0, reset;
    logic [4:0]  switches;
    logic [3:0]  dpad_btn;
    logic [95:0] leds;
    logic        ecall;

    genius_soc dut(
        .clk(clk), .reset(reset),
        .switches(switches), .dpad_btn(dpad_btn),
        .leds(leds), .ECall(ecall)
    );

    always #5 clk = ~clk;   // 10 ns

    // ---------------- estado de observacao ----------------
    int   cyc = 0;
    bit   done = 0;
    int   score = -1;
    int   shown [0:63];
    int   n_shown = 0;
    bit   verbose = 0;
    logic [3:0] led_prev = 4'b0;

    always @(posedge clk)
        if (reset) cyc <= 0; else cyc <= cyc + 1;

    function automatic string cor(input int i);
        case (i)
            0:       cor = "UP/vermelho";
            1:       cor = "DOWN/verde";
            2:       cor = "LEFT/azul";
            default: cor = "RIGHT/amarelo";
        endcase
    endfunction

    // modelo de referencia do gerador de cores do modo "Siga" (LFSR 8 bits, semente 0xA5)
    function automatic int exp_color(input int k);
        logic [7:0] s;
        logic       t;
        s = 8'hA5;
        for (int j = 0; j <= k; j++) begin
            t = s[7] ^ s[5] ^ s[4] ^ s[3];
            s = {s[6:0], t};
        end
        return int'(s[1:0]);
    endfunction

    // monitor dos LEDs: registra cada cor que o jogo acende
    always @(posedge clk) begin
        for (int i = 0; i < 4; i++) begin
            if ((|leds[24*i +: 24]) && !led_prev[i]) begin
                shown[n_shown] = i;
                n_shown = n_shown + 1;
                if (verbose) $display("  [%0t ns] LED %0d acende: %s", $time/1000, i, cor(i));
            end
            led_prev[i] <= |leds[24*i +: 24];
        end
    end

    // monitor do ecall (a7 = 1 -> "imprime inteiro" = pontuacao em a0)
    always @(posedge clk)
        if (!reset && ecall && !done && dut.rv.dp.rf.rf[17] == 32'd1) begin
            score = dut.rv.dp.rf.rf[10];
            done  = 1;
            if (verbose) $display("  [%0t ns] ECALL: jogo terminou, pontuacao impressa = %0d", $time/1000, score);
        end

    // ---------------- acoes do "jogador" ----------------
    task automatic press(input int d);
        @(posedge clk); #1 dpad_btn = 4'b0001 << d;
        @(posedge clk); #1 dpad_btn = 4'b0000;
        if (verbose) $display("  [%0t ns] jogador aperta %s", $time/1000, cor(d));
    endtask

    task automatic wait_consumed(input int d);
        do @(posedge clk); while (dut.pp.latch[d] && !done && cyc < MAXC);
    endtask

    task automatic wait_pc(input [31:0] a1, input [31:0] a2);
        do @(posedge clk); while (!done && cyc < MAXC && dut.PC !== a1 && dut.PC !== a2);
    endtask

    // ---------------- cenarios ----------------
    int s_mode, s_diff, s_speed, s_err_round, s_exp_score, s_exp_s3;
    int picks [0:7];
    int pass_cnt = 0, fail_cnt = 0;

    task automatic run_scenario(input string name);
        int  rc, n, k, d, mism;
        int  seqc [0:63];
        bit  err_injected, ok, timeout;

        $display("\n=== %s ===", name);
        done = 0; score = -1; n_shown = 0; mism = 0; rc = 0; err_injected = 0;
        reset = 1; dpad_btn = 0;
        switches = {1'b1, s_mode[0], s_speed[0], s_diff[1:0]};   // bit4 = inicio
        repeat (4) @(posedge clk);
        #1 reset = 0;

        while (!done && cyc < MAXC) begin
            wait_pc(ADDR_ESPERA, (s_mode == 1) ? ADDR_NOVA_LUZ : ADDR_ESPERA);
            if (!(done || cyc >= MAXC)) begin
            if (s_mode == 1 && dut.PC === ADDR_NOVA_LUZ) begin
                // modo "Mando eu": o jogador escolhe a proxima cor
                press(picks[rc]);
                wait_consumed(picks[rc]);
                n_shown = 0;
            end else begin
                // o jogo terminou de mostrar a sequencia: confere e repete
                n = n_shown;
                for (k = 0; k < n; k++) seqc[k] = shown[k];
                if (n != rc + 1) begin
                    mism++;
                    $display("  DIVERGENCIA: tamanho mostrado=%0d, esperado=%0d", n, rc + 1);
                end
                for (k = 0; k < n; k++) begin
                    if (s_mode == 0 && seqc[k] != exp_color(k)) begin
                        mism++;
                        $display("  DIVERGENCIA: cor %0d mostrada=%s esperada=%s", k, cor(seqc[k]), cor(exp_color(k)));
                    end
                    if (s_mode == 1 && seqc[k] != picks[k]) begin
                        mism++;
                        $display("  DIVERGENCIA: cor %0d mostrada=%s escolhida=%s", k, cor(seqc[k]), cor(picks[k]));
                    end
                end
                for (k = 0; k < n && !done && !err_injected; k++) begin
                    d = seqc[k];
                    if (s_err_round == n && k == 0) begin
                        d = (seqc[k] + 1) % 4;       // aperta a direcao errada de proposito
                        err_injected = 1;
                    end
                    press(d);
                    wait_consumed(d);
                    if (!err_injected) begin
                        if (k < n - 1) wait_pc(ADDR_ESPERA, ADDR_ESPERA);
                        else begin n_shown = 0; rc++; end
                    end
                end
            end
            end
        end

        timeout = (cyc >= MAXC) && !done;
        ok = !timeout && (score == s_exp_score) && (mism == 0) &&
             (dut.rv.dp.rf.rf[19] == s_exp_s3);
        $display("  pontuacao = %0d (esperado %0d) | tamanho max s3 = %0d (esperado %0d) | divergencias = %0d%s",
                 score, s_exp_score, dut.rv.dp.rf.rf[19], s_exp_s3, mism, timeout ? " | TIMEOUT" : "");
        $display("  >>> %s: %s", name, ok ? "PASSOU" : "FALHOU");
        if (ok) pass_cnt++; else fail_cnt++;

        switches = 5'b0;                 // desliga o switch de inicio
        repeat (3) @(posedge clk);
        verbose = 0;
    endtask

    initial begin
        reset = 1; dpad_btn = 0; switches = 0;
        #2;
        // confere que os enderecos dos labels deste arquivo batem com o genius.hex
        if (dut.imem1.RAM[ADDR_ESPERA >> 2][6:0]   !== 7'b0010111 ||
            dut.imem1.RAM[ADDR_NOVA_LUZ >> 2][6:0] !== 7'b0010111 ||
            dut.imem1.RAM[0] !== 32'h0000_4137) begin
            $display("ERRO: genius.hex nao encontrado ou labels desatualizados (ver genius/genius.sym).");
            $finish;
        end
        $display("Genius no nucleo RISC-V (PBL03) - %0d palavras de programa carregadas", 161);

        // 1) Siga, facil, lento, jogador perfeito ate o fim (8 cores): 1+2+...+8 acertos x peso 1
        s_mode=0; s_diff=0; s_speed=0; s_err_round=0; s_exp_score=36; s_exp_s3=8;
        run_scenario("Cenario 1: modo Siga, facil, lento, partida completa (8 rodadas)");

        // 2) Siga, facil, rapido, erro na rodada 3: (1+2) acertos x peso 1 x 2 (rapido)
        s_mode=0; s_diff=0; s_speed=1; s_err_round=3; s_exp_score=6; s_exp_s3=8;
        verbose = 1;
        run_scenario("Cenario 2: modo Siga, facil, rapido, erro de proposito na rodada 3");

        // 3) Siga, medio, rapido, partida completa (16 rodadas): 136 acertos x peso 2 x 2
        s_mode=0; s_diff=1; s_speed=1; s_err_round=0; s_exp_score=544; s_exp_s3=16;
        run_scenario("Cenario 3: modo Siga, medio, rapido, partida completa (16 rodadas)");

        // 4) Siga, dificil, lento, erro na rodada 2: 1 acerto x peso 3
        s_mode=0; s_diff=2; s_speed=0; s_err_round=2; s_exp_score=3; s_exp_s3=32;
        run_scenario("Cenario 4: modo Siga, dificil, lento, erro de proposito na rodada 2");

        // 5) Mando eu, facil, lento: jogador escolhe UP, RIGHT, DOWN; erra na rodada 3
        s_mode=1; s_diff=0; s_speed=0; s_err_round=3; s_exp_score=3; s_exp_s3=8;
        picks[0]=0; picks[1]=3; picks[2]=1;
        verbose = 1;
        run_scenario("Cenario 5: modo Mando eu, facil, lento, erro de proposito na rodada 3");

        $display("\n==========================================");
        $display(" RESULTADO: %0d cenarios passaram, %0d falharam", pass_cnt, fail_cnt);
        $display("==========================================");
        $finish;
    end
endmodule
