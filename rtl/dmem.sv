// ============================================================
// dmem.sv — Memoria de dados, byte-enderecavel (16 KB)
//
// Suporta lw/sw (palavra) e lb/sb (byte, leitura com sign-extend)
// via o campo funct3 da instrucao, repassado pelo top-level.
//
// DATA_FILE: se nao for vazio, carrega um .hex (1 byte por linha)
// a partir do endereco DATA_BASE (secao .data do programa).
// ============================================================
module dmem #(
    parameter DATA_FILE = "",
    parameter DATA_BASE = 14'h2000
)(
    input  logic        clk,
    input  logic        we,
    input  logic [2:0]  funct3,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    logic [7:0] mem[0:16383]; // 16KB

    initial
        if (DATA_FILE != "")
            $readmemh(DATA_FILE, mem, DATA_BASE);

    always_comb
        case (funct3)
            3'b000:  rd = {{24{mem[a][7]}}, mem[a]};               // lb (sign-extend)
            3'b010:  rd = {mem[a+3], mem[a+2], mem[a+1], mem[a]};  // lw
            default: rd = 32'bx;
        endcase

    always_ff @(posedge clk)
        if (we)
            case (funct3)
                3'b000: mem[a] <= wd[7:0]; // sb
                3'b010: begin               // sw
                    mem[a]   <= wd[7:0];
                    mem[a+1] <= wd[15:8];
                    mem[a+2] <= wd[23:16];
                    mem[a+3] <= wd[31:24];
                end
                default: ;
            endcase
endmodule
