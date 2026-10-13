// ============================================================
// genius_soc.sv — SoC de simulacao para rodar o Genius no nucleo
//
//   riscvsingle (nucleo)  +  imem (genius.hex)  +  dmem (data.hex)
//   + genius_periph (LEDs, switches, D-Pad, RTC)
//
// Decodificacao de endereco: 0xF000_0xxx = periferico, resto = dmem.
// ============================================================
module genius_soc(
    input  logic        clk, reset,
    input  logic [4:0]  switches,
    input  logic [3:0]  dpad_btn,
    output logic [95:0] leds,
    output logic        ECall
);
    logic [31:0] PC, Instr, ReadData, ALUResult, WriteData;
    logic        MemWrite;

    logic        io_sel;
    logic [31:0] io_rdata, mem_rdata;

    riscvsingle rv(
        .clk(clk), .reset(reset),
        .PC(PC), .Instr(Instr),
        .MemWrite(MemWrite),
        .ALUResult(ALUResult), .WriteData(WriteData),
        .ReadData(ReadData),
        .ECall(ECall)
    );

    imem #(.PROG_FILE("genius.hex")) imem1(.a(PC), .rd(Instr));

    dmem #(.DATA_FILE("data.hex")) dmem1(
        .clk(clk), .we(MemWrite & ~io_sel), .funct3(Instr[14:12]),
        .a(ALUResult), .wd(WriteData), .rd(mem_rdata)
    );

    genius_periph pp(
        .clk(clk), .reset(reset),
        .we(MemWrite),
        .is_load(Instr[6:0] == 7'b0000011),
        .addr(ALUResult), .wdata(WriteData),
        .sel(io_sel), .rdata(io_rdata),
        .switches(switches), .dpad_btn(dpad_btn), .leds(leds)
    );

    assign ReadData = io_sel ? io_rdata : mem_rdata;
endmodule
