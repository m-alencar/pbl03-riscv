`ifndef RISCV_AGENT_PKG
`define RISCV_AGENT_PKG

package riscv_agent_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "riscv_defines.svh"
  `include "riscv_decode.svh"
  `include "riscv_encode.svh"
  `include "riscv_gen.svh"
  `include "riscv_program.sv"
  `include "riscv_trace.sv"
  `include "riscv_sequencer.sv"
  `include "riscv_driver.sv"
  `include "riscv_monitor.sv"
  `include "riscv_agent.sv"

endpackage

`endif
