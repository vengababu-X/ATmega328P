module micro_avr_cpu (
    input wire clk,
    input wire reset,
    
    // Memory-Mapped I/O Peripheral Ports required by testbench
    output reg gpio_we,
    output reg [7:0] gpio_wdata,
    output reg uart_we,
    output reg [7:0] uart_wdata,
    input wire [7:0] timer_val
);

    // 32 General Purpose Registers
    reg [7:0] registers [0:31];
    
    // Program Memory (ROM) - 128 slots for 16-bit instructions
    reg [15:0] prog_mem [0:127];
    
    // Program Counter and Instruction Register
    reg [15:0] pc;
    reg [15:0] instruction;
    
    // Module-level integer for strict loop compatibility
    integer i;

    // SIMULATION INITIALIZATION: Clears arrays cleanly to prevent 'x' states
    initial begin
        // 1. Wipe all 32 registers to 0
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 8'b00000000;
        end
        
        // 2. Wipe Program Memory to NOPs
        for (i = 0; i < 128; i = i + 1) begin
            prog_mem[i] = 16'b0000000000000000;
        end
        
        // 3. LOAD INSTRUCTION PROGRAM
        // Custom 16-bit encoding: [15:12] Opcode | [11:8] Reg | [7:0] Data
        prog_mem[0] = 16'h10FF; // Opcode 1: LDI R16, 0xFF
        prog_mem[1] = 16'h2000; // Opcode 2: OUT to GPIO, write R16 value
        prog_mem[2] = 16'h3041; // Opcode 3: OUT to UART, write data 0x41 ('A')
        prog_mem[3] = 16'h4000; // Opcode 4: IN from TIMER into R17
    end

    // HARDWARE PIPELINE CYCLE
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pc <= 16'b0;
            instruction <= 16'b0;
            
            // Clear all peripheral control lines on reset
            gpio_we <= 1'b0;
            gpio_wdata <= 8'b00000000;
            uart_we <= 1'b0;
            uart_wdata <= 8'b00000000;
        end else begin
            
            // Standard Synchronous Behavior: Clear Write Enables after 1 cycle
            gpio_we <= 1'b0;
            uart_we <= 1'b0;
            
            // --- FETCH ---
            instruction <= prog_mem[pc];
            
            // --- DECODE & EXECUTE ---
            case (instruction[15:12])
                4'h1: begin 
                    // LDI: Load Immediate value into a register
                    registers[16 + instruction[11:8]] <= instruction[7:0];
                end
                
                4'h2: begin 
                    // OUT to GPIO: Pull write-enable high and send data
                    gpio_wdata <= registers[16 + instruction[11:8]];
                    gpio_we <= 1'b1;
                end
                
                4'h3: begin 
                    // OUT to UART: Pull write-enable high and send data
                    uart_wdata <= instruction[7:0];
                    uart_we <= 1'b1;
                end
                
                4'h4: begin
                    // IN from Timer: Read the peripheral port input into register
                    registers[16 + instruction[11:8]] <= timer_val;
                end
                
                default: begin
                    // NOP or Unhandled instruction
                end
            endcase
            
            // --- INCREMENT PROGRAM COUNTER ---
            pc <= pc + 16'd1;
            
        end
    end

endmodule
