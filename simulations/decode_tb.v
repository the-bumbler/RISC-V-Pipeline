`timescale 1ns/1ps


module decode_tb ();

parameter DATA_WIDTH =32;

// Inputs 
reg clk = 0;
reg rst_n = 0;

// Instruction input 
reg [31:0] InstrB;

// PC & PC+4 
reg [DATA_WIDTH-1:0] PCB;
reg [DATA_WIDTH-1:0] PCPlus4B;
wire [DATA_WIDTH-1:0] PCC;
wire [DATA_WIDTH-1:0] PCPlus4C;

// Register writeback
reg WrEnE;
reg [4:0] WrAddrE;
reg [DATA_WIDTH-1:0] WrDataE;

// Control signals 
wire RegWriteC;
wire MemWriteC;
wire JumpC;
wire BranchC;
wire [1:0] ALUSrcC;
wire [1:0] ResultSrcC;
wire [1:0] ALUOpC;
wire LinkRegCtrlC;

// Immediate Extension 
wire [DATA_WIDTH-1:0] ImmExtC;

// Register data out
wire [DATA_WIDTH-1:0] RData1C;
wire [DATA_WIDTH-1:0] RData2C;

// Destination addr out
wire [4:0] RdC;

// Funct3 & Funct7
wire [6:0] Funct7C;
wire [2:0] Funct3C;

// Register address for hazard
wire [4:0] Rs1C;
wire [4:0] Rs2C;

decode #(.DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .InstrB(InstrB),
    .PCB(PCB),
    .PCPlus4B(PCPlus4B),
    .PCC(PCC),
    .PCPlus4C(PCPlus4C),
    .WrEnE(WrEnE),
    .WrAddrE(WrAddrE),
    .WrDataE(WrDataE), 
    .RegWriteC(RegWriteC),
    .MemWriteC(MemWriteC),
    .JumpC(JumpC),
    .BranchC(BranchC),
    .ALUSrcC(ALUSrcC),
    .ResultSrcC(ResultSrcC),
    .ALUOpC(ALUOpC),
    .LinkRegCtrlC(LinkRegCtrlC),
    .ImmExtC(ImmExtC),
    .RdC(RdC),
    .RData1C(RData1C),
    .RData2C(RData2C),
    .Funct7C(Funct7C),
    .Funct3C(Funct3C),
    .Rs1C(Rs1C),
    .Rs2C(Rs2C)
);

always begin
    clk = ~clk;
    #5;
end

initial begin 
    $dumpfile("simulations/dump.vcd");
    $dumpvars(0, decode_tb);
end

initial begin
    #10;
    rst_n = 1;
    InstrB = 0;
    PCB = 0;
    PCPlus4B = 4;
    WrEnE = 1;
    WrAddrE = 5'd0;
    WrDataE = 'd100;
    #10;
    WrAddrE = 5'd1;
    WrDataE = 'd658038;
    #10;
    WrAddrE = 5'd2;
    WrDataE = 'd900004;
    #10; 
    WrAddrE = 5'd3;
    WrDataE = 'd444444;
    #10; 
    WrAddrE = 5'd15;
    WrDataE = 'd1111111;
    #9; 
    WrEnE = 0;
    InstrB = 32'b0000000_00000_00001_000_00010_0110011; // add 0x2, 0x1, 0x0
    #10;
    PCB = 4;
    PCPlus4B = 8;
    InstrB = 32'b000011110000_00011_100_00100_0010011; // xori 0x4, 0x3, imm
                                                       // imm = 19(0)_0000_1111_0000
    #10;
    PCB = 8;
    PCPlus4B = 12;
    InstrB = 32'b0110110_00000_01111_001_00001_0100011; // sh M[0x0 + imm] = 0x15
                                                        // imm = 20(0)_0110110_00001
    #10;
    PCB = 12;
    PCPlus4B = 16;
    InstrB = 32'b1000000_00010_00001_101_00011_1100011; // bge if(0x1 >= 0x2) PC += imm
                                                        // imm = 20(1)_1000_0000_0010
    #10;
    PCB = 16;
    PCPlus4B = 20;
    InstrB = 32'b11110000111100001111_10000_0110111; // lui rd = imm << 12
                                                     // imm = 11110000111100001111_0000_0000_0000
    #10;
    PCB = 20;
    PCPlus4B = 24;
    InstrB = 32'b1_0000000000_1_00000000_00100_1100111; // jalr rd = PC+4, PC = rs1 + imm
                                                        // imm = 12(1)_00000000_1_0000000000_0
    #1;
    #10;
    #10;
    $finish;
end

endmodule 
