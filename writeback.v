

module writeback #(
    parameter DATA_WIDTH = 32
) (
    // Clock and reset
    input                       clk,
    input                       rst_n,

    // E Stage Input
    input      [DATA_WIDTH-1:0] PCPlus4E,
    input                       RegWriteE,
    input      [1:0]            ResultSrcE,
    input      [DATA_WIDTH-1:0] ALUResultE,
    input      [DATA_WIDTH-1:0] MemReadDataE,
    input      [4:0]            RdE,
    input      [DATA_WIDTH-1:0] UpperImmExtE,

    // A Stage output
    output                      RegWriteEn,
    output     [4:0]            RegWrAddr,
    output     [DATA_WIDTH-1:0] RegWrData,

    // Hazard control outputs
    output                      RegWriteEH,
    output     [4:0]            RdEH,
    output     [DATA_WIDTH-1:0] WriteResultEH
);

// Hazard outputs 
assign RegWriteEH = RegWriteE;
assign RdEH = RdE;
assign WriteResultEH = RegWrData;

// Reg write 
assign RegWiteEn = RegWriteE; 
assign RegWrAddr = RdE;

// Result Mux
assign RegWrData = (ResultSrcE == 2'b00) ? ALUResultE : 
                   (ResultSrcE == 2'b01) ? MemReadDataE :
                   (ResultSrcE == 2'b10) ? PCPlus4E :
                   (ResultSrcE == 2'b11) ? UpperImmExtE;

endmodule