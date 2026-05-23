// timer.v
module timer (
    input clk,
    input reset,
    output reg [7:0] tcnt0  // Timer/Counter Register
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tcnt0 <= 0;
        end else begin
            tcnt0 <= tcnt0 + 1; // Runs continuously in the background
        end
    end
endmodule
