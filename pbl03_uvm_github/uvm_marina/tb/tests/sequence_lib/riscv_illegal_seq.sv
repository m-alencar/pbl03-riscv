//------------------------------------------------------------------------------
// Sequencia de instrucoes FORA do perfil do DUT (e de encodings invalidos).
// Comportamento especificado pelo projeto: instrucao nao suportada e IGNORADA
// (PC+4, nenhum registrador ou memoria muda). O ISS aplica essa regra a tudo
// que rv_supported() recusa. Um programa por candidata:
//   prologo fixo (x1..x29 conhecidos) ; candidata ; marcador (x6=77) ; despejo de x0..x29 ; fim
// Se o DUT executar a candidata (escrever x5, desviar, ...), o trace diverge.
//------------------------------------------------------------------------------
`ifndef RISCV_ILLEGAL_SEQ
`define RISCV_ILLEGAL_SEQ

class riscv_illegal_seq extends uvm_sequence #(riscv_program);

  `uvm_object_utils(riscv_illegal_seq)

  function new(string name = "riscv_illegal_seq");
    super.new(name);
  endfunction

  // candidatas: {nome, palavra}
  function void candidates(ref string names[$], ref bit [31:0] words[$]);
    names.push_back("sub");      words.push_back(rv_sub (5, 1, 3));
    names.push_back("or");       words.push_back(rv_or  (5, 1, 3));
    names.push_back("slli");     words.push_back(rv_slli(5, 1, 4));
    names.push_back("lb");       words.push_back(rv_lb  (5, 31, 0));
    names.push_back("lbu");      words.push_back(rv_lbu (5, 31, 0));
    names.push_back("xori");     words.push_back(rv_xori(5, 1, 255));
    names.push_back("bltu");     words.push_back(rv_bltu(3, 2, 8));   // 5 < 0xFFFFFFFF: tomado se executado
    names.push_back("blt");      words.push_back(rv_blt (2, 3, 8));   // -1 < 5: tomado se executado
    names.push_back("bgeu");     words.push_back(rv_b(8, 3, 2, 3'b111));
    names.push_back("ecall");    words.push_back(rv_ecall());
    names.push_back("ebreak");   words.push_back(32'h0010_0073);
    names.push_back("srai");     words.push_back(rv_i(32'h404, 2, 3'b101, 5, 7'b0010011));
    names.push_back("sll");      words.push_back(rv_r(7'b0000000, 3, 1, 3'b001, 5, 7'b0110011));
    names.push_back("slt");      words.push_back(rv_r(7'b0000000, 3, 1, 3'b010, 5, 7'b0110011));
    names.push_back("mul");      words.push_back(rv_r(7'b0000001, 3, 1, 3'b000, 5, 7'b0110011));
    names.push_back("sh");       words.push_back(rv_s(0, 3, 31, 3'b001));
    names.push_back("lh");       words.push_back(rv_i(0, 31, 3'b001, 5, 7'b0000011));
    names.push_back("jalr_f3");  words.push_back(rv_i(0, 31, 3'b001, 5, 7'b1100111));
  endfunction

  virtual task body();
    string names[$];
    bit [31:0] cand[$];
    riscv_program p;
    candidates(names, cand);

    foreach (cand[k]) begin
      // so as que o perfil NAO suporta (as suportadas ja sao exercitadas nos outros testes)
      if (rv_supported(rv_decode(cand[k]))) continue;

      p = riscv_program::type_id::create({"ilegal_", names[k]});
      p.words.delete();
      // prologo: valores conhecidos em x1..x29 (nada fica X no despejo)
      p.words.push_back(rv_lui (1, 32'h12345));
      p.words.push_back(rv_addi(1, 1, 32'h678));      // x1 = 0x12345678
      p.words.push_back(rv_addi(2, 0, -1));           // x2 = 0xFFFFFFFF
      p.words.push_back(rv_addi(3, 0, 5));            // x3 = 5
      for (int r = 4; r <= 29; r++) p.words.push_back(rv_addi(r, 0, 100 + r));
      p.words.push_back(rv_addi(5, 0, 0));            // x5 = 0 (destino da candidata)
      p.words.push_back(rv_addi(31, 0, `RV_DATA_BASE));
      // candidata + marcador
      p.words.push_back(cand[k]);
      p.words.push_back(rv_addi(6, 0, 77));           // marcador: x6 = 77 se o fluxo seguiu normal
      // despejo + fim
      for (int r = 0; r <= 29; r++) p.words.push_back(rv_sw(r, 31, `RV_DUMP_OFFSET + 4*r));
      p.words.push_back(rv_end());

      p.tag = {"ilegal:", names[k]};
      p.max_cycles = p.words.size() + 100;
      start_item(p);
      finish_item(p);
    end
  endtask

endclass

`endif
