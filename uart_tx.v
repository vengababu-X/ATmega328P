// uart_tx.v
module uart_tx (
    input clk,
    input reset,
    input tx_start,       // Triggered by CPU writing to UDR0
    input [7:0] tx_data,  // The byte to send
    output reg tx_pin,    // The physical TX pin
    output reg tx_ready   // Tells CPU if UART is busy
);
    reg [3:0] state;
    reg [7:0] shift_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_pin <= 1;
            tx_ready <= 1;
            state <= 0;
        end else begin
            case (state)
                0: begin // Idle State
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_ready <= 0;
                        tx_pin <= 0; // Start Bit
                        state <= 1;
                    end else begin
                        tx_pin <= 1;
                        tx_ready <= 1;
                    end
                end
                1, 2, 3, 4, 5, 6, 7, 8: begin // Data Bits
                    tx_pin <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    state <= state + 1;
                end
                9: begin // Stop Bit
                    tx_pin <= 1;
                    state <= 0;
                end
            endcase
        end
    end
endmodule
