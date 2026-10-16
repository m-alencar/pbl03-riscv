//------------------------------------------------------------------------------
// Interface do processador RISC-V (PBL03 - Frente 2)
//------------------------------------------------------------------------------
// O DUT (riscvsingle) nao tem memorias: ele exporta PC e recebe Instr/ReadData.
// Esta interface tambem faz o papel das memorias (modelo comportamental):
//   - imem: Instr = imem[PC[13:2]]            (leitura combinacional)
//   - dmem: ReadData conforme funct3 (lb com sinal / lw); escrita na borda
//           de subida do clock quando MemWrite=1 (sb / sw)
// Mesmo comportamento da imem.sv / dmem.sv do projeto, so que carregavel
// pelo driver UVM (sem arquivo .hex).
//------------------------------------------------------------------------------

`ifndef RISCV_INTERFACE
`define RISCV_INTERFACE

interface riscv_interface(input logic clk);

  localparam int IMEM_WORDS = 4096;   // PC[13:2]
  localparam int DMEM_BYTES = 4096;   // ALUResult[11:0]

  //////////////////////////////////////////////////////////////////////////////
  // Sinais do DUT
  //////////////////////////////////////////////////////////////////////////////
  logic        reset = 1'b1;          // dirigido pelo driver (um reset por programa)
  logic [31:0] PC;
  logic [31:0] Instr;                 // = Instr_m (modelo de memoria) ou Instr_ext (DUT com memoria propria)
  logic        MemWrite;
  logic [31:0] ALUResult;
  logic [31:0] WriteData;
  logic [31:0] ReadData;              // idem
  logic        ECall;

  // Modo "memoria externa": o DUT tem imem/dmem proprias (ex.: processador do
  // colega). O topo liga use_ext=1 e dirige Instr_ext/ReadData_ext a partir do DUT.
  bit          use_ext = 1'b0;
  logic [31:0] Instr_m, Instr_ext;
  logic [31:0] ReadData_m, ReadData_ext;
  assign Instr    = use_ext ? Instr_ext    : Instr_m;
  assign ReadData = use_ext ? ReadData_ext : ReadData_m;

  //////////////////////////////////////////////////////////////////////////////
  // Memorias (modelo comportamental)
  //////////////////////////////////////////////////////////////////////////////
  logic [31:0] imem [IMEM_WORDS];
  logic [7:0]  dmem [DMEM_BYTES];
  int unsigned imem_gen = 0;          // contadores: forcam reavaliar as leituras
  int unsigned dmem_gen = 0;
  event        load_req;              // avisa adaptadores (DUT com memoria propria)

  // Memoria de instrucoes: leitura combinacional por palavra
  always @(PC or imem_gen) begin
    Instr_m = imem[PC[13:2]];
  end

  // Memoria de dados: leitura combinacional (lb com extensao de sinal / lw)
  always @(ALUResult or Instr_m or dmem_gen) begin
    logic [11:0] a;
    a = ALUResult[11:0];
    case (Instr_m[14:12])
      3'b000:  ReadData_m = {{24{dmem[a][7]}}, dmem[a]};
      3'b010:  ReadData_m = {dmem[a + 12'd3], dmem[a + 12'd2], dmem[a + 12'd1], dmem[a]};
      default: ReadData_m = 32'h0;
    endcase
  end

  // Memoria de dados: escrita na borda de subida (sb / sw)
  always @(posedge clk) begin
    if (!use_ext && MemWrite === 1'b1 && reset !== 1'b1) begin
      logic [11:0] a;
      a = ALUResult[11:0];
      case (Instr_m[14:12])
        3'b000: dmem[a] <= WriteData[7:0];
        3'b010: begin
          dmem[a]            <= WriteData[7:0];
          dmem[a + 12'd1]    <= WriteData[15:8];
          dmem[a + 12'd2]    <= WriteData[23:16];
          dmem[a + 12'd3]    <= WriteData[31:24];
        end
        default: ;
      endcase
      dmem_gen <= dmem_gen + 1;
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // Tarefas usadas pelo driver para carregar um programa
  //////////////////////////////////////////////////////////////////////////////
  task automatic clear_mem();
    for (int i = 0; i < IMEM_WORDS; i++) imem[i] = 32'h0;
    for (int i = 0; i < DMEM_BYTES; i++) dmem[i] = 8'h0;
  endtask

  task automatic poke_imem(input int idx, input logic [31:0] w);
    imem[idx] = w;
  endtask

  task automatic poke_dmem(input int idx, input logic [7:0] b);
    dmem[idx] = b;
  endtask

  task automatic commit_load();
    imem_gen = imem_gen + 1;
    dmem_gen = dmem_gen + 1;
    -> load_req;
  endtask

endinterface

`endif
