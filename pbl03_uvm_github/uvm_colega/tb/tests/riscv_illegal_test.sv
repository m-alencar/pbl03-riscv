//------------------------------------------------------------------------------
// riscv_illegal_test: instrucoes nao suportadas devem ser ignoradas
//------------------------------------------------------------------------------
`ifndef RISCV_ILLEGAL_TEST
`define RISCV_ILLEGAL_TEST

class riscv_illegal_test extends uvm_test;

  `uvm_component_utils(riscv_illegal_test)

  riscv_environment  env;
  riscv_illegal_seq  seq;

  function new(string name = "riscv_illegal_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = riscv_environment::type_id::create("env", this);
    seq = riscv_illegal_seq::type_id::create("seq");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.riscv_agnt.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask

endclass : riscv_illegal_test

`endif
