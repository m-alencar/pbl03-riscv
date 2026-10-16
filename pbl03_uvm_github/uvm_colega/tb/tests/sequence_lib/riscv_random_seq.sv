//------------------------------------------------------------------------------
// Sequencia aleatoria: N programas gerados por randomize()
// N padrao = NO_OF_PROGRAMS; para mudar: -testplusarg "NUM_PROGS=200"
//------------------------------------------------------------------------------
`ifndef RISCV_RANDOM_SEQ
`define RISCV_RANDOM_SEQ

class riscv_random_seq extends uvm_sequence #(riscv_program);

  `uvm_object_utils(riscv_random_seq)

  function new(string name = "riscv_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    int n = `NO_OF_PROGRAMS;
    int found;
    found = $value$plusargs("NUM_PROGS=%d", n);
    for (int i = 0; i < n; i++) begin
      req = riscv_program::type_id::create($sformatf("rand_%0d", i));
      req.gen_random = 1;
      start_item(req);
      if (!req.randomize()) `uvm_fatal("RANDFAIL", "randomize() falhou")
      finish_item(req);
    end
  endtask

endclass

`endif
