// micro_avr_cpu.v
module micro_avr_cpu (
    input clk,
    input reset,
    output reg gpio_we,
    output reg [7:0] gpio_wdata,
    output reg uart_we,
    output reg [7:0] uart_wdata,
    input [7:0] timer_val
);
    reg [15:0] pc;
    reg [15:0] flash [0:31];
    reg [7:0] registers [0:31];
    reg [7:0] sreg; // Status Register (Bit 1 = Zero Flag)

    wire [15:0] instruction = flash[pc];
    wire [3:0] opcode = instruction[15:12];

    initial begin
        // Program: Send character 'A' (0x41) over UART, then blink LED.
        // LDI R16, 0x41 -> Load 'A' into R16
        flash[0] = 16'b1110_0100_0000_0001; 
        
        // OUT UDR0 (0xC6), R16 -> Send to UART
        flash[1] = 16'b1011_1100_0000_0110; 
        
        // LDI R17, 0x01 -> Load 1 into R17
        flash[2] = 16'b1110_0000_0001_0001; 

        // ADD R16, R17 -> R16 = R16 + 1 (Changes 'A' to 'B' for next loop)
        flash[3] = 16'b0000_1111_0000_0001;
        
        // OUT PORTB (0x25), R16 -> Output to physical pins
        flash[4] = 16'b1011_0010_0000_0101; 
        
        // RJMP -4 -> Loop back to instruction 1
        flash[5] = 16'b1100_1111_1111_1100; 
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0; gpio_we <= 0; uart_we <= 0; sreg <= 0;
        end else begin
            gpio_we <= 0; uart_we <= 0; // Reset write strobes
            
            case (opcode)
                4'b1110: begin // LDI: Load Immediate (simplified for R16/R17)
                    if (instruction[0]) registers[17] <= instruction[11:8] | (instruction[7:4] << 4);
                    else registers[16] <= instruction[11:8] | (instruction[7:4] << 4);
                    pc <= pc + 1;
                end
                4'b0000: begin // ADD: R16 = R16 + R17
                    registers[16] <= registers[16] + registers[17];
                    if ((registers[16] + registers[17]) == 0) sreg[1] <= 1; // Set Zero Flag
                    else sreg[1] <= 0;
                    pc <= pc + 1;
                end
                4'b1011: begin // OUT: Memory Mapped I/O
                    // Extract I/O Address (simplified decoding)
                    if (instruction[3:0] == 4'b0110) begin // 0xC6 = UDR0 (UART)
                        uart_wdata <= registers[16];
                        uart_we <= 1;
                    end else if (instruction[3:0] == 4'b0101) begin // 0x25 = PORTB (GPIO)
                        gpio_wdata <= registers[16];
                        gpio_we <= 1;
                    end
                    pc <= pc + 1;
                end
                4'b1100: begin // RJMP
                    pc <= pc - 4; // Hardcoded loop back for this specific program
                end
                default: pc <= pc + 1;
            endcase
        end
    end
endmodule
