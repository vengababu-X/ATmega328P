module micro_avr_cpu (
    input wire clk,
    input wire reset,
    output reg [7:0] portb_out,
    output reg uart_tx_req,
    output reg [7:0] uart_tx_data
);

    // 32 General Purpose Registers
    reg [7:0] registers [0:31];
    
    // Program Counter
    reg [15:0] pc;
    
    // Loop variable declared at the module level for maximum compatibility
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            // Strictly structured loop for Icarus Verilog compatibility
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
            
            // Initialize other registers
            pc <= 16'b0;
            portb_out <= 8'b00000000;
            uart_tx_req <= 1'b0;
            uart_tx_data <= 8'b00000000;
            
        end else begin
            
            // Auto-clear UART request flag after 1 clock cycle
            if (uart_tx_req == 1'b1) begin
                uart_tx_req <= 1'b0;
            end
            
            // Increment Program Counter safely
            pc <= pc + 16'd1;
            
            // Simulated Instruction Execution Cycle
            if (pc == 16'd5) begin
                // Simulate: LDI R16, 0xFF
                registers[16] <= 8'hFF;
            end 
            else if (pc == 16'd10) begin
                // Simulate: OUT PORTB, R16
                portb_out <= registers[16];
            end
            else if (pc == 16'd15) begin
                // Simulate: UART TX request for 'A'
                uart_tx_data <= 8'h41; 
                uart_tx_req <= 1'b1;
            end

        end
    end

endmodule
