// ============================================================
// regfile.sv — Banco de 32 registradores (x0..x31)
//
// 2 portas de leitura combinacional (a1/a2 -> rd1/rd2),
// 1 porta de escrita sincrona (a3/wd3/we3).
// x0 e fixo em zero (nunca escrito, sempre le 0).
// ============================================================
module regfile(
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:0];

    always_ff @(posedge clk)
        if (we3 && a3 != 5'b0)
            rf[a3] <= wd3;

    assign rd1 = (a1 != 5'b0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 5'b0) ? rf[a2] : 32'b0;
endmodule
