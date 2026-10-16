//------------------------------------------------------------------------------
// riscv_program: item de ESTIMULO. Um item = um programa completo.
//------------------------------------------------------------------------------
// - Programas dirigidos: a sequencia preenche 'words' diretamente.
// - Programas aleatorios: gen_random=1 -> randomize() sorteia 'rnd' e 'rdata'
//   e post_randomize() monta o programa (prologo + corpo + epilogo).
//
// As regras do gerador estao em riscv_gen.svh (rv_gen_program).
//------------------------------------------------------------------------------
`ifndef RISCV_PROGRAM
`define RISCV_PROGRAM

class riscv_program extends uvm_sequence_item;

  // ---- o programa
  bit [31:0]   words[$];                      // instrucoes, a partir do endereco 0
  bit [7:0]    init_data[`RV_DMEM_BYTES];     // conteudo inicial da dmem (padrao 0)
  int unsigned max_cycles = 1000;             // limite de ciclos (timeout)
  string       tag = "prog";

  // ---- campos aleatorios
  bit               gen_random = 0;
  rand int unsigned n_body;                   // numero de instrucoes do corpo
  rand bit [31:0]   rnd[];                    // dados aleatorios para montar o programa
  rand bit [7:0]    rdata[256];               // dados iniciais da dmem (regiao do corpo)

  constraint c_n   { n_body inside {[`RV_MIN_BODY:`RV_MAX_BODY]}; }
  constraint c_rnd { rnd.size() == 4*n_body + 32; }
  constraint c_ord { solve n_body before rnd; }

  `uvm_object_utils(riscv_program)

  function new(string name = "riscv_program");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s: %0d instrucoes, max_cycles=%0d", tag, words.size(), max_cycles);
  endfunction

  function void post_randomize();
    if (gen_random) build_random();
  endfunction

  function void build_random();
    words = rv_gen_program(int'(n_body), rnd);
    tag   = "random";
    foreach (init_data[i]) init_data[i] = 8'h00;
    for (int i = 0; i < 256; i++) init_data[`RV_DATA_BASE + i] = rdata[i];
    max_cycles = words.size() + 100;
  endfunction

endclass

`endif
