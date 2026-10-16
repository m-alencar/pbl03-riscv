//------------------------------------------------------------------------------
// Sequencia dirigida: 3 programas pequenos e conhecidos.
// Nao ha valores esperados escritos aqui: quem diz o resultado certo e o ISS.
//------------------------------------------------------------------------------
`ifndef RISCV_DIRECTED_SEQ
`define RISCV_DIRECTED_SEQ

class riscv_directed_seq extends uvm_sequence #(riscv_program);

  `uvm_object_utils(riscv_directed_seq)

  function new(string name = "riscv_directed_seq");
    super.new(name);
  endfunction

  task send(riscv_program p, string tag);
    p.tag = tag;
    p.max_cycles = 300;
    start_item(p);
    finish_item(p);
  endtask

  virtual task body();
    riscv_program p;

    // 1) aritmetica, logica, deslocamentos, auipc, sw/sb/lw/lb
    p = riscv_program::type_id::create("p_arith");
    p.words = '{
      rv_lui  (1, 32'h12345),        // x1 = 0x12345000
      rv_addi (1, 1, 32'h678),       // x1 = 0x12345678
      rv_addi (2, 0, -3),            // x2 = -3
      rv_add  (3, 1, 2),
      rv_sub  (4, 1, 2),
      rv_and  (5, 1, 2),
      rv_or   (6, 1, 2),
      rv_xor  (7, 1, 2),
      rv_slli (8, 1, 4),
      rv_srli (9, 2, 8),             // srl logico sobre numero negativo
      rv_andi (10, 1, 32'hFF),
      rv_auipc(11, 1),
      rv_sw   (3, 0, 256),
      rv_sb   (2, 0, 260),
      rv_lw   (12, 0, 256),
      rv_lb   (13, 0, 260),          // byte 0xFD: extensao de sinal
      rv_addi (0, 1, 5),             // escrita em x0 deve ser ignorada
      rv_add  (14, 0, 0),
      rv_end()
    };
    send(p, "arith");

    // 2) laco com desvio para tras: soma 5+4+3+2+1
    p = riscv_program::type_id::create("p_loop");
    p.words = '{
      rv_addi (1, 0, 5),             //  0: contador
      rv_addi (2, 0, 0),             //  4: soma
      rv_add  (2, 2, 1),             //  8: soma += contador
      rv_addi (1, 1, -1),            // 12: contador--
      rv_bne  (1, 0, -8),            // 16: volta para 8 enquanto contador != 0
      rv_sw   (2, 0, 0),             // 20
      rv_end()                     // 24
    };
    send(p, "loop");

    // 3) chamada e retorno (jal/jalr) + bge/bltu
    p = riscv_program::type_id::create("p_call");
    p.words = '{
      rv_addi (5, 0, 7),             //  0
      rv_jal  (1, 12),               //  4: chama a sub-rotina em 16, x1 = 8
      rv_sw   (6, 0, 0),             //  8: volta aqui
      rv_end(),                    // 12
      rv_add  (6, 5, 5),             // 16: sub-rotina: x6 = 14
      rv_jalr (0, 1, 0)              // 20: retorna para x1 (=8)
    };
    send(p, "call");

    p = riscv_program::type_id::create("p_branch");
    p.words = '{
      rv_addi (1, 0, -1),            //  0: x1 = 0xFFFFFFFF
      rv_addi (2, 0, 1),             //  4: x2 = 1
      rv_addi (3, 0, 0),             //  8: x3 = 0 (o regfile nao e zerado pelo reset!)
      rv_bge  (1, 2, 8),             // 12: -1 >= 1 ? (com sinal) nao -> segue para 16
      rv_bltu (2, 1, 8),             // 16: 1 < 0xFFFFFFFF ? (sem sinal) sim -> 24
      rv_addi (3, 0, 99),            // 20: nao deve executar
      rv_beq  (1, 1, 8),             // 24: sempre -> 32
      rv_addi (4, 0, 99),            // 28: nao deve executar
      rv_sw   (3, 0, 0),             // 32
      rv_end()                     // 36
    };
    send(p, "branch");
  endtask

endclass

`endif
