module avr_cpu_core (
    input wire clk,
    input wire reset,
    
    // Instruction Bus (ROM)
    output reg [15:0] pc,
    input wire [15:0] instruction,
    
    // Data Bus (SRAM & Peripherals)
    output reg [7:0] mem_addr,
    output reg [7:0] mem_wdata,
    input wire [7:0] mem_rdata,
    output reg mem_we,
    
    // Interrupt Lines
    input wire irq_timer
);

    reg [7:0] registers [0:31];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pc <= 16'b0;
            mem_we <= 1'b0;
            mem_addr <= 8'b0;
            mem_wdata <= 8'b0;
            for (i = 0; i < 32; i = i + 1) registers[i] <= 8'b0;
        end else begin
            // Default: turn off write-enable every cycle
            mem_we <= 1'b0;
            
            // Interrupt Hijack
            if (irq_timer == 1'b1) begin
                pc <= 16'h0001; // Jump to ISR vector
            end else begin
                // Normal Execution
                case (instruction[15:12])
                    4'h1: begin // LDI
                        registers[16 + instruction[11:8]] <= instruction[7:0];
                        pc <= pc + 16'd1;
                    end
                    
                    4'h2: begin // OUT to GPIO (Mapped to Mem Addr 0x25)
                        mem_addr <= 8'h25; 
                        mem_wdata <= registers[16 + instruction[11:8]];
                        mem_we <= 1'b1;
                        pc <= pc + 16'd1;
                    end
                    
                    4'h3: begin // OUT to UART (Mapped to Mem Addr 0x26)
                        mem_addr <= 8'h26;
                        mem_wdata <= instruction[7:0];
                        mem_we <= 1'b1;
                        pc <= pc + 16'd1;
                    end
                    
                    4'hB: begin // RETI (Return from Interrupt)
                        pc <= 16'h0003; // Hardcoded return to Main for simplicity
                    end
                    
                    4'hC: begin // RJMP (Relative Jump)
                        pc <= {4'b0, instruction[11:0]};
                    end
                    
                    default: pc <= pc + 16'd1; // NOP
                endcase
            end
        end
    end

endmodule

