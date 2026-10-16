//------------------------------------------------------------------------------
// riscv_basic_test: roda os programas dirigidos (sanidade do ambiente e do DUT)
//------------------------------------------------------------------------------
`ifndef RISCV_BASIC_TEST
`define RISCV_BASIC_TEST

class riscv_basic_test extends uvm_test;

  `uvm_component_utils(riscv_basic_test)

  riscv_environment  env;
  riscv_directed_seq seq;

  function new(string name = "riscv_basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = riscv_environment::type_id::create("env", this);
    seq = riscv_directed_seq::type_id::create("seq");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.riscv_agnt.sequencer);
    #100ns;                       // deixa monitor e scoreboard terminarem
    phase.drop_objection(this);
  endtask

endclass : riscv_basic_test

`endif
