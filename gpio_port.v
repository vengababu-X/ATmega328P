// gpio_port.v
// Simulates a physical GPIO port (like PORTB on Arduino, where Pin 13 is an LED)
module gpio_port (
    input clk,
    input reset,
    input we,             // Write Enable from CPU
    input [7:0] wdata,    // Data from CPU
    output reg [7:0] pins // The physical pins on the outside of the DIP chip
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pins <= 8'b00000000;
        end else if (we) begin
            pins <= wdata;
        end
    end
endmodule
