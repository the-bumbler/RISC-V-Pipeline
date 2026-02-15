

module execute #(
    parameter DATA_WIDTH = 32
) (
    // Clock and reset 
    input                       clk,
    input                       rst_n,

    // C stage input (clocked)
    // PC & PC+4 input
    input      [DATA_WIDTH-1:0] PCC,
    input      [DATA_WIDTH-1:0] PCPlus4C,
    // Control signals inputs 
    input                       RegWriteC,
    input                       MemWriteC,
    input                       JumpC,
    input                       BranchC,
    input      [1:0]            ALUSrcC,
    input      [1:0]            ResultSrcC,
    input      [1:0]            ALUOpC,
    input                       LinkRegCtrlC,
    // Immediate extended 
    input      [DATA_WIDTH-1:0] ImmExtC,
    // Destination address 
    input      [4:0]            RdC,
    // Register Data 
    input      [DATA_WIDTH-1:0] RData1C,
    input      [DATA_WIDTH-1:0] RData2C,
    // Function 7 & 3, ALU Control
    //input      [6:0]            Funct7C,
    input      [2:0]            Funct3C,
    input      [4:0]            ALUControlC,

    // Hazard control input & output (non-clocked)
    // Rs Hazard control address input and output 
    input      [4:0]            Rs1,
    input      [4:0]            Rs2,
    output     [4:0]            Rs1H,
    output     [4:0]            Rs2H,
    // Hazard forward control
    input      [1:0]            ForwardAH,
    input      [1:0]            ForwardBH,
    // Hazard forward Data
    input      [DATA_WIDTH-1:0] ForwardALUResultDH,   // data taken from ALU result (mem stage)
    input      [DATA_WIDTH-1:0] ForwardWriteResultEH, // data taken from ResultSrc (writeback stage)
    
    // Fetch output (non-clocked, branch/jump)
    // PC target and source A branch
    output                      PCSrcA,
    output     [DATA_WIDTH-1:0] PCTargetA,

    // D stage output (clocked)
    // Control signals
    output reg                  RegWriteD,
    output reg [1:0]            ResultSrcD,
    output reg                  MemWriteD,
    // PC+4 Passthrough
    output reg [DATA_WIDTH-1:0] PCPlus4D,
    // Destination address passthrough
    output reg [4:0]            RdD,
    // Mem write data 
    output reg [DATA_WIDTH-1:0] MemWriteDataD,
    // ALU Result 
    output reg [DATA_WIDTH-1:0] ALUResultD,
    // Funct3 passthrough for load/store module (might not be used)
    output reg [2:0]            Funct3D
);

// Hazard control addresses
assign Rs1H = Rs1;
assign Rs2H = Rs2;

// Hazard control Mux
wire [DATA_WIDTH-1:0] ForwardSrcA, ForwardSrcB;

assign ForwardSrcA = (ForwardAH == 2'b10) ? ForwardALUResultDH : (ForwardAH == 2'b01) ? ForwardWriteResultEH : RData1C;
assign ForwardSrcB = (ForwardBH == 2'b10) ? ForwardALUResultDH : (ForwardBH == 2'b01) ? ForwardWriteResultEH : RData2C;

// Mux sources
wire signed [DATA_WIDTH-1:0] ALU_A, ALU_B;
wire [DATA_WIDTH-1:0] PCImmSrc;

assign ALU_A = (ALUSrcC[1]) ? PCC : ForwardSrcA;
assign ALU_B = (ALUSrcC[0]) ? ImmExtC : ForwardSrcB;
assign PCImmSrc = (LinkRegCtrlC) ? RData1C : PCC;

// PC + Imm adder
assign PCTargetA = PCImmSrc + ImmExtC;

// ALU wires
reg signed [DATA_WIDTH-1:0] ALUResult;

// ADDER Wires
wire carry_in;
reg adder_enable;
wire [DATA_WIDTH-1:0] adder_in_A; 
wire [DATA_WIDTH-1:0] adder_in_B;
wire [DATA_WIDTH-1:0] adder_result;
wire [3:0] ZCNO;

