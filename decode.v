

module decode #(
    parameter DATA_WIDTH = 32
) (
    // Clock and reset
    input                       clk,
    input                       rst_n,
    // Instruction input 
    input      [31:0]           InstrB,
    // PC & PC+4 input and output 
    input      [DATA_WIDTH-1:0] PCB,
    input      [DATA_WIDTH-1:0] PCPlus4B,
    output reg [DATA_WIDTH-1:0] PCC,
    output reg [DATA_WIDTH-1:0] PCPlus4C,
    // Register write-back data, address, and signal (from E stage)
    input                       WrEnE,
    input      [4:0]            WrAddrE,
    input      [DATA_WIDTH-1:0] WrDataE,
    // Control Signal outputs 
    output reg                  RegWriteC,
    output reg                  MemWriteC,
    output reg                  JumpC,
    output reg                  BranchC,
    output reg [1:0]            ALUSrcC,
    output reg [1:0]            ResultSrcC,
    output reg [1:0]            ALUOpC,
    output reg                  LinkRegCtrlC,
    // Immediate extended
    output reg [DATA_WIDTH-1:0] ImmExtC,
    // Destination address
    output reg [4:0]            RdC,
    // Register data out 1 & 2
    output reg [DATA_WIDTH-1:0] RData1C,
    output reg [DATA_WIDTH-1:0] RData2C,
    // Function 7 & 3 
    output reg [6:0]            Funct7C,
    output reg [2:0]            Funct3C,
    // Rs Hazard control address 
    output reg [4:0]            Rs1C,
    output reg [4:0]            Rs2C
);

// Internal wire definintions 
wire [6:0] Opcode = InstrB[6:0];
wire [4:0] Rs1    = InstrB[19:15];
wire [4:0] Rs2    = InstrB[24:20];
wire [4:0] Rd     = InstrB[11:7];
wire [6:0] Funct7 = InstrB[31:25];
wire [2:0] Funct3 = InstrB[14:12];

// Control Unit Wires
wire RegWrite;
wire MemWrite;
wire Jump;
wire Branch;
wire [1:0] ALUSrc;    // ALUSrc[0] will control the mux for rs2 & imm (B input), ALUSrc[1] will control the mux for rs1 & PC (A input)
wire [1:0] ResultSrc; // control signal for 4 input mux at writeback stage (00=ALU result, 01=memory, 10=PC+4, 11=Imm)
wire [1:0] ALUOp;     // ALU control (00=do nothing, 01=accept funct, 10=add, 11=sub)
wire LinkRegCtrl;     // control for Jalr mux (pass Rs1 to PC+Imm module instead of PC)
wire [2:0] ImmGenSrc; // immediate generator signals for 5 types of immediate formats
/*
// Control Unit reg
reg RegWrite;
reg MemWrite;
reg Jump;
reg Branch;
reg [1:0] ALUSrc;    // ALUSrc[0] will control the mux for rs2 & imm (B input), ALUSrc[1] will control the mux for rs1 & PC (A input)
reg [1:0] ResultSrc; // control signal for 4 input mux at writeback stage (00=ALU result, 01=memory, 10=PC+4, 11=Imm)
reg [1:0] ALUOp;     // ALU control (00=do nothing, 01=accept funct, 10=add, 11=sub)
reg LinkRegCtrl;     // control for Jalr mux (pass Rs1 to PC+Imm module instead of PC)
reg [2:0] ImmGenSrc; // immediate generator signals for 5 types of immediate formats
*/
// Opcode parameters
localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_REG    = 7'b0110011;
localparam OP_IMM    = 7'b0010011;
localparam OP_JAL    = 7'b1101111;
localparam OP_JALR   = 7'b1100111;
localparam OP_LUI    = 7'b0110111;
localparam OP_AUIPC  = 7'b0010111;

// Immediate type signals
localparam NO_IMM = 3'b000;
localparam I_IMM = 3'b001;
localparam S_IMM = 3'b010;
localparam B_IMM = 3'b011;
localparam U_IMM = 3'b100;
localparam J_IMM = 3'b101;

// Immediate Extender Result
wire [DATA_WIDTH-1:0] ImmExt;

