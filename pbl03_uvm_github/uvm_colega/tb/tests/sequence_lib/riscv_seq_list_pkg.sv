`ifndef RISCV_SEQ_LIST_PKG
`define RISCV_SEQ_LIST_PKG

package riscv_seq_list_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import riscv_agent_pkg::*;
  import riscv_ref_model_pkg::*;
  import riscv_env_pkg::*;

  `include "riscv_defines.svh"
  `include "riscv_directed_seq.sv"
  `include "riscv_random_seq.sv"
  `include "riscv_illegal_seq.sv"

endpackage

`endif
