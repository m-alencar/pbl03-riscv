// ============================================================
// aludec.sv — ALU Decoder
//
// Produz alucontrol[2:0] a partir de aluop (vindo do Main
// Decoder) e funct3/funct7b5 (quando op for R-type/I-type ALU).
//
// aluop = 00 -> add   (lw/sw/lb/sb/jalr/auipc)
// aluop = 01 -> sub   (comparacao de branches; zero/lt/ltu
//                       saem direto da ALU independente disso)
// aluop = 10 -> depende de funct3 (R-type ou I-type ALU)
// ============================================================
module aludec(
    input  logic       opb5,      // instr[5]: 1 para R-type
    input  logic [2:0] funct3,
    input  logic       funct7b5,  // instr[30]
    input  logic [1:0] aluop,
    output logic [2:0] alucontrol
);
    logic rtypesub;
    assign rtypesub = funct7b5 & opb5; // true somente para sub (R-type), nunca para addi

    always_comb
        case (aluop)
            2'b00:   alucontrol = 3'b000; // add
            2'b01:   alucontrol = 3'b001; // sub (branches)
            default: // 2'b10 : R-type ou I-type ALU
                case (funct3)
                    3'b000:  alucontrol = rtypesub ? 3'b001 : 3'b000; // sub : add/addi
                    3'b111:  alucontrol = 3'b010; // and/andi
                    3'b110:  alucontrol = 3'b011; // or
                    3'b100:  alucontrol = 3'b100; // xor
                    3'b001:  alucontrol = 3'b101; // sll/slli
                    3'b101:  alucontrol = 3'b110; // srl/srli
                    default: alucontrol = 3'bxxx;
                endcase
        endcase
endmodule
