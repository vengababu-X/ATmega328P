module prog_rom (
    input wire [15:0] pc_addr,
    output reg [15:0] instruction_out
);
    reg [15:0] memory [0:127];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1) memory[i] = 16'b0000;
        
        memory[0] = 16'hC003; // RJMP to Main (PC=3)
        memory[1] = 16'h0000; // Unused ISR
        memory[2] = 16'h0000; 
        
        // --- LED CHASER PROGRAM ---
        // PC=3: Setup
        memory[3] = 16'h1001; // LDI R16, 0x01 (Load starting bit: 00000001)
        
        // PC=4: Loop Start
        memory[4] = 16'h2000; // OUT GPIO, R16 (Display it on the simulated LEDs)
        memory[5] = 16'h4000; // LSL R16 (Shift the bit left: 00000010)
        memory[6] = 16'h9000; // CPI R16, 0x00 (Did we shift the bit completely off the edge?)
        
        // PC=7: Conditional Branch
        // If R16 is not 0 (Zero flag = 0), jump backward 3 steps (-3 = 0xFD in 8-bit two's complement)
        memory[7] = 16'hA0FD; // BRNE -3 (Jumps back to PC=4)
        
        // PC=8: Reset Logic
        // If we didn't branch, it means the bit fell off. Reset it and start over.
        memory[8] = 16'h1001; // LDI R16, 0x01 
        memory[9] = 16'hC004; // RJMP to PC=4 
    end

    always @(*) begin
        instruction_out = memory[pc_addr[6:0]]; 
    end
endmodule
