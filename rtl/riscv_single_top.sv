// ============================================================
// riscv_single_top.sv — SoC minimo de simulacao
//
// Conecta riscvsingle + imem + dmem, igual ao esquema da
// Figura 7.63 do Harris&Harris (controller/datapath dentro do
// "Processor", memorias externas).
// ============================================================
module riscv_single_top(
    input  logic        clk, reset,
    output logic [31:0] WriteData, DataAdr,
    output logic        MemWrite,
    output logic        ECall
);
    logic [31:0] PC, Instr, ReadData;

    riscvsingle rv(
        .clk(clk), .reset(reset),
        .PC(PC), .Instr(Instr),
        .MemWrite(MemWrite),
        .ALUResult(DataAdr), .WriteData(WriteData),
        .ReadData(ReadData),
        .ECall(ECall)
    );

    imem imem1(.a(PC), .rd(Instr));

    dmem dmem1(
        .clk(clk), .we(MemWrite), .funct3(Instr[14:12]),
        .a(DataAdr), .wd(WriteData), .rd(ReadData)
    );
endmodule
