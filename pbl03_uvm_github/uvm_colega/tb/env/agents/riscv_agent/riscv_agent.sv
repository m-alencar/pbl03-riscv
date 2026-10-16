`ifndef RISCV_AGENT
`define RISCV_AGENT

class riscv_agent extends uvm_agent;

  riscv_driver    driver;
  riscv_sequencer sequencer;
  riscv_monitor   monitor;

  uvm_analysis_port #(riscv_trace)   mon2sb_port;   // ciclos observados no DUT
  uvm_analysis_port #(riscv_program) drv2rm_port;   // programa que sera executado

  `uvm_component_utils(riscv_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon2sb_port = new("mon2sb_port", this);
    drv2rm_port = new("drv2rm_port", this);
    monitor = riscv_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = riscv_driver::type_id::create("driver", this);
      sequencer = riscv_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.mon2sb_port.connect(mon2sb_port);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.drv2rm_port.connect(drv2rm_port);
    end
  endfunction

endclass : riscv_agent

`endif
