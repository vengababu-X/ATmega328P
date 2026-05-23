module timer_counter0 (
    input wire clk,
    input wire reset,
    output reg interrupt_flag
);
    reg [7:0] tcnt0;

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            tcnt0 <= 8'b0;
            interrupt_flag <= 1'b0;
        end else begin
            tcnt0 <= tcnt0 + 8'd1;
            
            // Trigger flag when the counter overflows (255)
            if (tcnt0 == 8'hFF) begin
                interrupt_flag <= 1'b1;
            end else begin
                // Auto-clear flag for simulation simplicity
                interrupt_flag <= 1'b0; 
            end
        end
    end
endmodule
