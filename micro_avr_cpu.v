module micro_avr_cpu (
    input wire clk,
    input wire reset,
    
    // Memory-Mapped I/O Peripheral Ports
    output reg gpio_we,
    output reg [7:0] gpio_wdata,
    output reg uart_we,
    output reg [7:0] uart_wdata,
    input wire [7:0] timer_val
);

    // --- INTERNAL MEMORY ARCHITECTURE ---
    reg [7:0] registers [0:31];        // 32 General Purpose Registers
    reg [15:0] prog_mem [0:127];       // Program Memory (ROM)
    reg [7:0] sram [0:255];            // 256 bytes of Data Memory (RAM)
    
    // --- CPU CONTROL REGISTERS ---
    reg [15:0] pc;                     // Program Counter
    reg [15:0] instruction;            // Current Instruction
    
    // Status Register (Bit 1: Zero Flag, Bit 0: Carry Flag)
    reg [7:0] sreg;                    
    
    // 9-bit temporary ALU variable to catch math carry-overs
    reg [8:0] alu_temp;                
    
    // Strict compiler loop compatibility
    integer i;

    // --- SIMULATION INITIALIZATION ---
    initial begin
        // Cleanse all memory arrays to prevent 'x' states
        for (i = 0; i < 32; i = i + 1) registers[i] = 8'b00000000;
        for (i = 0; i < 256; i = i + 1) sram[i] = 8'b00000000;
        for (i = 0; i < 128; i = i + 1) prog_mem[i] = 16'b0000000000000000;
        
        // --- ADVANCED EXTENDED TEST PROGRAM ---
        
        // 1. Output a continuous stream of hex numbers to the UART
        prog_mem[0]  = 16'h3045; // OUT UART, 0x45
        prog_mem[1]  = 16'h3055; // OUT UART, 0x55
        prog_mem[2]  = 16'h3065; // OUT UART, 0x65
        prog_mem[3]  = 16'h3075; // OUT UART, 0x75
        
        // 2. Perform ALU Math and push the result to the GPIO pins
        prog_mem[4]  = 16'h100A; // LDI R16, 0x0A (Load 10 into R16)
        prog_mem[5]  = 16'h110A; // LDI R17, 0x0A (Load 10 into R17)
        prog_mem[6]  = 16'h5010; // ADD R16, R17 (R16 = 0x14 / 20 in decimal)
        prog_mem[7]  = 16'h2000; // OUT GPIO, R16 (Sends 0x14 to the GPIO ports)

        // 3. Test Conditional Branching
        prog_mem[8]  = 16'h6010; // SUB R16, R17 (R16 becomes 0x0A)
        prog_mem[9]  = 16'h6010; // SUB R16, R17 (R16 becomes 0x00. Zero Flag is triggered!)
        prog_mem[10] = 16'h9002; // BREQ +2 (Branch forward 2 steps because Zero Flag is 1)
        
        // 4. Final UART Outputs based on Branch
        prog_mem[11] = 16'h30EE; // OUT UART, 0xEE (ERROR: This will be skipped by the branch)
        prog_mem[12] = 16'h3099; // OUT UART, 0x99 (SUCCESS: The CPU successfully jumped here)
    end

    // --- HARDWARE PIPELINE CYCLE ---
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            // Hardware-accurate peripheral reset
            pc <= 16'b0;
            instruction <= 16'b0;
            sreg <= 8'b0;
            
            gpio_we <= 1'b0;
            gpio_wdata <= 8'b00000000;
            uart_we <= 1'b0;
            uart_wdata <= 8'b00000000;
        end else begin
            
            // Clear Write Enables after 1 cycle to prevent double-writing
            gpio_we <= 1'b0;
            uart_we <= 1'b0;
            
            // --- STAGE 1: FETCH ---
            instruction <= prog_mem[pc];
            
            // Default PC increment (Can be overwritten by branches below)
            pc <= pc + 16'd1;
            
            // --- STAGE 2 & 3: DECODE & EXECUTE ---
            case (instruction[15:12])
                4'h1: begin 
                    // LDI: Load Immediate
                    registers[16 + instruction[11:8]] <= instruction[7:0]; 
                end
                
                4'h2: begin 
                    // OUT: Push to GPIO
                    gpio_wdata <= registers[16 + instruction[11:8]];
                    gpio_we <= 1'b1;
                end
                
                4'h3: begin 
                    // OUT: Push to UART
                    uart_wdata <= instruction[7:0];
                    uart_we <= 1'b1;
                end
                
                4'h4: begin 
                    // IN: Read from Timer
                    registers[16 + instruction[11:8]] <= timer_val; 
                end
                
                4'h5: begin 
                    // ADD Registers & Update Flags
                    alu_temp = registers[16 + instruction[11:8]] + registers[16 + instruction[7:4]];
                    registers[16 + instruction[11:8]] <= alu_temp[7:0];
                    sreg[0] <= alu_temp[8]; // Carry Flag
                    sreg[1] <= (alu_temp[7:0] == 8'b0) ? 1'b1 : 1'b0; // Zero Flag
                end
                
                4'h6: begin 
                    // SUB Registers & Update Flags
                    alu_temp = registers[16 + instruction[11:8]] - registers[16 + instruction[7:4]];
                    registers[16 + instruction[11:8]] <= alu_temp[7:0];
                    sreg[1] <= (alu_temp[7:0] == 8'b0) ? 1'b1 : 1'b0; // Zero Flag
                end
                
                4'h7: begin 
                    // STORE to SRAM
                    sram[instruction[7:0]] <= registers[16 + instruction[11:8]];
                end
                
                4'h8: begin 
                    // LOAD from SRAM
                    registers[16 + instruction[11:8]] <= sram[instruction[7:0]];
                end
                
                4'h9: begin 
                    // BREQ: Branch if Equal (Zero Flag == 1)
                    if (sreg[1] == 1'b1) begin
                        // Overwrite the default PC increment to jump forward
                        pc <= pc + 16'd1 + instruction[7:0]; 
                    end
                end
                
                default: ; // NOP (No Operation)
            endcase
        end
    end

endmodule
