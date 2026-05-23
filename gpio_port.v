module gpio_port (
    input wire clk,
    input wire reset,
    input wire [7:0] bus_addr,
    input wire [7:0] bus_wdata,
    input wire bus_we,
    output reg [7:0] pin_state
);
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pin_state <= 8'b00000000;
        end else begin
            // Address 0x25 simulates PORTB memory mapping
            if (bus_we == 1'b1 && bus_addr == 8'h25) begin
                pin_state <= bus_wdata;
            end
        end
    end
endmodule
