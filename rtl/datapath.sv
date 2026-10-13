// ============================================================
// datapath.sv — Caminho de dados single-cycle
//
// Segue a estrutura das Fig. 7.12/7.15 do Harris&Harris,
// estendida com:
//  - mux ALUSrcA (rd1 / pc) para suportar auipc
//  - resultsrc de 2 bits com 4 opcoes (inclui ImmExt p/ lui)
//  - pcsrc de 2 bits com 3 opcoes (inclui ALUResult p/ jalr)
//  - saidas lt/ltu da ALU, usadas pelo controller p/ bge/bltu
// ============================================================
module datapath(
    input  logic        clk, reset,
    input  logic [1:0]  pcsrc,
    input  logic        alusrca, alusrcb,
    input  logic        regwrite,
    input  logic [2:0]  immsrc,
    input  logic [2:0]  alucontrol,
    input  logic [1:0]  resultsrc,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic [31:0] aluresult, writedata,
    input  logic [31:0] readdata,
    output logic        zero, lt, ltu
);
    logic [31:0] pcnext, pcplus4, pctarget;
    logic [31:0] immext;
    logic [31:0] srca, srcb;
    logic [31:0] rd1, rd2;
    logic [31:0] result;

    // --- registrador de PC ---
    always_ff @(posedge clk, posedge reset)
        if (reset) pc <= 32'b0;
        else       pc <= pcnext;

    assign pcplus4  = pc + 32'd4;
    assign pctarget = pc + immext;

    always_comb
        case (pcsrc)
            2'b00:   pcnext = pcplus4;
            2'b01:   pcnext = pctarget;
            2'b10:   pcnext = {aluresult[31:1], 1'b0}; // jalr (bit0 = 0)
            default: pcnext = pcplus4;
        endcase

    // --- banco de registradores ---
    regfile rf(
        .clk(clk), .we3(regwrite),
        .a1(instr[19:15]), .a2(instr[24:20]), .a3(instr[11:7]),
        .wd3(result), .rd1(rd1), .rd2(rd2)
    );

    // --- gerador de imediato ---
    extend ext(.instr(instr[31:7]), .immsrc(immsrc), .immext(immext));

    // --- operandos da ALU ---
    assign srca      = alusrca ? pc : rd1;   // pc so para auipc
    assign srcb      = alusrcb ? immext : rd2;
    assign writedata = rd2;                  // dado a escrever na memoria (sw/sb)

    alu alu1(
        .a(srca), .b(srcb), .alucontrol(alucontrol),
        .result(aluresult), .zero(zero), .lt(lt), .ltu(ltu)
    );

    // --- mux de resultado (4 vias) ---
    always_comb
        case (resultsrc)
            2'b00:   result = aluresult; // R-type/I-type ALU/auipc
            2'b01:   result = readdata;  // lw/lb
            2'b10:   result = pcplus4;   // jal/jalr (endereco de retorno)
            2'b11:   result = immext;    // lui
            default: result = aluresult;
        endcase
endmodule
