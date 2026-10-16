`ifndef RISCV_ENV_PKG
`define RISCV_ENV_PKG

package riscv_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import riscv_agent_pkg::*;
  import riscv_ref_model_pkg::*;

  `include "riscv_defines.svh"
  `include "riscv_coverage.sv"
  `include "riscv_scoreboard.sv"
  `include "riscv_env.sv"

endpackage

`endif
