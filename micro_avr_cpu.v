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
    reg [7:0] registers [0:31];        
    reg [15:0] prog_mem [0:127];       
    reg [7:0] sram [0:255];            
    
    // --- CPU CONTROL REGISTERS ---
    reg [15:0] pc;                     
    reg [15:0] instruction;            
    reg [7:0] sreg;                    
    reg [7:0] sp;                      
    reg [8:0] alu_temp;                
    
    // --- NEW: HARDWARE TIMER PERIPHERAL ---
    reg [7:0] tcnt0;                   // Timer Counter 0 (Runs independently)
    reg timer_interrupt_flag;          // Flags the CPU when the timer overflows
    
    integer i;

    // --- SIMULATION INITIALIZATION ---
    initial begin
        for (i = 0; i < 32; i = i + 1) registers[i] = 8'b00000000;
        for (i = 0; i < 256; i = i + 1) sram[i] = 8'b00000000;
        for (i = 0; i < 128; i = i + 1) prog_mem[i] = 16'b0000000000000000;
        
        // --- NEW TEST PROGRAM: INTERRUPT VECTORS ---
        
        // 0x0000: RESET VECTOR (Jump to Main)
        prog_mem[0] = 16'hC003; // RJMP 0x03 (Jump to PC=3)
        
        // 0x0001: TIMER OVERFLOW INTERRUPT VECTOR
        prog_mem[1] = 16'hC007; // RJMP 0x07 (Jump to ISR at PC=7)
        prog_mem[2] = 16'h0000; // NOP
        
        // --- MAIN PROGRAM (Starts at PC=3) ---
        prog_mem[3] = 16'h1001; // LDI R16, 0x01
        prog_mem[4] = 16'h304D; // OUT UART, 'M' (Main Loop Running)
        prog_mem[5] = 16'hC004; // RJMP 0x04 (Infinite loop back to PC=4)
        prog_mem[6] = 16'h0000; // NOP
        
        // --- INTERRUPT SERVICE ROUTINE (Starts at PC=7) ---
        prog_mem[7] = 16'h3049; // OUT UART, 'I' (Interrupt Triggered!)
        prog_mem[8] = 16'hB000; // RET (Return from Interrupt to Main Loop)
    end

    // --- HARDWARE PIPELINE CYCLE ---
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pc <= 16'b0;
            instruction <= 16'b0;
            sreg <= 8'b0;
            sp <= 8'hFF; 
            
            tcnt0 <= 8'b0;
            timer_interrupt_flag <= 1'b0;
            
            gpio_we <= 1'b0;
            gpio_wdata <= 8'b00000000;
            uart_we <= 1'b0;
            uart_wdata <= 8'b00000000;
        end else begin
            
            gpio_we <= 1'b0;
            uart_we <= 1'b0;
            
            // --- BACKGROUND HARDWARE TIMER ---
            tcnt0 <= tcnt0 + 8'd1;
            if (tcnt0 == 8'hFF) begin
                timer_interrupt_flag <= 1'b1; // Trigger interrupt on overflow
            end
            
            // --- INTERRUPT HANDLING ---
            if (timer_interrupt_flag == 1'b1) begin
                // Acknowledge and clear the flag
                timer_interrupt_flag <= 1'b0;
                
                // Push current PC to Stack (Context Save)
                sram[sp]   <= pc & 16'h00FF;         
                sram[sp-1] <= (pc >> 8) & 16'h00FF;  
                sp <= sp - 8'd2;                     
                
                // Jump to Timer Interrupt Vector (PC = 1)
                pc <= 16'h0001;
                
            end else begin
                // --- NORMAL CPU PIPELINE ---
                
                instruction <= prog_mem[pc];
                pc <= pc + 16'd1; // Default increment
                
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
                    
                    4'h5: begin // ADD
                        alu_temp = registers[16 + instruction[11:8]] + registers[16 + instruction[7:4]];
                        registers[16 + instruction[11:8]] <= alu_temp[7:0];
                        sreg[0] <= alu_temp[8]; 
                        sreg[1] <= (alu_temp[7:0] == 8'b0) ? 1'b1 : 1'b0; 
                    end
                    
                    4'h7: sram[instruction[7:0]] <= registers[16 + instruction[11:8]]; // STORE
                    4'h8: registers[16 + instruction[11:8]] <= sram[instruction[7:0]]; // LOAD
                    
                    4'hB: begin // RET / RETI (Return from Interrupt)
                        pc <= {sram[sp+1], sram[sp+2]};
                        sp <= sp + 8'd2; 
                    end
                    
                    4'hC: begin // NEW: RJMP (Relative Jump for loops)
                        pc <= instruction[11:0]; 
                    end
                    
                    default: ; // NOP
                endcase
            end
        end
    end

endmodule
