// testbench.v
`timescale 1ns/1ns

module testbench;
    reg clk, reset;
    
    // Buses
    wire gpio_we, uart_we;
    wire [7:0] gpio_wdata, uart_wdata;
    wire [7:0] physical_pins, timer_val;
    wire tx_pin, tx_ready;

    // CPU Core
    micro_avr_cpu cpu (.clk(clk), .reset(reset), .gpio_we(gpio_we), .gpio_wdata(gpio_wdata), 
                       .uart_we(uart_we), .uart_wdata(uart_wdata), .timer_val(timer_val));

    // Peripherals
    gpio_port portB (.clk(clk), .reset(reset), .we(gpio_we), .wdata(gpio_wdata), .pins(physical_pins));
    timer timer0 (.clk(clk), .reset(reset), .tcnt0(timer_val));
    uart_tx serial0 (.clk(clk), .reset(reset), .tx_start(uart_we), .tx_data(uart_wdata), 
                     .tx_pin(tx_pin), .tx_ready(tx_ready));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("arduino_soc.vcd");
        $dumpvars(0, testbench);
        clk = 0; reset = 1;
        
        #10 reset = 0;
        #300; // Let it run longer to see the UART shift out data
        $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (uart_we) $display("Time: %0t | CPU requested UART TX. Data: '%c' (0x%h)", $time, uart_wdata, uart_wdata);
        if (gpio_we) $display("Time: %0t | CPU updated PORTB pins: %b", $time, gpio_wdata);
    end
endmodule
