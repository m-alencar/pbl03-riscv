// ============================================================
// testbench.sv — Sanity check local (NAO e o ambiente UVM da
// Frente 2; serve só para validar o core antes de integrar ao
// verif-env-template).
// ============================================================
`timescale 1ns/1ps

module testbench();
    logic clk, reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite, ECall;

    riscv_single_top dut(
        .clk(clk), .reset(reset),
        .WriteData(WriteData), .DataAdr(DataAdr),
        .MemWrite(MemWrite), .ECall(ECall)
    );

    // clock de 10ns de periodo
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        #22;
        reset = 0;
    end

    // acompanha PC e escreve em memoria/ecall
    always @(posedge clk)
        if (!reset) begin
            $display("t=%0t  PC=%08h  Instr=%08h", $time, dut.PC, dut.Instr);
            if (MemWrite)
                $display("          MEM[%08h] <= %08h", DataAdr, WriteData);
        end

    always @(posedge clk)
        if (!reset && ECall) begin
            $display("---- ECALL em PC=%08h ----", dut.PC);
            $display("a0 = %0d (0x%08h)", dut.rv.dp.rf.rf[10], dut.rv.dp.rf.rf[10]);
            $display("t3 (mem[0x2000]) esperado=15 -> x28 = %0d", dut.rv.dp.rf.rf[28]);
            $display("t5 (mem[0x2004]) esperado=65 -> x30 = %0d", dut.rv.dp.rf.rf[30]);
            $display("a2 (auipc)       esperado=0x34 -> x12 = %08h", dut.rv.dp.rf.rf[12]);
            $finish;
        end

    initial begin
        #2000;
        $display("TIMEOUT - ecall nao foi atingido, revisar o core.");
        $finish;
    end
endmodule
