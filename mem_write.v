

module mem_write #(
    parameter DATA_WIDTH = 32
) (
    // Clock and reset 
    input                       clk,
    input                       rst_n,

    // D stage input 
    // PC+4 & Passthrough
    input      [DATA_WIDTH-1:0] PCPlus4D,
    output reg [DATA_WIDTH-1:0] PCPlus4E,
    // Control signals
    input                       RegWriteD,
    input      [1:0]            ResultSrcD,
    input                       MemWriteD,
    // ALU Result
    input      [DATA_WIDTH-1:0] ALUResultD,
    // Memory Write Data
    input      [DATA_WIDTH-1:0] MemWriteDataD,
    // Destination address
    input      [4:0]            RdD,
    // Immediate pass through
    input      [DATA_WIDTH-1:0] UpperImmExtD,
    // Funct3
    input      [2:0]            Funct3D,

    // Memory file input and output
    output                      WriteEn,
    output reg [DATA_WIDTH-1:0] MemAddress,
    output reg [DATA_WIDTH-1:0] MemStoreData,
    input      [DATA_WIDTH-1:0] MemLoadData,

    // E Stage output 
    // Control signals output
    output reg                  RegWriteE,
    output reg [1:0]            ResultSrcE,
    // ALU Result
    output reg [DATA_WIDTH-1:0] ALUResultE,
    // Memory Read
    output reg [DATA_WIDTH-1:0] MemReadDataE,
    // Destination Register Address passthrough
    output reg [4:0]            RdE,
    // Immediate value passthrough
    output reg [DATA_WIDTH-1:0] UpperImmExtE,

    // Hazard control outputs
    output                      RegWriteDH,
    output     [DATA_WIDTH-1:0] ALUResultDH,
    output     [4:0]            RdDH
);

// Hazard control outputs
assign RegWriteDH = RegWriteD;
assign ALUResultDH = ALUResultD;
assign RdDH = RdD;

// Memory file signals
assign MemAddress = ALUResultD;
assign WriteEn = MemWriteD;

// Funct3 codes
localparam BYTE  = 3'b000;
localparam HALF  = 3'b001;
localparam WORD  = 3'b010;
localparam BYTEU = 3'b100;
localparam HALFU = 3'b101;

// Half word 
localparam HALF_DATA = DATA_WIDTH/2;

// Load/Store module
reg [DATA_WIDTH-1:0] MemData;
always @(*) begin
    if(~MemWriteD) begin // Store
        case(Funct3D) 
            BYTE: MemStoreData = {{(DATA_WIDTH-8){MemWriteDataD[7]}}, MemWriteDataD[7:0]};
            HALF: MemStoreData = {{(DATA_WIDTH-HALF_DATA){MemWriteDataD[HALF_DATA-1]}}, MemWriteDataD[HALF_DATA-1:0]};
            WORD: MemStoreData = MemWriteDataD;
        endcase
    end else begin // Load
        case(Funct3D)
            BYTE: MemData = {{(DATA_WIDTH-8){MemLoadData[7]}}, MemLoadData[7:0]};
            HALF: MemData = {{(DATA_WIDTH-HALF_DATA){MemLoadData[HALF_DATA-1]}}, MemLoadData[HALF_DATA-1:0]};
            WORD: MemData = MemLoadData;
            BYTEU: MemData = {{(DATA_WIDTH-8){1'b0}}, MemLoadData[7:0]};
            HALFU: MemData = {{(DATA_WIDTH-HALF_DATA){1'b0}}, MemLoadData[HALF_DATA-1:0]};
        endcase
    end
end

// E side output registers
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        PCPlus4E <= 0;
        RegWriteE <= 0;
        ResultSrcE <= 0;
        ALUResultE <= 0;
        MemReadDataE <= 0;
        RdE <= 0;
        UpperImmExtE <= 0;
    end else begin
        PCPlus4E <= PCPlus4D;
        RegWriteE <= RegWriteD;
        ResultSrcE <= ResultSrcD;
        ALUResultE <= ALUResultD;
        MemReadDataE <= MemData;
        RdE <= RdD;
        UpperImmExtE <= UpperImmExtD;
    end
end

endmodule