// Immediate Extender 
//      For I-type instructions, Imm[11:0] are Instr[31:20]
//      For S-type instructions, Imm[11:5 | 4:0] are Instr[31:25] & Instr[11:7]
//      For B-type instructions, Imm[12 | 11 | 10:5 | 4:1] are Instr[31] & Instr[7] & Instr[30:25] & Instr[11:8]
assign ImmExt = (ImmGenSrc == I_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[31:20]} : 
                (ImmGenSrc == S_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[31:25], InstrB[11:7]} : 
                (ImmGenSrc == B_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[7], InstrB[30:25], InstrB[11:8], 1'b0} : 
                (ImmGenSrc == U_IMM) ? {{(DATA_WIDTH-32){InstrB[31]}}, InstrB[31:12], {12{1'b0}}} :
                (ImmGenSrc == J_IMM) ? {{(DATA_WIDTH-20){InstrB[31]}}, InstrB[19:12], InstrB[20], InstrB[30:21], 1'b0} : 
                32'h0000_0000;

// Control Unit 
assign RegWrite  = (Opcode == OP_LOAD  | Opcode == OP_REG  | Opcode == OP_IMM | Opcode ==  OP_JAL | Opcode ==  OP_JALR | Opcode == OP_LUI | Opcode == OP_AUIPC) ? 1'b1 : 1'b0;
assign MemWrite = (Opcode == OP_STORE) ? 1'b1 : 1'b0;
assign Jump = (Opcode == OP_JAL | Opcode == OP_JALR) ? 1'b1 : 1'b0;
assign Branch = (Opcode == OP_BRANCH) ? 1'b1 : 1'b0;
assign ALUSrc[0] = (Opcode == OP_LOAD | Opcode == OP_STORE | Opcode == OP_IMM | Opcode == OP_AUIPC) ? 1'b1 : 1'b0;
assign ALUSrc[1] = (Opcode == OP_AUIPC) ? 1'b1 : 1'b0;
assign ResultSrc = (Opcode == OP_LOAD) ? 2'b01 : (Opcode == OP_JAL | Opcode == OP_JALR) ? 2'b10 : (Opcode == OP_LUI) ? 2'b11 : 2'b00;
assign ALUOp = (Opcode == OP_REG | Opcode == OP_IMM) ? 2'b01 : (Opcode == OP_LOAD | Opcode == OP_STORE | Opcode == OP_AUIPC) ? 2'b10 : (Opcode == OP_BRANCH) ? 2'b11 : 2'b00;
assign LinkRegCtrl = (Opcode == OP_JALR) ? 1'b1 : 1'b0;
assign ImmGenSrc = (Opcode == OP_IMM) ? I_IMM : (Opcode == OP_STORE) ? S_IMM : (Opcode == OP_BRANCH) ? B_IMM : 
                   (Opcode == OP_AUIPC | Opcode == OP_LUI) ? U_IMM : (Opcode == OP_JAL | Opcode == OP_JALR) ? J_IMM : NO_IMM;

/*
wire if_LOAD   = (Opcode == OP_LOAD);
wire if_STORE  = (Opcode == OP_STORE);
wire if_BRANCH = (Opcode == OP_BRANCH);
wire if_REG    = (Opcode == OP_REG);
wire if_IMM    = (Opcode == OP_IMM);
wire if_JAL    = (Opcode == OP_JAL);
wire if_JALR   = (Opcode == OP_JALR);
wire if_LUI    = (Opcode == OP_LUI);
wire if_AUIPC  = (Opcode == OP_AUIPC);

always @(*) begin
    RegWrite = if_LOAD | if_REG | if_IMM | if_JAL | if_JALR | if_LUI | if_AUIPC;
    MemWrite = if_STORE;
    Jump = if_JAL | if_JALR;
    Branch = if_BRANCH;
    ALUSrc[0] = if_LOAD | if_STORE | if_IMM | if_AUIPC;
    ALUSrc[1] = if_AUIPC;
    // Result Source
    if(if_REG | if_IMM | if_AUIPC | if_BRANCH | if_STORE) ResultSrc = 2'b00; // branch and store are included here because it doesn't matter what they are
    else if(if_LOAD) ResultSrc = 2'b01;
    else if(if_JAL | if_JALR) ResultSrc = 2'b10;
    else if(if_LUI) ResultSrc = 2'b11;
    // ALU Operation
    if(if_LUI | if_JAL | if_JALR) ALUOp = 2'b00;
    else if(if_REG | if_IMM) ALUOp = 2'b01;
    else if(if_LOAD | if_STORE | if_AUIPC) ALUOp = 2'b10;
    else if(if_BRANCH) ALUOp = 2'b11;
    LinkRegCtrl = if_JALR;
end
*/
// Register File 
reg [DATA_WIDTH-1:0] RegisterFile [31:0];

integer i;

// Register Assignment
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        RegWriteC <= 0;
        ResultSrcC <= 0;
        MemWriteC <= 0;
        JumpC <= 0;
        BranchC <= 0;
        ALUSrcC <= 0;
        ALUOpC <= 0;
        LinkRegCtrlC <= 0;
        ImmExtC <= 0;
        RdC <= 0;
        RData1C <= 0;
        RData2C <= 0;
        Funct7C <= 0;
        Funct3C <= 0;
        Rs1C <= 0;
        Rs2C <= 0;
        PCC <= 0;
        PCPlus4C <= 0;
        for(i = 0; i < 32; i = i + 1) begin
            RegisterFile[i] <= 0;
        end
    end else begin
        // Register write
        if(WrEnE) begin
            RegisterFile[WrAddrE] <= WrDataE;
        end
        // Register read
        RData1C <= RegisterFile[Rs1];
        RData2C <= RegisterFile[Rs2];
        // Control signal assignment
        RegWriteC <= RegWrite;
        ResultSrcC <= ResultSrc;
        MemWriteC <= MemWrite;
        JumpC <= Jump;
        BranchC <= Branch;
        ALUSrcC <= ALUSrc;
        ALUOpC <= ALUOp;
        LinkRegCtrlC <= LinkRegCtrl;
        // Immediate extension
        ImmExtC <= ImmExt;
        // Rd, rs1, rs2 addr
        RdC <= Rd;
        Rs1C <= Rs1;
        Rs2C <= Rs2;
        // Funct7 & Funct3
        Funct7C <= Funct7;
        Funct3C <= Funct3;
        // PC & PC+4
        PCC <= PCB;
        PCPlus4C <= PCPlus4B;
    end
end
endmodule