//------------------------------------------------------------------------------
// riscv_driver: recebe um PROGRAMA e o executa no DUT.
//   1. segura o reset (o PC volta a 0)
//   2. limpa e carrega imem/dmem da interface
//   3. avisa o modelo de referencia (drv2rm_port)
//   4. solta o reset e espera o ecall (ou o timeout)
//------------------------------------------------------------------------------
`ifndef RISCV_DRIVER
`define RISCV_DRIVER

class riscv_driver extends uvm_driver #(riscv_program);

  virtual riscv_interface vif;
  uvm_analysis_port #(riscv_program) drv2rm_port;

  `uvm_component_utils(riscv_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv2rm_port = new("drv2rm_port", this);
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "intf", vif))
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.reset = 1'b1;
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      `uvm_info(get_type_name(), {"programa executado: ", req.convert2string()}, UVM_MEDIUM)
      seq_item_port.item_done();
    end
  endtask

  task drive(riscv_program p);
    int unsigned cycles = 0;

    // 1) reset assincrono: PC=0
    vif.reset = 1'b1;

    // 2) carrega as memorias
    vif.clear_mem();
    for (int i = 0; i < p.words.size() && i < `RV_IMEM_WORDS; i++)
      vif.poke_imem(i, p.words[i]);
    for (int i = 0; i < `RV_DMEM_BYTES; i++)
      vif.poke_dmem(i, p.init_data[i]);
    vif.commit_load();

    // 3) avisa o modelo de referencia
    drv2rm_port.write(p);

    // 4) solta o reset (depois de 2 bordas) e roda ate o ecall ou o timeout
    repeat (2) @(posedge vif.clk);
    #1 vif.reset = 1'b0;

    forever begin
      @(posedge vif.clk);
      cycles++;
      if (vif.ECall === 1'b1) break;
      if (cycles >= p.max_cycles) begin
        `uvm_warning(get_type_name(), $sformatf("timeout: %0d ciclos sem ecall (%s)", cycles, p.tag))
        break;
      end
    end
  endtask

endclass : riscv_driver

`endif
