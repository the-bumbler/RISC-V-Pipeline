

module hazard #(
    parameter DATA_WIDTH = 32
) (
    // Reset signal
    input                   rst_n,
    // C side 
    // Rs1 & Rs2 addresses for ALU input
    input  [4:0]            Rs1CH,
    input  [4:0]            Rs2CH,
    // D side 
    // Write desination address for result
    input  [4:0]            RdDH,
    // ALU result for pass through
    input  [DATA_WIDTH-1:0] ALUResultDH,
    // Register write enable 
    input                   RegWriteDH,

    // E side
    // Write desination address for result
    input  [4:0]            RdEH,
    // Writeback result for pass through
    input  [DATA_WIDTH-1:0] WriteResultEH,
    // Register write enable 
    input                   RegWriteEH,

    // Mux control outputs
    output [1:0]            ForwardAH,
    output [1:0]            ForwardBH
);

assign ForwardAH = (~rst_n) ? 2'b00 : 
                   ((RegWriteEH) & (RdEH != 0) & (RdEH == Rs1CH)) ? 2'b01 :
                   ((RegWriteDH) & (RdDH != 0) & (RdDH == Rs1CH)) ? 2'b10 : 2'b00;
assign ForwardBH = (~rst_n) ? 2'b00 : 
                   ((RegWriteEH) & (RdEH != 0) & (RdEH == Rs2CH)) ? 2'b01 :
                   ((RegWriteDH) & (RdDH != 0) & (RdDH == Rs2CH)) ? 2'b10 : 2'b00;

endmodule