`timescale 1ns/1ps

module execute_tb ();

parameter DATA_WIDTH = 32;

// Clock and reset 
reg clk = 0;
reg rst_n = 0;

// C stage input (clocked)
// PC & PC+4 input
reg [DATA_WIDTH-1:0] PCC;
reg [DATA_WIDTH-1:0] PCPlus4C;

// Control signals inputs 
reg RegWriteC;
reg MemWriteC;
reg JumpC;
reg BranchC;
reg [1:0] ALUSrcC;
reg [1:0] ResultSrcC;
reg [1:0] ALUOpC;
reg LinkRegCtrlC;

// Immediate extended 
reg [DATA_WIDTH-1:0] ImmExtC;

// Destination address 
reg [4:0] RdC;

// Register Data 
reg [DATA_WIDTH-1:0] RData1C;
reg [DATA_WIDTH-1:0] RData2C;
wire [DATA_WIDTH-1:0] RData1C_unsigned, RData1C_signed, RData2C_unsigned, RData2C_signed;
assign RData1C_unsigned = RData1C;
assign RData1C_signed = RData1C;
assign RData2C_unsigned = RData2C;
assign RData2C_signed = RData2C;

// Function 7 & 3, ALU Control
//input      [6:0]            Funct7C,
reg [2:0] Funct3C;
reg [4:0] ALUControlC;

// Hazard control input & output (non-clocked)
// Rs Hazard control address input and output 
reg [4:0] Rs1;
reg [4:0] Rs2;
wire [4:0] Rs1H;
wire [4:0] Rs2H;

// Hazard forward control
reg [1:0] ForwardAH;
reg [1:0] ForwardBH;

// Hazard forward Data
reg [DATA_WIDTH-1:0] ForwardALUResultDH;   // data taken from ALU result (mem stage)
reg [DATA_WIDTH-1:0] ForwardWriteResultEH; // data taken from ResultSrc (writeback stage)
    
// Fetch output (non-clocked, branch/jump)
// PC target and source A branch
wire PCSrcA;
wire [DATA_WIDTH-1:0] PCTargetA;

// D stage output (clocked)
// Control signals
wire RegWriteD;
wire [1:0] ResultSrcD;
wire MemWriteD;

// PC+4 Passthrough
wire [DATA_WIDTH-1:0] PCPlus4D;

// Destination address passthrough
wire [4:0] RdD;

// Mem write data 
wire [DATA_WIDTH-1:0] MemWriteDataD;

// ALU Result 
wire [DATA_WIDTH-1:0] ALUResultD, ALUResultD_unsigned, ALUResultD_signed;
assign ALUResultD_signed = ALUResultD;
assign ALUResultD_unsigned = ALUResultD;

// Funct3 passthrough for load/store module (might not be used)
wire [2:0] Funct3D;

execute #(.DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .PCC(PCC),
    .PCPlus4C(PCPlus4C),
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
    .Funct3C(Funct3C),
    .ALUControlC(ALUControlC),
    .Rs1(Rs1),
    .Rs2(Rs2),
    .Rs1H(Rs1H),
    .Rs2H(Rs2H),
    .ForwardAH(ForwardAH),
    .ForwardBH(ForwardBH),
    .ForwardALUResultDH(ForwardALUResultDH), 
    .ForwardWriteResultEH(ForwardWriteResultEH), 
    .PCSrcA(PCSrcA),
    .PCTargetA(PCTargetA),
    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .PCPlus4D(PCPlus4D),
    .RdD(RdD),
    .MemWriteDataD(MemWriteDataD),
    .ALUResultD(ALUResultD),
    .Funct3D(Funct3D)
);

always begin
    clk = ~clk;
    #5;
end

initial begin
    $dumpfile("simulations/dump.vcd");
    $dumpvars(0, execute_tb);
end

initial begin
    #9.9;
    rst_n = 1; 
    // Hazard inputs
    Rs1 = 5'h00;
    Rs2 = 5'h00;
    ForwardAH = 2'b00;
    ForwardBH = 2'b00;
    ForwardALUResultDH = 0;
    ForwardWriteResultEH = 0;
    // R-type instruction(s)
    // Instruction: Rd = 100 + 50
    PCC = 0;
    PCPlus4C = 4;
    RegWriteC = 1;
    MemWriteC = 0;
    JumpC = 0;
    BranchC = 0;
    ALUSrcC[0] = 0;
    ALUSrcC[1] = 0;
    ResultSrcC = 2'b00;
    ALUOpC = 2'b01;
    LinkRegCtrlC = 0;
    ImmExtC = 0;
    RdC = 5'h00;
    RData1C = 100;
    RData2C = 50;
    Funct3C = 3'h0;
    ALUControlC = 5'b0_0_000;
    #10;
    // Instruction: Rd = -100 + 50
    PCC = 4;
    PCPlus4C = 8;
    RdC = 5'h01;
    RData1C = -100;
    RData2C = 50;
    #10;
    // Instruction: Rd = -100 + -50
    RdC = 5'h02;
    RData1C = -100;
    RData2C = -50;
    #10;
    // Instruction: Rd = -100 - 50
    RdC = 5'h03;
    RData1C = -100;
    RData2C = 50;
    ALUControlC = 5'b0_1_000;
    #10;
    // Instruction: Rd = 4.2b - 4.2b
    RdC = 5'h04;
    RData1C = 'hffff_ffff;
    RData2C = 'hffff_ffff;
    #10;
    // Instruction: Rd = 100 - 50
    RdC = 5'h05;
    RData1C = 100;
    RData2C = 50;
    ALUControlC = 5'b0_1_000;
    #10;
    // Instruction: Rd = -100 - 50
    RdC = 5'h05;
    RData1C = -100;
    RData2C = 50;
    #10;
    // Instruction: Rd = 100 - -50
    RdC = 5'h06;
    RData1C = 100;
    RData2C = -50;
    #10;
    // Instruction: Rd = -2.1b - 2.1b
    RdC = 5'h07;
    RData1C = 'h8000_0001;
    RData2C = 'hffff_ffff;
    #10;
    // Instruction: Rd = 2.1b - -2.b
    RdC = 5'h08;
    RData1C = 'hffff_ffff;
    RData2C = 'h8000_0001;
    #10;
    // Instruction: Rd = f0f0_0101 ^ 00f0_0f01
    RdC = 5'h09;
    RData1C = 'hf0f0_0101;
    RData2C = 'h00f0_0f01;
    Funct3C = 3'h4;
    ALUControlC = 5'b0_0_100;
    #10;
    // Instruction: Rd = f0f0_0101 | 01f0_0f11
    RdC = 5'h0a;
    RData1C = 'hf0f0_0101;
    RData2C = 'h01f0_0f11;
    Funct3C = 3'h6;
    ALUControlC = 5'b0_0_110;
    #10;
    // Instruction: Rd = f0f0_0101 & 01f0_0f11
    RdC = 5'h0b;
    RData1C = 'hf0f0_0101;
    RData2C = 'h01f0_0f11;
    Funct3C = 3'h7;
    ALUControlC = 5'b0_0_111;
    #10;
    // Instruction: Rd = ffff_0000 << [00004]
    RdC = 5'h0c;
    RData1C = 'hffff_0000;
    RData2C = 'h0000_0004;
    Funct3C = 3'h1;
    ALUControlC = 5'b0_0_001;
    #10;
    // Instruction: Rd = ffff_0000 >> [00004]
    RdC = 5'h0d;
    RData1C = 'hffff_0000;
    RData2C = 'h0000_0004;
    Funct3C = 3'h5;
    ALUControlC = 5'b0_0_101;
    #10;
    // Instruction: Rd = ffff_0000 >>> [00004]
    RdC = 5'h0e;
    RData1C = 'hffff_0000;
    RData2C = 'h0000_0004;
    Funct3C = 3'h5;
    ALUControlC = 5'b0_1_101;
    #10;
    // Instruction: Rd = -100 < 50
    RdC = 5'h0f;
    RData1C = -100;
    RData2C = 50;
    Funct3C = 3'h2;
    ALUControlC = 5'b0_0_010;
    #10;
    // Instruction: Rd = 50 < -100
    RdC = 5'h10;
    RData1C = 50;
    RData2C = -100;
    #10;
    // Instruction: Rd = 100 < 50 (unsinged)
    RdC = 5'h11;
    RData1C = 100;
    RData2C = 50;
    Funct3C = 3'h3;
    ALUControlC = 5'b0_0_011;
    #10;
    // Instruction: Rd = 50 < 100 (unsinged)
    RdC = 5'h12;
    RData1C = 50;
    RData2C = 100;
    Funct3C = 3'h3;
    ALUControlC = 5'b0_0_011;
    #10;
    // I-Type
    // Instruction: Rd = 100 + 15
    RegWriteC = 1;
    MemWriteC = 0;
    JumpC = 0;
    BranchC = 0;
    ALUSrcC[0] = 1;
    ALUSrcC[1] = 0;
    ResultSrcC = 2'b00;
    ALUOpC = 2'b01;
    LinkRegCtrlC = 0;
    ImmExtC = {{(DATA_WIDTH-12){1'b0}}, {12'h00f}};
    RdC = 5'h13;
    RData1C = 100;
    RData2C = 50;
    Funct3C = 3'h0;
    ALUControlC = 5'b0_0_000;
    #10;
    // Instruction: Rd = 100 + 15
    RdC = 5'h14;
    ALUControlC = 5'b0_1_000;
    #10;
    // Instruction: Rd = 100 + (-16)
    RdC = 5'h15;
    ImmExtC = {{(DATA_WIDTH-12){1'b1}}, 12'hff0};
    #10;
    // B-Type 
    // Instruction: if(100 == 100) PC += Imm
    RegWriteC = 0;
    MemWriteC = 0;
    JumpC = 0;
    BranchC = 1;
    ALUSrcC[0] = 0;
    ALUSrcC[1] = 0;
    ResultSrcC = 2'b00;
    ALUOpC = 2'b11;
    LinkRegCtrlC = 0;
    ImmExtC = {{(DATA_WIDTH-12){1'b0}}, 12'h00f};
    RdC = 5'h16;
    RData1C = 100;
    RData2C = 100;
    Funct3C = 3'h0;
    ALUControlC = 5'b0_0_000;
    #10;
    // Instruction: if(100 != 100) PC += Imm
    Funct3C = 3'h1;
    #10;
    // Instruction: if(100 < -50) PC += Imm
    RData1C = 100;
    RData2C = -50;
    Funct3C = 3'h4;
    #10;
    // Instruction: if(50 < 100) PC += Imm
    RData1C = 50;
    RData2C = 100;
    Funct3C = 3'h4;
    #10
    // Instruction: if(-50 >= 100) PC += Imm
    RData1C = -50;
    RData2C = 100;
    Funct3C = 3'h5;
    #10
    // Instruction: if(-100 >= -150) PC += Imm
    RData1C = -100;
    RData2C = -150;
    Funct3C = 3'h5;
    #10
    // Instruction: if(50 < 100) PC += Imm UNSIGNED
    RData1C = 50;
    RData2C = 100;
    Funct3C = 3'h6;
    #10
    // Instruction: if(-100 < 100) PC += Imm UNSIGNED
    RData1C = -100;
    RData2C = 100;
    Funct3C = 3'h6;
    #10
    // Instruction: if(-100 >= 100) PC += Imm UNSIGNED
    RData1C = -100;
    RData2C = 100;
    Funct3C = 3'h7;
    #10
    // Instruction: if(100 >= -100) PC += Imm UNSIGNED
    RData1C = -100;
    RData2C = 100;
    Funct3C = 3'h7;
    #10
    
    #10.1;
    $finish;
end

endmodule