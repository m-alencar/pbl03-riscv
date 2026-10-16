`ifndef RISCV_SEQUENCER
`define RISCV_SEQUENCER

class riscv_sequencer extends uvm_sequencer#(riscv_program);

  `uvm_component_utils(riscv_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif
