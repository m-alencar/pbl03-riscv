`ifndef RISCV_ENV
`define RISCV_ENV

class riscv_environment extends uvm_env;

  riscv_agent                   riscv_agnt;
  riscv_ref_model               ref_model;
  riscv_coverage #(riscv_trace) coverage;
  riscv_scoreboard              sb;

  `uvm_component_utils(riscv_environment)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    riscv_agnt = riscv_agent::type_id::create("riscv_agnt", this);
    ref_model  = riscv_ref_model::type_id::create("ref_model", this);
    coverage   = riscv_coverage#(riscv_trace)::type_id::create("coverage", this);
    sb         = riscv_scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    riscv_agnt.drv2rm_port.connect(ref_model.prog_export);     // programa -> ISS
    ref_model.rm2sb_port.connect(sb.exp_export);               // esperado -> scoreboard
    riscv_agnt.mon2sb_port.connect(sb.act_export);             // observado -> scoreboard
    ref_model.rm2sb_port.connect(coverage.analysis_export);    // esperado -> cobertura
  endfunction

endclass : riscv_environment

`endif
