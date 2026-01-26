

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
    output     [DATA_WIDTH-1:0] PCTargetA,
    output reg [DATA_WIDTH-1:0] PCPlus4C,
    // Register write-back data, address, and signal (from E stage)
    input                       WrEnE,
    input      [4:0]            WrAddrE,
    input      [DATA_WIDTH-1:0] WrDataE,
    // Control Signal outputs 
    output reg                  RegWriteC,
    output reg [1:0]            ResultSrcC,
    output reg                  MemWriteC,
    output reg                  JumpC,
    output reg                  BranchC,
    output reg [1:0]            ALUSrcC,
    output reg [1:0]            ALUOpC,
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
wire [1:0] ALUSrc;    // ALUSrc[0] will control the mux for rs2 & imm, ALUSrc[1] will control the mux for rs1 & PC
wire [1:0] ResultSrc; // control signal for 4 input mux at writeback stage
wire [2:0] ImmGenSrc; // immediate generator signals for 5 types of immediate formats
wire [1:0] ALUOp;     // ALU control that chooses functs, or forces add/sub

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
localparam I_IMM = 3'b001;
localparam S_IMM = 3'b010;
localparam B_IMM = 3'b011;
localparam U_IMM = 3'b100;
localparam J_IMM = 3'b101;

// Immediate Extender Result
wire ImmExt;

// Immediate Extender 
//      For I-type instructions, Imm[11:0] are Instr[31:20]
//      For S-type instructions, Imm[11:5 | 4:0] are Instr[31:25] & Instr[11:7]
//      For B-type instructions, Imm[12 | 11 | 10:5 | 4:1] are Instr[31] & Instr[7] & Instr[30:25] & Instr[11:8]
assign ImmExt = (ImmGenSrc == I_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[31:20]} : 
                (ImmGenSrc == S_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[31:25], InstrB[11:7]} : 
                (ImmGenSrc == B_IMM) ? {{(DATA_WIDTH-12){InstrB[31]}}, InstrB[7], InstrB[30:25], InstrB[11:8], 1'b0} : 
                (ImmGenSrc == U_IMM) ? {{(DATA_WIDTH-32){InstrB[31]}}, InstrB[31:12], {12{1'b0}}} :
                (ImmGenSrc == J_IMM) ? {{(DATA_WIDTH-20){InstrB[31]}}, InstrB[31], InstrB[19:12], InstrB[20], InstrB[30:21], 1'b0} : 
                32'h0000_0000;

/*
// Control Unit 
assign RegWrite  = (Opcode == OP_LOAD  | Opcode == OP_REG  | Opcode == OP_IMM | Opcode ==  OP_JUMP | Opcode == OP_LUI | Opcode == OP_AUIPC) ? 1'b1 : 1'b0;
assign MemWrite  = (Opcode == OP_STORE) ? 1'b1 : 1'b0; 
assign Jump      = (Opcode == OP_JUMP) ? 1'b1 : 1'b0;
assign Branch    = (Opcode == OP_BRANCH) ? 1'b1 : 1'b0;   
assign ALUSrc    = (Opcode == OP_LOAD | Opcode == OP_STORE | Opcode == OP_IMM | ) ? 1'b1 : 1'b0;
//assign ALUSrc[1] = (Opcode == OP_JALR) ? 1'b1 : 1'b0;
assign ALUOp     = (Opcode == OP_JAL | Opcode == OP_JALR) ? 2'b01 : (Opcode == OP_LUI) ? 2'b10 : (Opcode == OP_AUIPC) ? 2'b11 : 2'b00;
assign ResultSrc = (Opcode == OP_LOAD) ? 1'b01 : (Opcode == OP_JUMP) ? 1'b10 : 1'b00; 
assign ImmGenSrc = (Opcode == OP_IMM) ? I_IMM : (Opcode == OP_STORE) ? S_IMM : (Opcode == OP_BRANCH) ? B_IMM : 
                   (Opcode == OP_JALR | Opcode == OP_JAL) ? J_IMM : (Opcode == OP_AUIPC | Opcode == OP_LUI) ? U_IMM : 3'b000;
*/


endmodule