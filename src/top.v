`timescale 1ns / 1ps

module top(
    input  wire       clk,      // 100 MHz Basys3 Clock
    input  wire       btnC,     // Center button used as async reset
    
    // OV7670 Physical Pins
    input  wire [7:0] ov7670_d,
    input  wire       ov7670_pclk,
    input  wire       ov7670_vsync,
    input  wire       ov7670_href,
    output wire       ov7670_xclk,
    output wire       ov7670_sioc,
    inout  wire       ov7670_siod,
    output wire       ov7670_pwdn,
    output wire       ov7670_reset,

    // VGA Output Physical Pins
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);

    // 1. Clock Generation (100 MHz -> 25 MHz)
    // Simple 2-bit counter down-scaler
    reg [1:0] clk_div;
    always @(posedge clk) begin
        if (btnC) clk_div <= 0;
        else      clk_div <= clk_div + 1;
    end
    wire clk_25 = clk_div[1];
    
    // Provide 25MHz clock to the camera
    assign ov7670_xclk = clk_25;
    
    // Hardwire constant camera pins
    assign ov7670_pwdn = 0;   // Normal operation (active high powerdown)
    assign ov7670_reset = 1;  // Normal operation (active low reset)

    // 2. Camera SCCB Configuration Phase
    wire       sccb_ready;
    wire       sccb_start;
    wire [7:0] reg_addr;
    wire [7:0] reg_data;
    wire       config_done;

    ov7670_registers camera_regs (
        .clk(clk),            // Run at 100MHz to align with master
        .rst(btnC),
        .sccb_ready(sccb_ready),
        .sccb_start(sccb_start),
        .reg_addr(reg_addr),
        .reg_data(reg_data),
        .done(config_done)
    );

    sccb_master sccb_ctrl (
        .clk(clk),            // Contains DIVIDER = 250 for 100MHz input
        .rst(btnC),
        .start(sccb_start),
        .reg_addr(reg_addr),
        .reg_data(reg_data),
        .ready(sccb_ready),
        .sccb_c(ov7670_sioc),
        .sccb_d(ov7670_siod)
    );

    // 3. Pixel Capture into Frame Buffer
    wire [16:0] write_addr;
    wire [11:0] write_data;
    wire        write_en;

    ov7670_capture capture_inst (
        .pclk(ov7670_pclk),
        .vsync(ov7670_vsync),
        .href(ov7670_href),
        .d(ov7670_d),
        .addr(write_addr),
        .dout(write_data),
        .we(write_en)
    );

    // 4. Dual-Port BRAM Frame Buffer
    wire [16:0] read_addr;
    wire [11:0] read_data;

    frame_buffer bram_inst (
        .clka(ov7670_pclk), // Memory writes synchronous to camera pixel clock
        .wea(write_en),
        .addra(write_addr),
        .dina(write_data),

        .clkb(clk_25),      // Memory reads synchronous to VGA logic clock
        .addrb(read_addr),
        .doutb(read_data)
    );

    // 5. VGA Controller
    vga_controller vga_inst (
        .clk_25MHz(clk_25),
        .rst(btnC),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .frame_addr(read_addr),
        .frame_pixel(read_data)
    );

endmodule
