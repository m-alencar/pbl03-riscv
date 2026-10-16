//------------------------------------------------------------------------------
// Testbench top do processador RISC-V (PBL03 - Frente 2)
//------------------------------------------------------------------------------
// Instancia o DUT, gera o clock, cria a interface e inicia as fases UVM.
// Adaptado de adder_tb_top.sv (verif-env-template).
//------------------------------------------------------------------------------

`ifndef RISCV_TB_TOP
`define RISCV_TB_TOP
`include "uvm_macros.svh"
`include "riscv_interface.sv"
import uvm_pkg::*;

module riscv_tb_top;

  import riscv_test_list_pkg::*;

  parameter cycle = 10;
  bit clk;

  // Clock
  initial begin
    clk = 0;
    forever #(cycle/2) clk = ~clk;
  end

  // Interface (o reset e dirigido pelo driver, um por programa)
  riscv_interface riscv_intf(clk);

  // DUT: processador de ciclo unico (sem memorias)
  riscvsingle dut_inst(
    .clk      (clk),
    .reset    (riscv_intf.reset),
    .PC       (riscv_intf.PC),
    .Instr    (riscv_intf.Instr),
    .MemWrite (riscv_intf.MemWrite),
    .ALUResult(riscv_intf.ALUResult),
    .WriteData(riscv_intf.WriteData),
    .ReadData (riscv_intf.ReadData),
    .ECall    (riscv_intf.ECall)
  );

  // Inicia o teste escolhido por +UVM_TESTNAME
  initial begin
    run_test();
  end

  // Publica a interface virtual para driver e monitor
  initial begin
    uvm_config_db#(virtual riscv_interface)::set(uvm_root::get(), "*", "intf", riscv_intf);
  end

endmodule

`endif
