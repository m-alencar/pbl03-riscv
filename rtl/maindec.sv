// ============================================================
// maindec.sv — Main Decoder
//
// Tabela de decodificacao completa para o ISA limitado do
// PBL03 (subconjunto de RV32I necessario para rodar o Genius
// do PBL02). Baseado na Tabela 7.6 do Harris&Harris, estendido
// com: lb/sb, bne/bge/bltu, jalr, lui, auipc.
//
// | Instr          | op       | RegWrite | ImmSrc | ALUSrcA | ALUSrcB | MemWrite | ResultSrc | Branch | ALUOp | Jump | Jalr |
// |----------------|----------|----------|--------|---------|---------|----------|-----------|--------|-------|------|------|
// | lw / lb        | 0000011  |    1     |  000   |    0    |    1    |    0     |    01     |   0    |  00   |  0   |  0   |
// | sw / sb        | 0100011  |    0     |  001   |    0    |    1    |    1     |    xx     |   0    |  00   |  0   |  0   |
// | R-type         | 0110011  |    1     |  xxx   |    0    |    0    |    0     |    00     |   0    |  10   |  0   |  0   |
// | I-type ALU     | 0010011  |    1     |  000   |    0    |    1    |    0     |    00     |   0    |  10   |  0   |  0   |
// | beq/bne/bge/.. | 1100011  |    0     |  010   |    0    |    0    |    0     |    xx     |   1    |  01   |  0   |  0   |
// | jal            | 1101111  |    1     |  011   |    x    |    x    |    0     |    10     |   0    |  xx   |  1   |  0   |
// | jalr           | 1100111  |    1     |  000   |    0    |    1    |    0     |    10     |   0    |  00   |  1   |  1   |
// | lui            | 0110111  |    1     |  100   |    x    |    x    |    0     |    11     |   0    |  xx   |  0   |  0   |
// | auipc          | 0010111  |    1     |  100   |    1    |    1    |    0     |    00     |   0    |  00   |  0   |  0   |
// | ecall          | 1110011  |    0     |  xxx   |    x    |    x    |    0     |    xx     |   0    |  xx   |  0   |  0   |
// ============================================================
module maindec(
    input  logic [6:0] op,
    output logic        regwrite,
    output logic [2:0]  immsrc,
    output logic        alusrca,
    output logic        alusrcb,
    output logic        memwrite,
    output logic [1:0]  resultsrc,
    output logic        branch,
    output logic [1:0]  aluop,
    output logic        jump,
    output logic        jalr
);
    always_comb begin
        // defaults seguros (evita latches; cobre ecall/opcode invalido)
        regwrite  = 1'b0;
        immsrc    = 3'b000;
        alusrca   = 1'b0;
        alusrcb   = 1'b0;
        memwrite  = 1'b0;
        resultsrc = 2'b00;
        branch    = 1'b0;
        aluop     = 2'b00;
        jump      = 1'b0;
        jalr      = 1'b0;

        case (op)
            7'b0000011: begin // lw, lb
                regwrite  = 1'b1;
                alusrcb   = 1'b1;
                resultsrc = 2'b01;
                aluop     = 2'b00;
            end
            7'b0100011: begin // sw, sb
                immsrc   = 3'b001;
                alusrcb  = 1'b1;
                memwrite = 1'b1;
                aluop    = 2'b00;
            end
            7'b0110011: begin // add, sub, and, or, xor
                regwrite = 1'b1;
                aluop    = 2'b10;
            end
            7'b0010011: begin // addi, andi, slli, srli
                regwrite = 1'b1;
                alusrcb  = 1'b1;
                aluop    = 2'b10;
            end
            7'b1100011: begin // beq, bne, bge, bltu
                immsrc = 3'b010;
                branch = 1'b1;
                aluop  = 2'b01;
            end
            7'b1101111: begin // jal
                regwrite  = 1'b1;
                immsrc    = 3'b011;
                resultsrc = 2'b10;
                jump      = 1'b1;
            end
            7'b1100111: begin // jalr
                regwrite  = 1'b1;
                alusrcb   = 1'b1;
                resultsrc = 2'b10;
                jump      = 1'b1;
                jalr      = 1'b1;
            end
            7'b0110111: begin // lui
                regwrite  = 1'b1;
                immsrc    = 3'b100;
                resultsrc = 2'b11;
            end
            7'b0010111: begin // auipc
                regwrite = 1'b1;
                immsrc   = 3'b100;
                alusrca  = 1'b1;
                alusrcb  = 1'b1;
                aluop    = 2'b00;
            end
            default: ; // 1110011 (ecall) e qualquer opcode nao suportado
        endcase
    end
endmodule
