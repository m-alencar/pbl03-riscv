//------------------------------------------------------------------------------
// riscv_random_test: programas aleatorios (muda a semente para explorar mais)
//------------------------------------------------------------------------------
`ifndef RISCV_RANDOM_TEST
`define RISCV_RANDOM_TEST

class riscv_random_test extends uvm_test;

  `uvm_component_utils(riscv_random_test)

  riscv_environment env;
  riscv_random_seq  seq;

  function new(string name = "riscv_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = riscv_environment::type_id::create("env", this);
    seq = riscv_random_seq::type_id::create("seq");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.riscv_agnt.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask

endclass : riscv_random_test

`endif
