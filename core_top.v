

module core_top #(
    parameter DATA_WIDTH = 32
) (
    // Clock and reset
    input                   clk,
    input                   rst_n,
    // Fetch stage instruction memory I/O
    input  [31:0]           Instr,
    output [DATA_WIDTH-1:0] InstrAddr,
    // Memory state memory file I/O
    output                  WriteEn,
    output [DATA_WIDTH-1:0] MemAddress,
    output [DATA_WIDTH-1:0] MemStoreData,
    input  [DATA_WIDTH-1:0] MemLoadData
);

// A stage wires
wire PCSrcA;
wire [DATA_WIDTH-1:0] PCTargetA;

// Instantiate fetch cycle
fetch #(.DATA_WIDTH(DATA_WIDTH)) fetch_inst (
    .clk(clk),
    .rst_n(rst_n),
    .PCSrcA(PCSrcA),
    .PCTargetA(PCTargetA), 
    .InstrAddr(InstrAddr), // top module input
    .Instr(Instr),         // top module output
    .InstrB(InstrB),
    .PCB(PCB),
    .PCPlus4B(PCPlus4B)
);

// B stage wires
wire [31:0] InstrB;
wire [DATA_WIDTH-1:0] PCB;
wire [DATA_WIDTH-1:0] PCPlus4B;

// Instantiate decode cycle
decode #(.DATA_WIDTH(DATA_WIDTH)) decode_inst (
    .clk(clk),
    .rst_n(rst_n),
    .InstrB(InstrB),
    .PCB(PCB),
    .PCPlus4B(PCPlus4B),
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
    .ALUControlC(ALUControlC),
    .UIControlC(UIControlC),
    .ImmExtC(ImmExtC),
    .RdC(RdC),
    .RData1C(RData1C),
    .RData2C(RData2C),
    .Funct3C(Funct3C),
    .WrEnE(RegWriteEn),  // writeback enable (wire defs under writeback inst)
    .WrAddrE(RegWrAddr), // writeback address
    .WrDataE(RegWrData), // writeback data
    .Rs1C(Rs1C),
    .Rs2C(Rs2C)
);

// C Stage wires
wire [DATA_WIDTH-1:0] PCC;
wire [DATA_WIDTH-1:0] PCPlus4C;
wire RegWriteC;
wire MemWriteC;
wire JumpC;
wire BranchC;
wire [1:0] ALUSrcC;
wire [1:0] ResultSrcC;
wire [1:0] ALUOpC;
wire LinkRegCtrlC;
wire [4:0] ALUControlC;
wire UIControlC;
wire [DATA_WIDTH-1:0] ImmExtC;
wire [4:0] RdC;
wire [DATA_WIDTH-1:0] RData1C;
wire [DATA_WIDTH-1:0] RData2C;
wire [2:0] Funct3C;
wire WrEnE;
wire [4:0] WrAddrE;
wire [DATA_WIDTH-1:0] WrDataE;
wire [4:0] Rs1C;
wire [4:0] Rs2C;

// Instantiate Execute Cycle
execute #(.DATA_WIDTH(DATA_WIDTH)) execute_inst (
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
    .UIControlC(UIControlC),
    .ImmExtC(ImmExtC),
    .RdC(RdC),
    .RData1C(RData1C),
    .RData2C(RData2C),
    .Funct3C(Funct3C),
    .ALUControlC(ALUControlC),
    .Rs1C(Rs1C),
    .Rs2C(Rs2C),
    .Rs1CH(Rs1CH),                //******************
    .Rs2CH(Rs2CH),                //****************** 
    .ForwardAH(ForwardAH),            //******************
    .ForwardBH(ForwardBH),            //******************
    .ForwardALUResultDH(ALUResultDH),   //******************
    .ForwardWriteResultEH(WriteResultEH), //******************
    .PCSrcA(PCSrcA),
    .PCTargetA(PCTargetA),
    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .PCPlus4D(PCPlus4D),
    .RdD(RdD),
    .MemWriteDataD(MemWriteDataD),
    .ALUResultD(ALUResultD),
    .UpperImmExtD(UpperImmExtD),
    .Funct3D(Funct3D),
);

