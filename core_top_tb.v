`timescale 1ns/1ps

module core_top_tb();

initial begin
    $dumpfile("simulations/dump.vcd");
    $dumpvars(0, core_top_tb);
end

parameter DATA_WIDTH = 32;

reg clk = 0;
reg rst_n = 0;

wire [31:0] Instr;
wire [DATA_WIDTH-1:0] InstrAddr;

wire WriteEn;
wire [DATA_WIDTH-1:0] MemAddress;
wire [DATA_WIDTH-1:0] MemStoreData;
wire [DATA_WIDTH-1:0] MemLoadData;

core_top #(.DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .Instr(Instr),
    .InstrAddr(InstrAddr),
    .WriteEn(WriteEn),
    .MemAddress(MemAddress),
    .MemStoreData(MemStoreData),
    .MemLoadData(MemLoadData)
);

InstructionMemory #(.DATA_WIDTH(DATA_WIDTH)) InstructionMem_Inst (
    .InstrAddr(InstrAddr >> 2),
    .Instr(Instr)
);

DataMemory #(.DATA_WIDTH(DATA_WIDTH)) DataMemory_Inst (
    .WriteEn(WriteEn),
    .MemAddress(MemAddress),
    .MemStoreData(MemStoreData),
    .MemLoadData(MemLoadData)
);

always begin
    clk = ~clk;
    #5;
end

initial begin
    #6;
    rst_n <= 1;
    #90;
    #90;
    #90;
    #90;
    #90;
    #84;
    $finish;
end

endmodule

module InstructionMemory #(
    parameter DATA_WIDTH = 32
) (
    input [DATA_WIDTH-1:0] InstrAddr,
    output reg [31:0] Instr
);

reg [31:0] InstrMem [99:0];

integer k;

initial begin
    for(k = 0; k < 100; k = k + 1) begin
        InstrMem[k] = 0;
    end
    InstrMem[0]  = 32'b0000_0000_0000__00000__010__00001__0000011; // lw 0x1, M[0+0]
    InstrMem[1]  = 32'b0000_0000_0001__00000__010__00010__0000011; // lw 0x2, M[0+1]
    InstrMem[2]  = 32'b0000_0000_0010__00000__010__00011__0000011; // lw 0x3, M[0+2]
    InstrMem[3]  = 32'b0000_0000_0011__00000__010__00100__0000011; // lw 0x4, M[0+3]
    InstrMem[4]  = 32'b0000_0000_0100__00000__101__00101__0000011; // lhu 0x5, M[0+4]
    InstrMem[5]  = 32'b0000_0000_0101__00000__100__00110__0000011; // lbu 0x6, M[0+5]
    InstrMem[6]  = 32'b0000_0000_0110__00000__010__00111__0000011; // lw 0x7, M[0+6]
    InstrMem[7]  = 32'b0000_0000_0111__00000__010__01000__0000011; // lw 0x8, M[0+7]
    InstrMem[8]  = 32'b1111_1111_1111_1111_1111__01001__0110111;   // lui 0x9, imm << 12
    InstrMem[9]  = 32'b1111_1111_1111_1111_1111__01010__0010111;   // auipc 0xA, PC + (imm << 12)

    InstrMem[10] = 32'b0_000101__00010__00001__000__0100_0__1100011; // beq (0x1 == 0x2) PC += 168
    InstrMem[11] = 32'b0_000101__00001__00001__001__0100_0__1100011; // bne (0x1 == 0x1) PC += 168
    InstrMem[12] = 32'b0_000101__00011__00001__101__0100_0__1100011; // bge (0x1 >= 0x3) PC += 168

    InstrMem[15] = 32'b0000000__01011__00011__010__00000__0100011; // sw M[0x3+0], 0xB
    InstrMem[16] = 32'b0000000__01100__00011__010__00001__0100011; // sw M[0x3+1], 0xC
    InstrMem[17] = 32'b0000000__01101__00011__010__00010__0100011; // sw M[0x3+2], 0xD
    InstrMem[18] = 32'b0000000__01110__00011__010__00011__0100011; // sw M[0x3+3], 0xE
    InstrMem[19] = 32'b0000000__01111__00011__010__00100__0100011; // sw M[0x3+4], 0xF
    InstrMem[20] = 32'b0000000__10000__00011__010__00101__0100011; // sw M[0x3+5], 0x10
    InstrMem[21] = 32'b0000000__10001__00011__010__00110__0100011; // sw M[0x3+6], 0x11
    InstrMem[22] = 32'b0000000__01001__00000__010__01010__0100011; // sw M[0x0+10], 0x9
    InstrMem[23] = 32'b0000000__01010__00000__010__01011__0100011; // sw M[0x0+11], 0xA
    InstrMem[24] = 32'b0000000__00101__00000__010__01100__0100011; // sw M[0x0+12], 0x5
    InstrMem[25] = 32'b0000000__00110__00000__010__01101__0100011; // sw M[0x0+13], 0x6
    InstrMem[26] = 32'b0000000__01001__00000__001__01110__0100011; // sh M[0x0+14], 0x9
    InstrMem[27] = 32'b0000000__01010__00000__000__01111__0100011; // sb M[0x0+15], 0xA

    InstrMem[54] = 32'b0100000__00010__00001__000__01011__0110011;  // sub 0xB, 0x1 - 0x2
    InstrMem[55] = 32'b0000000__00100__00011__000__01100__0110011;  // add 0xC, 0x3 + 0x4
    InstrMem[56] = 32'b0000_0000_1000__00101__001__01101__0010011;  // slli 0xD, 0x5 << (8)
    InstrMem[57] = 32'b0000000__00011__00100__010__01110__0110011;  // slt 0xE, 0x4 < 0x3
    InstrMem[58] = 32'b0000_0100_0001__00001__000__01111__0010011;  // addi 0xF, 0x1 + 65
    InstrMem[59] = 32'b0000_0010_0001__00011__000__10000__0010011;  // addi 0x10, 0x3 + 33
    InstrMem[60] = 32'b1110_0101_1100__00100__000__10001__0010011;  // addi 0x11, 0x4 + (-420)
    InstrMem[61] = 32'b1_111010_0000_1__00000__00000__111__1100011; // bgeu (0x0 >= 0x0) PC += (-192)
end
always @(*) begin
    Instr <= InstrMem[InstrAddr];
end

endmodule

module DataMemory #(
    parameter DATA_WIDTH = 32
) (
    input WriteEn,
    input [DATA_WIDTH-1:0] MemAddress,
    input [DATA_WIDTH-1:0] MemStoreData,
    output reg [DATA_WIDTH-1:0] MemLoadData
);

reg [DATA_WIDTH-1:0] DataMem [99:0];

integer k;

initial begin
    for(k = 0; k < 100; k = k + 1) begin
        DataMem[k] = 0;
    end
    DataMem[0] = 100;
    DataMem[1] = -100;
    DataMem[2] = 50;
    DataMem[3] = -50;
    DataMem[4] = 32'hffff_ffff;
    DataMem[5] = 32'hffff_ffff;
    DataMem[6] = 32'hf0f0_0fe1;
    DataMem[7] = 32'h00f0_0fd1;
end

always @(*) begin
    if(WriteEn) begin
        DataMem[MemAddress] <= MemStoreData;
    end else begin
        MemLoadData <= DataMem[MemAddress];
    end
end

endmodule