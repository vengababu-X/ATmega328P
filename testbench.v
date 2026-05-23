// testbench.v
`timescale 1ns/1ns

module testbench;
    reg clk;
    reg reset;

    wire gpio_we;
    wire [7:0] gpio_wdata;
    wire [7:0] physical_pins;

    // Instantiate CPU Core
    micro_avr_cpu cpu (
        .clk(clk),
        .reset(reset),
        .gpio_we(gpio_we),
        .gpio_wdata(gpio_wdata)
    );

    // Instantiate physical DIP Pins
    gpio_port portB (
        .clk(clk),
        .reset(reset),
        .we(gpio_we),
        .wdata(gpio_wdata),
        .pins(physical_pins)
    );

    // 10ns Clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("arduino_chip.vcd");
        $dumpvars(0, testbench);

        clk = 0;
        reset = 1;

        // Release reset
        #10 reset = 0;

        // Run for 100ns to let the loop execute a few times
        #100;
        
        $display("\n--- PHYSICAL DIP CHIP SIMULATION ---");
        $finish;
    end

    // Monitor the physical pins in real-time
    always @(physical_pins) begin
        $display("Time: %0t | PORTB Physical Pins output: %b", $time, physical_pins);
    end
endmodule

