`timescale 1ns / 1ps

module testbench;

    // Inputs
    reg clk;
    reg reset;

    // Outputs from the Top Module
    wire [7:0] portb_pins;
    wire uart_tx_pin;

    // Instantiate the Top-Level Wrapper
    atmega328p_top uut (
        .clk(clk),
        .reset(reset),
        .portb_pins(portb_pins),
        .uart_tx_pin(uart_tx_pin)
    );

    // Clock Generation (50MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Simulation Sequence
    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, testbench);

        // 1. Initialize System
        reset = 1;
        
        // 2. Release Reset
        #20 reset = 0;

        // 3. Let the CPU run for a while to trigger loops and interrupts
        #5000; 
        
        // 4. End Simulation
        $display("Simulation Complete.");
        $finish;
    end

endmodule
