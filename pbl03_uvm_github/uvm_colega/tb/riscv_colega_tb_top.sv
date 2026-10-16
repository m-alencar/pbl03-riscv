//------------------------------------------------------------------------------
// Testbench top para o processador do COLEGA (Penelu/RISC_V-PBL, modulo "cpu")
//------------------------------------------------------------------------------
// O "cpu" do colega nao expoe PC, Instr nem as saidas de memoria como portas, e
// tem imem/dmem proprias. Este topo faz o ADAPTADOR, por referencia hierarquica:
//   DUT -> interface : pc_cur, instr, mem_write, alu_y, rs2_val, mem_rd
//   interface -> DUT : o programa e os dados iniciais (copiados para u_imem / u_dmem)
// O "fim de programa" do colega e o salto para si mesmo (jal x0,0 = 0x0000006F).
//------------------------------------------------------------------------------

`ifndef RISCV_COLEGA_TB_TOP
`define RISCV_COLEGA_TB_TOP
`include "uvm_macros.svh"
`include "riscv_interface.sv"
import uvm_pkg::*;

module riscv_colega_tb_top;

  import riscv_test_list_pkg::*;

  parameter cycle = 10;
  bit clk;

  initial begin
    clk = 0;
    forever #(cycle/2) clk = ~clk;
  end

  riscv_interface riscv_intf(clk);

  logic [3:0] leds;

  // DUT do colega (sem arquivos: o programa e carregado pelo driver)
  cpu #(.MEM_FILE(""), .DATA_FILE("")) dut_inst (
    .clk     (clk),
    .reset   (riscv_intf.reset),
    .dpad    (4'b0000),
    .switches(7'b0000000),
    .leds    (leds)
  );

  // ---------------- adaptador: DUT -> interface (sinais internos do cpu)
  initial riscv_intf.use_ext = 1'b1;
  assign riscv_intf.PC           = dut_inst.pc_cur;
  assign riscv_intf.Instr_ext    = dut_inst.instr;
  assign riscv_intf.MemWrite     = dut_inst.mem_write;
  assign riscv_intf.ALUResult    = dut_inst.alu_y;
  assign riscv_intf.WriteData    = dut_inst.rs2_val;
  assign riscv_intf.ReadData_ext = dut_inst.mem_rd;
  assign riscv_intf.ECall        = (dut_inst.instr === 32'h0000_006F);   // jal x0,0

  // ---------------- adaptador: interface -> DUT (carga do programa e dos dados)
  always @(riscv_intf.load_req) begin
    for (int i = 0; i < 1024; i++) begin
      dut_inst.u_imem.mem[i] = riscv_intf.imem[i];
      dut_inst.u_dmem.mem[i] = {riscv_intf.dmem[4*i+3], riscv_intf.dmem[4*i+2],
                                riscv_intf.dmem[4*i+1], riscv_intf.dmem[4*i]};
    end
  end

  initial begin
    run_test();
  end

  initial begin
    uvm_config_db#(virtual riscv_interface)::set(uvm_root::get(), "*", "intf", riscv_intf);
  end

endmodule

`endif
