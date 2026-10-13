// ============================================================
// genius_periph.sv — Periféricos mapeados em memoria (modelo de simulacao)
//
// Reproduz, para o nosso nucleo, os 4 perifericos que o Ripes oferecia
// ao programa Genius do PBL02. Regiao de I/O: enderecos 0xF000_0xxx.
//
//   0xF0000000 + 4*i  LED Matrix   (i=0..3)  escrita: cor RGB de 24 bits
//   0xF0000100        Switches                leitura: bits [4:0]
//   0xF0000200 + 4*d  D-Pad (d=0 UP,1 DOWN,2 LEFT,3 RIGHT)
//                                             leitura: 1 se houve clique
//                                             desde a ultima leitura
//                                             (captura de borda; a leitura limpa)
//   0xF0000300        RTC                     leitura: tempo em "ns"
//
// RTC_STEP: quanto o RTC avanca por ciclo de clock. Em hardware real o
// RTC avanca em tempo real; em simulacao usamos 1.000.000 ns/ciclo
// (1 ms por clock) para que um delay de 2 s custe so ~2000 ciclos.
// ============================================================
module genius_periph #(
    parameter RTC_STEP = 1000000
)(
    input  logic        clk, reset,
    // interface com o barramento de dados do processador
    input  logic        we,        // MemWrite
    input  logic        is_load,   // instrucao corrente e um load
    input  logic [31:0] addr,      // ALUResult
    input  logic [31:0] wdata,
    output logic        sel,       // endereco cai na regiao de I/O
    output logic [31:0] rdata,
    // "mundo externo" (controlado pelo testbench)
    input  logic [4:0]  switches,
    input  logic [3:0]  dpad_btn,  // pulso de 1 ciclo = clique
    output logic [95:0] leds       // 4 LEDs x 24 bits (LED i = leds[24*i +: 24])
);
    logic [3:0]  latch;
    logic [31:0] rtc;

    assign sel = (addr[31:28] == 4'hF);

    wire [3:0] page = addr[11:8];
    wire [1:0] idx  = addr[3:2];

    // leitura combinacional
    always_comb begin
        rdata = 32'b0;
        case (page)
            4'h1:    rdata = {27'b0, switches};
            4'h2:    rdata = {31'b0, latch[idx]};
            4'h3:    rdata = rtc;
            default: rdata = 32'b0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            latch <= 4'b0;
            rtc   <= 32'b0;
            leds  <= 96'b0;
        end else begin
            rtc <= rtc + RTC_STEP;

            // escrita nos LEDs
            if (we && sel && page == 4'h0)
                leds[24*idx +: 24] <= wdata[23:0];

            // D-Pad: o clique seta o latch; a leitura (lw) limpa
            for (int i = 0; i < 4; i++) begin
                if (dpad_btn[i])
                    latch[i] <= 1'b1;
                else if (is_load && sel && page == 4'h2 && idx == i)
                    latch[i] <= 1'b0;
            end
        end
    end
endmodule
