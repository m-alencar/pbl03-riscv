// ============================================================
// imem.sv — Memoria de instrucoes (somente leitura, combinacional)
//
// PROG_FILE: arquivo .hex com uma palavra de 32 bits por linha.
//   - sanity test (riscv_single_top): "program.hex" (padrao)
//   - Genius (genius_soc):            "genius.hex"
// ============================================================
module imem #(
    parameter PROG_FILE = "program.hex"
)(
    input  logic [31:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM[0:16383]; // 64KB

    initial
        $readmemh(PROG_FILE, RAM);

    assign rd = RAM[a[31:2]]; // acesso por palavra (ignora a[1:0])
endmodule
