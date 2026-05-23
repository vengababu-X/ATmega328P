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
    reg [7:0] sreg;                    // Status Register (Bit 1: Zero, Bit 0: Carry)
    reg [7:0] sp;                      // NEW: Stack Pointer
    reg [8:0] alu_temp;                // ALU math buffer
    
    integer i;

    // --- SIMULATION INITIALIZATION ---
    initial begin
        for (i = 0; i < 32; i = i + 1) registers[i] = 8'b00000000;
        for (i = 0; i < 256; i = i + 1) sram[i] = 8'b00000000;
        for (i = 0; i < 128; i = i + 1) prog_mem[i] = 16'b0000000000000000;
        
        // --- NEW TEST PROGRAM: SUBROUTINES ---
        
        // MAIN ROUTINE
        prog_mem[0] = 16'h1005; // LDI R16, 0x05
        prog_mem[1] = 16'h304D; // OUT UART, 'M' (Indicates Main routine started)
        prog_mem[2] = 16'hA006; // CALL 0x06 (Jump to Subroutine at memory address 6)
        prog_mem[3] = 16'h3052; // OUT UART, 'R' (Indicates successful Return!)
        prog_mem[4] = 16'hF000; // HALT (Freeze CPU, program complete)
        prog_mem[5] = 16'h0000; // NOP (Padding)
        
        // SUBROUTINE (Located at PC = 6)
        prog_mem[6] = 16'h110A; // LDI R17, 0x0A (Load 10)
        prog_mem[7] = 16'h5010; // ADD R16, R17 (5 + 10 = 15 / 0x0F)
        prog_mem[8] = 16'h2000; // OUT GPIO, R16 (Push the math result 0x0F to pins)
        prog_mem[9] = 16'hB000; // RET (Pop the return address from Stack and jump back)
    end

    // --- HARDWARE PIPELINE CYCLE ---
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pc <= 16'b0;
            instruction <= 16'b0;
            sreg <= 8'b0;
            sp <= 8'hFF; // Initialize Stack Pointer to the very top of SRAM
            
            gpio_we <= 1'b0;
            gpio_wdata <= 8'b00000000;
            uart_we <= 1'b0;
            uart_wdata <= 8'b00000000;
        end else begin
            
            gpio_we <= 1'b0;
            uart_we <= 1'b0;
            
            // --- STAGE 1: FETCH ---
            instruction <= prog_mem[pc];
            
            // Default PC increment
            pc <= pc + 16'd1;
            
            // --- STAGE 2 & 3: DECODE & EXECUTE ---
            case (instruction[15:12])
                4'h1: registers[16 + instruction[11:8]] <= instruction[7:0]; // LDI
                
                4'h2: begin // OUT GPIO
                    gpio_wdata <= registers[16 + instruction[11:8]];
                    gpio_we <= 1'b1;
                end
                
                4'h3: begin // OUT UART
                    uart_wdata <= instruction[7:0];
                    uart_we <= 1'b1;
                end
                
                4'h4: registers[16 + instruction[11:8]] <= timer_val; // IN Timer
                
                4'h5: begin // ADD
                    alu_temp = registers[16 + instruction[11:8]] + registers[16 + instruction[7:4]];
                    registers[16 + instruction[11:8]] <= alu_temp[7:0];
                    sreg[0] <= alu_temp[8]; 
                    sreg[1] <= (alu_temp[7:0] == 8'b0) ? 1'b1 : 1'b0; 
                end
                
                4'h6: begin // SUB
                    alu_temp = registers[16 + instruction[11:8]] - registers[16 + instruction[7:4]];
                    registers[16 + instruction[11:8]] <= alu_temp[7:0];
                    sreg[1] <= (alu_temp[7:0] == 8'b0) ? 1'b1 : 1'b0; 
                end
                
                4'h7: sram[instruction[7:0]] <= registers[16 + instruction[11:8]]; // STORE
                
                4'h8: registers[16 + instruction[11:8]] <= sram[instruction[7:0]]; // LOAD
                
                4'h9: begin // BREQ
                    if (sreg[1] == 1'b1) pc <= pc + 16'd1 + instruction[7:0]; 
                end
                
                4'hA: begin // NEW: CALL (Jump to Subroutine)
                    // Push the return address (PC + 1) to the Stack
                    sram[sp]   <= (pc + 16'd1) & 16'h00FF;         // Push Low Byte
                    sram[sp-1] <= ((pc + 16'd1) >> 8) & 16'h00FF;  // Push High Byte
                    sp <= sp - 8'd2;                               // Move Stack Pointer down
                    
                    // Jump to the subroutine address
                    pc <= {4'b0, instruction[11:0]}; 
                end
                
                4'hB: begin // NEW: RET (Return from Subroutine)
                    // Pop the return address from the Stack
                    pc <= {sram[sp+1], sram[sp+2]};
                    sp <= sp + 8'd2; // Restore Stack Pointer
                end
                
                4'hF: pc <= pc; // NEW: HALT (Freeze the processor)
                
                default: ; // NOP
            endcase
        end
    end

endmodule

