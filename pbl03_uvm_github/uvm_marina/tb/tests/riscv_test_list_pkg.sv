`ifndef RISCV_TEST_LIST_PKG
`define RISCV_TEST_LIST_PKG

package riscv_test_list_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import riscv_env_pkg::*;
  import riscv_agent_pkg::*;
  import riscv_seq_list_pkg::*;

  `include "riscv_basic_test.sv"
  `include "riscv_random_test.sv"
  `include "riscv_illegal_test.sv"

endpackage

`endif
