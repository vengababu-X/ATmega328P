module data_sram (
    input wire clk,
    input wire [7:0] addr,
    input wire [7:0] wdata,
    input wire we,         // Write Enable
    output reg [7:0] rdata // Read Data
);
    // 256 bytes of SRAM
    reg [7:0] memory [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) memory[i] = 8'b00000000;
    end

    // Synchronous write, asynchronous read
    always @(posedge clk) begin
        if (we == 1'b1) begin
            memory[addr] <= wdata;
        end
        rdata <= memory[addr];
    end
endmodule
