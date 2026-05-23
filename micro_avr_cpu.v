module micro_avr_cpu (
    input wire clk,
    input wire reset,
    output reg [7:0] portb_out,
    output reg uart_tx_req,
    output reg [7:0] uart_tx_data
);

    // 32 General Purpose Registers (R0 to R31)
    reg [7:0] registers [0:31];
    
    // Program Counter (PC)
    reg [15:0] pc;
    
    // Variable for loops
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // THE FIX: Clear all 32 registers to 0 on startup to eliminate 'x' states
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 8'b00000000;
            end
            
            // Initialize other core components
            pc <= 16'b0;
            portb_out <= 8'b00000000;
            uart_tx_req <= 1'b0;
            uart_tx_data <= 8'b00000000;
            
        end else begin
            // THE NEW UPGRADE: Basic Instruction Execution Cycle
            
            // Auto-clear UART request flag after 1 clock cycle
            if (uart_tx_req) begin
                uart_tx_req <= 1'b0;
            end
            
            // Increment Program Counter
            pc <= pc + 1;
            
            // Placeholder for fetched instruction (Normally comes from Program ROM)
            // Here we can build the ALU (Arithmetic Logic Unit) logic. 
            // For example, simulating a specific instruction execution at specific PC times:
            
            if (pc == 16'd5) begin
                // Simulate: LDI R16, 0xFF (Load immediate)
                registers[16] <= 8'hFF;
            end 
            else if (pc == 16'd10) begin
                // Simulate: OUT PORTB, R16 (Output to pins)
                portb_out <= registers[16];
            end
            else if (pc == 16'd15) begin
                // Simulate: UART TX request
                uart_tx_data <= 8'h41; // ASCII 'A'
                uart_tx_req <= 1'b1;
            end

        end
    end

endmodule
