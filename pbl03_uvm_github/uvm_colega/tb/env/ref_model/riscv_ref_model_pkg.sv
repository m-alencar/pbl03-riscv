`ifndef RISCV_REF_MODEL_PKG
`define RISCV_REF_MODEL_PKG

package riscv_ref_model_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import riscv_agent_pkg::*;

  `include "riscv_defines.svh"
  `include "riscv_ref_model.sv"

endpackage

`endif
