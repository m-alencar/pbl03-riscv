// ============================================================
// riscvsingle.sv — Topo do processador (Controller + Datapath)
//
// Interface identica (em espirito) ao HDL Example 7.1 do
// Harris&Harris, acrescida da saida ECall. Os campos da
// instrucao sao roteados do Instr vindo da memoria externa,
// como na Figura 7.63 do livro.
// ============================================================
module riscvsingle(
    input  logic        clk, reset,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic        MemWrite,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData,
    output logic         ECall
);
    logic        alusrca, alusrcb, regwrite, zero, lt, ltu;
    logic [1:0]  pcsrc, resultsrc;
    logic [2:0]  immsrc, alucontrol;

    controller c(
        .op(Instr[6:0]), .funct3(Instr[14:12]), .funct7b5(Instr[30]),
        .zero(zero), .lt(lt), .ltu(ltu),
        .pcsrc(pcsrc), .alusrca(alusrca), .alusrcb(alusrcb),
        .memwrite(MemWrite), .resultsrc(resultsrc), .immsrc(immsrc),
        .regwrite(regwrite), .alucontrol(alucontrol), .ecall(ECall)
    );

    datapath dp(
        .clk(clk), .reset(reset),
        .pcsrc(pcsrc), .alusrca(alusrca), .alusrcb(alusrcb),
        .regwrite(regwrite), .immsrc(immsrc), .alucontrol(alucontrol),
        .resultsrc(resultsrc),
        .pc(PC), .instr(Instr),
        .aluresult(ALUResult), .writedata(WriteData), .readdata(ReadData),
        .zero(zero), .lt(lt), .ltu(ltu)
    );
endmodule
