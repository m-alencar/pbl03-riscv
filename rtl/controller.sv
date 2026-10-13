// ============================================================
// controller.sv — Control Unit
//
// Une Main Decoder + ALU Decoder e resolve:
//  - a condicao de desvio (branch_taken) a partir de funct3
//    e dos flags da ALU (zero/lt/ltu)
//  - o sinal pcsrc[1:0] que escolhe o proximo PC:
//      00 = PC+4
//      01 = PCTarget = PC + ImmExt   (branch tomado / jal)
//      10 = ALUResult (rs1+imm, bit0 zerado)  (jalr)
//  - o flag ecall (usado pelo ambiente/testbench para observar
//    a0/a7, equivalente ao "ecall" do PBL02 em Ripes)
// ============================================================
module controller(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       zero,
    input  logic       lt,
    input  logic       ltu,
    output logic [1:0] pcsrc,
    output logic        alusrca,
    output logic        alusrcb,
    output logic        memwrite,
    output logic [1:0]  resultsrc,
    output logic [2:0]  immsrc,
    output logic        regwrite,
    output logic [2:0]  alucontrol,
    output logic        ecall
);
    logic        branch, jump, jalr;
    logic [1:0]  aluop;
    logic        branch_taken;

    maindec md(
        .op(op), .regwrite(regwrite), .immsrc(immsrc),
        .alusrca(alusrca), .alusrcb(alusrcb), .memwrite(memwrite),
        .resultsrc(resultsrc), .branch(branch), .aluop(aluop),
        .jump(jump), .jalr(jalr)
    );

    aludec ad(
        .opb5(op[5]), .funct3(funct3), .funct7b5(funct7b5),
        .aluop(aluop), .alucontrol(alucontrol)
    );

    always_comb
        case (funct3)
            3'b000:  branch_taken = zero;   // beq
            3'b001:  branch_taken = ~zero;  // bne
            3'b101:  branch_taken = ~lt;    // bge  (a >= b)
            3'b110:  branch_taken = ltu;    // bltu
            default: branch_taken = 1'b0;
        endcase

    assign pcsrc = jalr ? 2'b10 :
                   ((jump | (branch & branch_taken)) ? 2'b01 : 2'b00);

    assign ecall = (op == 7'b1110011);
endmodule
