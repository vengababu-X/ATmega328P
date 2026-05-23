module micro_avr_cpu (
    input wire clk,
    input wire reset,
    output reg [7:0] portb_out,
    output reg uart_tx_req,
    output reg [7:0] uart_tx_data
);

    // 32 General Purpose Registers
    reg [7:0] registers [0:31];
    
    // Program Memory (ROM) - 128 slots for 16-bit instructions
    reg [15:0] prog_mem [0:127];
    
    // Program Counter and Instruction Register
    reg [15:0] pc;
    reg [15:0] instruction;
    
    // Module-level integer for strict compiler loop compatibility
    integer i;

    // SIMULATION INITIALIZATION: Guaranteed to eliminate 'x' states 
    // and highly favored by strict compilers.
    initial begin
        // 1. Wipe all 32 registers to 0
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 8'b00000000;
        end
        
        // 2. Wipe Program Memory to 0 (NOP / No-Operations)
        for (i = 0; i < 128; i = i + 1) begin
            prog_mem[i] = 16'b0000000000000000;
        end
        
        // 3. LOAD OUR PROGRAM INTO ROM!
        // Custom 16-bit structure: [15:12] Opcode | [11:8] Reg | [7:0] Data
        prog_mem[0] = 16'h10FF; // Opcode 1: LDI R16, 0xFF (Load 0xFF into R16)
        prog_mem[1] = 16'h2000; // Opcode 2: OUT PORTB, R16 (Push R16 to PORTB)
        prog_mem[2] = 16'h3041; // Opcode 3: UART TX 'A'   (Send hex 0x41)
    end

    // HARDWARE EXECUTION CYCLE
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            // Hardware-accurate reset (Only wiping active control registers)
            pc <= 16'b0;
            instruction <= 16'b0;
            portb_out <= 8'b00000000;
            uart_tx_req <= 1'b0;
            uart_tx_data <= 8'b00000000;
        end else begin
            
            // Auto-clear UART request flag after 1 clock cycle
            if (uart_tx_req == 1'b1) begin
                uart_tx_req <= 1'b0;
            end
            
            // --- THE CPU PIPELINE ---
            
            // STAGE 1: FETCH
            // Grab the current instruction from the ROM using the PC
            instruction <= prog_mem[pc];
            
            // STAGE 2: DECODE & EXECUTE
            // Read the top 4 bits (the Opcode) to decide what to do
            case (instruction[15:12])
                4'h1: begin 
                    // Execute LDI (Load Immediate)
                    registers[16 + instruction[11:8]] <= instruction[7:0];
                end
                4'h2: begin 
                    // Execute OUT (Push to Pins)
                    portb_out <= registers[16 + instruction[11:8]];
                end
                4'h3: begin 
                    // Execute UART TX
                    uart_tx_data <= instruction[7:0];
                    uart_tx_req <= 1'b1;
                end
                default: begin
                    // Do nothing (NOP)
                end
            endcase
            
            // STAGE 3: INCREMENT
            // Move the Program Counter to the next memory address
            pc <= pc + 16'd1;
            
        end
    end

endmodule
