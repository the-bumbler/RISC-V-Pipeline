

module fetch # (
    parameter DATA_WIDTH = 32
) (
    // Clock and reset
    input                       clk,
    input                       rst_n,
    // Branch PC target and control signal
    input                       PCSrcA,
    input      [DATA_WIDTH-1:0] PCTargetA,
    // Instruction address output and instruction read input
    output     [DATA_WIDTH-1:0] InstrAddr,
    input      [31:0]           Instr,
    // B-side output: Instr, PC, & PC+4
    output reg [31:0]           InstrB,
    output reg [DATA_WIDTH-1:0] PCB,
    output reg [DATA_WIDTH-1:0] PCPlus4B
);

// Internal wire and register definitions
wire [DATA_WIDTH-1:0] PCPlus4;
reg  [DATA_WIDTH-1:0] PC;

assign PCPlus4 = PC + 4;
assign InstrAddr = PC;

// Register assigments
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        PC <= 0;
        InstrB <= 0;
        PCB <= 0;
        PCPlus4B <= 0;
    end else begin
        PC <= (PCSrcA) ? PCTargetA : PCPlus4;
        InstrB <= Instr;
        PCB <= PC;
        PCPlus4B <= PCPlus4;
    end
end 

endmodule