module prog_rom (
    input wire [15:0] pc_addr,
    output reg [15:0] instruction_out
);
    // 128 slots for 16-bit instructions
    reg [15:0] memory [0:127];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1) memory[i] = 16'b0000000000000000;
        
        // --- MODULAR TEST PROGRAM ---
        memory[0] = 16'hC003; // RJMP to Main (PC=3)
        memory[1] = 16'hC007; // RJMP to ISR (PC=7)
        memory[2] = 16'h0000; // NOP
        
        // MAIN (PC=3)
        memory[3] = 16'h100A; // LDI R16, 0x0A
        memory[4] = 16'h2000; // OUT GPIO, R16 
        memory[5] = 16'hC004; // RJMP back to PC=4 (Infinite Loop)
        memory[6] = 16'h0000; // NOP
        
        // ISR (PC=7) - Triggered by Timer
        memory[7] = 16'h3049; // OUT UART, 'I'
        memory[8] = 16'hB000; // RETI (Return from Interrupt)
    end

    // Combinational read: instantly outputs instruction based on PC
    always @(*) begin
        instruction_out = memory[pc_addr[6:0]]; 
    end
endmodule
