// ============================================================
// alu.sv — Unidade Logico-Aritmetica
//
// alucontrol: 000 add | 001 sub | 010 and | 011 or
//             100 xor | 101 sll | 110 srl
//
// zero = (result == 0)              -> usado por beq/bne
// lt   = signed(a) <  signed(b)     -> usado por bge
// ltu  = a < b (unsigned)           -> usado por bltu
// ============================================================
module alu(
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero,
    output logic        lt,
    output logic        ltu
);
    always_comb
        case (alucontrol)
            3'b000:  result = a + b;
            3'b001:  result = a - b;
            3'b010:  result = a & b;
            3'b011:  result = a | b;
            3'b100:  result = a ^ b;
            3'b101:  result = a << b[4:0];
            3'b110:  result = a >> b[4:0];
            default: result = 32'bx;
        endcase

    assign zero = (result == 32'b0);
    assign lt   = ($signed(a) < $signed(b));
    assign ltu  = (a < b);
endmodule