// D stage wires
wire RegWriteD;
wire [1:0] ResultSrcD;
wire MemWriteD;
wire [DATA_WIDTH-1:0] PCPlus4D;
wire [4:0] RdD;
wire [DATA_WIDTH-1:0] MemWriteDataD;
wire [DATA_WIDTH-1:0] ALUResultD;
wire [DATA_WIDTH-1:0] UpperImmExtD;
wire [2:0] Funct3D;

// Instantiate Mem cycle
mem_write #(.DATA_WIDTH(DATA_WIDTH)) mem_cycle_inst (
    .clk(clk),
    .rst_n(rst_n),
    .PCPlus4D(PCPlus4D),
    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .ALUResultD(ALUResultD),
    .MemWriteDataD(MemWriteDataD),
    .RdD(RdD),
    .UpperImmExtD(UpperImmExtD),
    .Funct3D(Funct3D),
    .WriteEn(WriteEn),           // top module output
    .MemAddress(MemAddress),     // top module output
    .MemStoreData(MemStoreData), // top module output
    .MemLoadData(MemLoadData),   // top module input
    .PCPlus4E(PCPlus4E),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .ALUResultE(ALUResultE),
    .MemReadDataE(MemReadDataE),
    .RdE(RdE),
    .UpperImmExtE(UpperImmExtE),
    .RegWriteDH(RegWriteDH),   // regwrite to hazard
    .ALUResultDH(ALUResultDH), // ALU data to hazard
    .RdDH(RdDH)                // destination address to hazard
);

// E stage wires
wire [DATA_WIDTH-1:0] PCPlus4E;
wire RegWriteE;
wire [1:0] ResultSrcE;
wire [DATA_WIDTH-1:0] ALUResultE;
wire [DATA_WIDTH-1:0] MemReadDataE;
wire [4:0] RdE;
wire [DATA_WIDTH-1:0] UpperImmExtE;

// Instantiate writeback cycle
writeback #(.DATA_WIDTH(DATA_WIDTH)) writeback_inst (
    .clk(clk),
    .rst_n(rst_n),
    .PCPlus4E(PCPlus4E),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .ALUResultE(ALUResultE),
    .MemReadDataE(MemReadDataE),
    .RdE(RdE),
    .UpperImmExtE(UpperImmExtE),
    .RegWriteEn(RegWriteEn),
    .RegWrAddr(RegWrAddr),
    .RegWrData(RegWrData),
    .RegWriteEH(RegWriteEH),      // writeback write signal to hazard
    .RdEH(RdEH),                  // writeback address to hazard
    .WriteResultEH(WriteResultEH) // writeback data to hazard
);

// Register writeback wires
wire RegWriteEn;
wire [4:0] RegWrAddr;
wire [DATA_WIDTH-1:0] RegWrData;
// go up to decode register file

// Hazard control wires
wire [4:0] Rs1CH;
wire [4:0] Rs2CH;
wire [4:0] RdDH;
wire [DATA_WIDTH-1:0] ALUResultDH;
wire RegWriteDH;
wire [4:0] RdEH;
wire [DATA_WIDTH-1:0] WriteResultEH;
wire RegWriteEH;
wire [1:0] ForwardAH;
wire [1:0] ForwardBH;

// Instantiate hazard control
hazard #(.DATA_WIDTH(DATA_WIDTH)) hazard_inst (
    .rst_n(rst_n),
    .Rs1CH(Rs1CH),
    .Rs2CH(Rs2CH),
    .RdDH(RdDH),
    .ALUResultDH(ALUResultDH),
    .RegWriteDH(RegWriteDH),
    .RdEH(RdEH),
    .WriteResultEH(WriteResultEH),
    .RegWriteEH(RegWriteEH),
    .ForwardAH(ForwardAH),
    .ForwardBH(ForwardBH)
);

endmodule 
