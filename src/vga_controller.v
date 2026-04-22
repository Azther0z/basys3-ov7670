`timescale 1ns / 1ps

module vga_controller (
    input  wire        clk_25MHz, // 25 MHz pixel clock
    input  wire        rst,
    
    // VGA output physical pins
    output reg         hsync,
    output reg         vsync,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    
    // Memory interface to BRAM Video Buffer
    output wire [16:0] frame_addr,
    input  wire [11:0] frame_pixel
);

    // 640x480 @ 60Hz Industry Standard Timings
    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;
    localparam V_TOTAL  = 525;

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // Address calculated combinationally from current XY coordinate
    // The BRAM has 320x240 pixels. We divide H and V by 2 using [9:1].
    wire [8:0] px = h_cnt[9:1];
    wire [8:0] py = v_cnt[9:1];
    
    // Compute BRAM address (py * 320 + px).
    // Ensure we don't access outside bounds (e.g. if we somehow misalign).
    assign frame_addr = (py < 240 && px < 320) ? ((py * 320) + px) : 17'd0;

    // Track active display region
    wire active = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    reg  active_d; // 1 clock cycle delay to exactly match the dual-port BRAM read latency

    always @(posedge clk_25MHz) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
            active_d <= 0;
        end else begin
            // Increment counters
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) begin
                    v_cnt <= 0;
                end else begin
                    v_cnt <= v_cnt + 1;
                end
            end else begin
                h_cnt <= h_cnt + 1;
            end
            
            // Delay the 'active' evaluation by 1 cycle to align with memory read arrival
            active_d <= active;
        end
    end

    // HSYNC and VSYNC Generation (Active Low for 640x480 standard)
    always @(posedge clk_25MHz) begin
        hsync <= ~((h_cnt >= (H_ACTIVE + H_FP)) && (h_cnt < (H_ACTIVE + H_FP + H_SYNC)));
        vsync <= ~((v_cnt >= (V_ACTIVE + V_FP)) && (v_cnt < (V_ACTIVE + V_FP + V_SYNC)));
        
        // Output pins registration (adds another +1 latency, matching the hsync delay intuitively)
        if (active_d) begin
            vga_r <= frame_pixel[11:8];
            vga_g <= frame_pixel[7:4];
            vga_b <= frame_pixel[3:0];
        end else begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end

endmodule
