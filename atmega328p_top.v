module atmega328p_top (
    input wire clk,
    input wire reset,
    
    // Physical External Pins
    output wire [7:0] portb_pins,
    output wire uart_tx_pin
);

    // --- INTERNAL SILICON BUSES (The "Wires" between modules) ---
    
    // Instruction Bus (Connects CPU to ROM)
    wire [15:0] core_pc;
    wire [15:0] core_instruction;
    
    // Data Bus (Connects CPU to RAM and Peripherals)
    wire [7:0]  core_data_out;
    wire [7:0]  core_data_in;
    wire [7:0]  core_addr_bus;
    wire        core_write_enable;
    
    // Peripheral Interrupt Lines
    wire        timer_interrupt;

    // --- MODULE 1: THE CPU CORE ---
    // Handles fetching, decoding, ALU math, and branching
    avr_cpu_core u_cpu (
        .clk(clk),
        .reset(reset),
        .pc(core_pc),
        .instruction(core_instruction),
        .mem_addr(core_addr_bus),
        .mem_wdata(core_data_out),
        .mem_rdata(core_data_in),
        .mem_we(core_write_enable),
        .irq_timer(timer_interrupt)
    );

    // --- MODULE 2: PROGRAM ROM ---
    // Holds the compiled hex code
    prog_rom u_rom (
        .pc_addr(core_pc),
        .instruction_out(core_instruction)
    );

    // --- MODULE 3: DATA SRAM ---
    // 2KBs of working memory
    data_sram u_sram (
        .clk(clk),
        .addr(core_addr_bus),
        .wdata(core_data_out),
        .we(core_write_enable),
        .rdata(core_data_in)
    );

    // --- MODULE 4: HARDWARE TIMER PERIPHERAL ---
    // Independent counter generating background interrupts
    timer_counter0 u_timer0 (
        .clk(clk),
        .reset(reset),
        .interrupt_flag(timer_interrupt)
    );

    // --- MODULE 5: GPIO PORT B ---
    // Maps memory writes to physical external pins
    gpio_port u_portb (
        .clk(clk),
        .reset(reset),
        .bus_addr(core_addr_bus),
        .bus_wdata(core_data_out),
        .bus_we(core_write_enable),
        .pin_state(portb_pins)
    );

endmodule

