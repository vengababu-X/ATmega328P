module avr_cpu_core (
    input wire clk,
    input wire reset,
    output reg [15:0] pc,
    input wire [15:0] instruction,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_wdata,
    input wire [7:0] mem_rdata,
    output reg mem_we,
    input wire irq_timer
);

    reg [7:0] registers [0:31];
    reg sreg_z; // Zero Flag for conditional branching
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            pc <= 16'b0;
            mem_we <= 1'b0;
            sreg_z <= 1'b0;
            for (i = 0; i < 32; i = i + 1) registers[i] <= 8'b0;
        end else begin
            mem_we <= 1'b0;
            
            if (irq_timer == 1'b1) begin
                pc <= 16'h0001; 
            end else begin
                case (instruction[15:12])
                    4'h1: begin // LDI (Load Immediate)
                        registers[16 + instruction[11:8]] <= instruction[7:0];
                        pc <= pc + 16'd1;
                    end
                    
                    4'h2: begin // OUT to GPIO (Mem 0x25)
                        mem_addr <= 8'h25; 
                        mem_wdata <= registers[16 + instruction[11:8]];
                        mem_we <= 1'b1;
                        pc <= pc + 16'd1;
                    end
                    
                    4'h4: begin // NEW: LSL (Logical Shift Left)
                        registers[16 + instruction[11:8]] <= registers[16 + instruction[11:8]] << 1;
                        pc <= pc + 16'd1;
                    end

                    4'h9: begin // NEW: CPI (Compare Immediate)
                        if (registers[16 + instruction[11:8]] == instruction[7:0])
                            sreg_z <= 1'b1; // Set Zero Flag if match
                        else
                            sreg_z <= 1'b0;
                        pc <= pc + 16'd1;
                    end

                    4'hA: begin // NEW: BRNE (Branch if Not Equal / Zero flag is 0)
                        if (sreg_z == 1'b0) 
                            pc <= pc + 16'd1 + instruction[7:0]; // Jump backwards/forwards
                        else 
                            pc <= pc + 16'd1; // Do not jump, continue normally
                    end
                    
                    4'hC: pc <= {4'b0, instruction[11:0]}; // RJMP
                    
                    default: pc <= pc + 16'd1; // NOP
                endcase
            end
        end
    end
endmodule
