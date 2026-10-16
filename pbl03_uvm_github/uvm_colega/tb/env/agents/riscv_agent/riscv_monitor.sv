//------------------------------------------------------------------------------
// riscv_monitor: observa o DUT a cada ciclo (borda de descida, sinais estaveis)
// e publica um riscv_trace. So le; nunca escreve nos sinais.
//------------------------------------------------------------------------------
`ifndef RISCV_MONITOR
`define RISCV_MONITOR

class riscv_monitor extends uvm_monitor;

  virtual riscv_interface vif;
  uvm_analysis_port #(riscv_trace) mon2sb_port;

  `uvm_component_utils(riscv_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon2sb_port = new("mon2sb_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "intf", vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction

  virtual task run_phase(uvm_phase phase);
    riscv_trace t;
    bit was_reset = 1'b1;
    forever begin
      @(negedge vif.clk);
      if (vif.reset !== 1'b0) begin   // em reset (ou X): nada a observar
        was_reset = 1'b1;
        continue;
      end
      t = riscv_trace::type_id::create("act");
      t.pc        = vif.PC;
      t.instr     = vif.Instr;
      t.memwrite  = vif.MemWrite;
      t.aluresult = vif.ALUResult;
      t.writedata = vif.WriteData;
      t.ecall     = vif.ECall;
      t.start     = was_reset;      // primeiro ciclo depois do reset
      was_reset   = 1'b0;
      `uvm_info(get_type_name(), {"TRACE FROM MONITOR: ", t.convert2string()}, UVM_HIGH)
      mon2sb_port.write(t);
    end
  endtask

endclass : riscv_monitor

`endif