assign adder_in_A = ALU_A;
assign adder_in_B = ALU_B;
assign carry_in = ((ALUOpC == 2'b11) | (ALUControlC[3] & ~ALUSrcC[0]));

ADDER #(.DATA_WIDTH(DATA_WIDTH)) ADDER_SUBTRACTOR (
    .enable(adder_enable),
    .A(adder_in_A), 
    .B(adder_in_B),
    .carry_in(carry_in),
    .result(adder_result),
    .ZCNO(ZCNO)
);

// Funct3 - I Extension
localparam ADD_SUB = 3'b000;
localparam XOR     = 3'b100;
localparam OR      = 3'b110;
localparam AND     = 3'b111;
localparam SLL     = 3'b001;
localparam SRL_A   = 3'b101;
localparam SLT     = 3'b010;
localparam SLTU    = 3'b011;

// ALU
always @(*) begin
    adder_enable = 0;
    case(ALUOpC)
        2'b11: begin 
            adder_enable = 1;
            ALUResult = adder_result;
        end
        2'b10: begin 
            adder_enable = 1;
            ALUResult = adder_result;
        end
        2'b01: begin
            if(~ALUControlC[4]) begin
                adder_enable = 0;
                case(ALUControlC[2:0]) 
                    ADD_SUB: begin 
                        adder_enable = 1;
                        ALUResult = adder_result;
                    end
                    XOR: ALUResult = ALU_A ^ ALU_B;
                    OR: ALUResult = ALU_A | ALU_B;
                    AND: ALUResult = ALU_A & ALU_B;
                    SLL: ALUResult = ALU_A << ALU_B[4:0];
                    SRL_A: ALUResult = (ALUControlC[3]) ? ALU_A >>> ALU_B[4:0] : ALU_A >> ALU_B[4:0];
                    SLT: ALUResult = ALU_A < ALU_B;
                    SLTU: ALUResult = $unsigned(ALU_A) < $unsigned(ALU_B);
                endcase
            end
        end
        default: begin 
            ALUResult = 0;
        end
    endcase
end

// Branch Funct3
localparam BEQ  = 3'b000; // branch if equal
localparam BNE  = 3'b001; // branch if not equal
localparam BLT  = 3'b100; // branch if less than (signed)
localparam BGE  = 3'b101; // branch if greater than or equal to (signed)
localparam BLTU = 3'b110; // branch if less than (unsigned)
localparam BGEU = 3'b111; // branch if greater than or equal to (unsigned)

// Branch logic wire
reg branch_logic;

// Branch logic unit
always @(*) begin
    if(BranchC) begin
        case(Funct3C) 
            BEQ: branch_logic = ZCNO[3];
            BNE: branch_logic = ~ZCNO[3];
            BLT: branch_logic = (ZCNO[0] ^ ZCNO[1]);
            BGE: branch_logic = ~(ZCNO[0] ^ ZCNO[1]) | ZCNO[3];
            BLTU: branch_logic = (~ZCNO[2] & ZCNO[1]);
            BGEU: branch_logic = (ZCNO[2] & ~ZCNO[1]) | ZCNO[3];
        endcase
    end
end

assign PCSrcA = branch_logic | JumpC;

// D side output registers
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        RegWriteD <= 0;
        ResultSrcD <= 0;
        MemWriteD <= 0;
        PCPlus4D <= 0;
        RdD <= 0;
        MemWriteDataD <= 0;
        ALUResultD <= 0;
        Funct3D <= 0;
    end else begin
        RegWriteD <= RegWriteC;
        ResultSrcD <= ResultSrcD;
        MemWriteD <= MemWriteC;
        PCPlus4D <= PCPlus4C;
        RdD <= RdC;
        MemWriteDataD <= ForwardSrcB;
        ALUResultD <= ALUResult;
        Funct3D <= Funct3C;
    end
end

endmodule

module ADDER #(
    parameter DATA_WIDTH = 32
) (
    input enable,
    input [DATA_WIDTH-1:0] A, B,
    input carry_in,
    output [DATA_WIDTH-1:0] result,
    output [3:0] ZCNO
);
localparam BIT_WIDTH = 8; // bitwidth of CLA
localparam MODULE_COUNT = DATA_WIDTH/BIT_WIDTH;
localparam MSB = DATA_WIDTH;

wire [DATA_WIDTH-1:0] B_ctrl;
assign B_ctrl = B ^ {DATA_WIDTH{carry_in}};

wire [MODULE_COUNT:0] carry_array;
assign carry_array[0] = carry_in;

generate 
    genvar i;
    for(i = 0; i < MODULE_COUNT; i = i + 1) begin : CLA_submodule
        CLA #(.BIT_WIDTH(BIT_WIDTH)) CLA_instance (
            .enable(enable),
            .A(A[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i]),
            .B(B_ctrl[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i]),
            .carry_in(carry_array[i]),
            .sum(result[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i]),
            .carry_out(carry_array[i+1])
        );
    end
endgenerate

assign ZCNO[0] = (A[MSB] & B_ctrl[MSB] & ~result[MSB]) | (~A[MSB] & ~B_ctrl[MSB] & result[MSB]);
assign ZCNO[1] = result[MSB];
assign ZCNO[2] = carry_array[MODULE_COUNT];
assign ZCNO[3] = ~(|result);

endmodule

module CLA #(
    parameter BIT_WIDTH = 8
) (
    input enable,
    input [BIT_WIDTH-1:0] A, B,
    input carry_in,
    output reg [BIT_WIDTH-1:0] sum,
    output carry_out
);

reg [BIT_WIDTH:0] carry;
assign carry_out = carry[BIT_WIDTH];
reg [BIT_WIDTH-1:0] p, g;

integer k;

always @(*) begin
    if(enable) begin
        g = A & B;
        p = A ^ B;
        carry[0] = carry_in;
        for(k = 0; k < BIT_WIDTH; k = k + 1) begin
            carry[k+1] = g[k] | (p[k] & carry[k]);
        end
        sum = carry[BIT_WIDTH-1:0] ^ p;
    end
end

endmodule