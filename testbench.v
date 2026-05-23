`timescale 1ns / 1ps

module testbench;
    reg clk;
    reg reset;
    wire [7:0] portb_pins;
    wire uart_tx_pin;

    // Instantiate Top-Level
    atmega328p_top uut (
        .clk(clk),
        .reset(reset),
        .portb_pins(portb_pins),
        .uart_tx_pin(uart_tx_pin)
    );

    // 50MHz Clock
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // The Real-Time Visualizer
    always @(portb_pins) begin
        if (!reset) begin
            $display("⏱️ Time: %0t ns | 🖥️ PC: %02h | 💡 LEDs: [%c %c %c %c %c %c %c %c]", 
                $time, 
                uut.core_pc,
                portb_pins[7] ? "O" : ".",
                portb_pins[6] ? "O" : ".",
                portb_pins[5] ? "O" : ".",
                portb_pins[4] ? "O" : ".",
                portb_pins[3] ? "O" : ".",
                portb_pins[2] ? "O" : ".",
                portb_pins[1] ? "O" : ".",
                portb_pins[0] ? "O" : "."
            );
        end
    end

    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, testbench);

        $display("========================================");
        $display("🚀 BOOTING ATMEGA328P CUSTOM CORE v0.5");
        $display("========================================");

        reset = 1;
        #20 reset = 0;

        // Run long enough to see the LED animation loop
        #1500; 

        $display("========================================");
        $display("🛑 SIMULATION HALTED.");
        $display("========================================");
        $finish;
    end
endmodule
