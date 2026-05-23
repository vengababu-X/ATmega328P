// micro_avr_cpu.v
module micro_avr_cpu (
    input clk,
    input reset,
    output reg gpio_we,
    output reg [7:0] gpio_wdata
);
    // Program Counter & Instruction Memory (Simulating Flash)
    reg [15:0] pc;
    reg [15:0] flash [0:15];
    wire [15:0] instruction;
    
    // Register File: 32 x 8-bit registers
    reg [7:0] registers [0:31];

    assign instruction = flash[pc];

    // Instruction Decoding
    wire [3:0] opcode = instruction[15:12];
    
    // Hardcoded program (Arduino "Blink" equivalent)
    initial begin
        // LDI R16, 0x01 (Load immediate 1 into R16) -> Opcode 1110
        flash[0] = 16'b1110_0000_0001_0000; 
        
        // OUT PORTB, R16 (Turn on LED) -> Opcode 1011
        flash[1] = 16'b1011_0000_0001_0000; 
        
        // INC R16 (Increment R16 to change the pin state next loop) -> Opcode 1001
        flash[2] = 16'b1001_0100_0001_0011; 
        
        // OUT PORTB, R16 (Update LED) -> Opcode 1011
        flash[3] = 16'b1011_0000_0001_0000; 
        
        // RJMP -2 (Jump back to step 2 to create an infinite loop) -> Opcode 1100
        flash[4] = 16'b1100_1111_1111_1110; 
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            gpio_we <= 0;
            gpio_wdata <= 0;
        end else begin
            gpio_we <= 0; // Default state
            
            case (opcode)
                4'b1110: begin // LDI (Load Immediate)
                    registers[16] <= 8'h01; // Simplified: Hardcoded to load 1 into R16
                    pc <= pc + 1;
                end
                4'b1011: begin // OUT (Write to GPIO)
                    gpio_wdata <= registers[16];
                    gpio_we <= 1;
                    pc <= pc + 1;
                end
                4'b1001: begin // INC (Increment Register)
                    registers[16] <= registers[16] + 1;
                    pc <= pc + 1;
                end
                4'b1100: begin // RJMP (Relative Jump)
                    pc <= pc - 2; // Loop back
                end
                default: pc <= pc + 1;
            endcase
        end
    end
endmodule
