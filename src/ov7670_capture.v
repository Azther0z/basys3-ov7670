`timescale 1ns / 1ps

module ov7670_capture(
    input  wire        pclk,
    input  wire        vsync,
    input  wire        href,
    input  wire  [7:0] d,
    output wire [16:0] addr, 
    output reg  [11:0] dout, 
    output reg         we
);

    reg [16:0] address;
    reg [1:0]  state;      // 0 = byte 1, 1 = byte 2
    reg        pixel_dwn;  // 0 = keep, 1 = drop
    reg        row_dwn;    // 0 = keep, 1 = drop
    reg [7:0]  d_latch;
    reg        prev_href;
    
    assign addr = address;

    always @(posedge pclk) begin
        if (vsync == 1'b1) begin
            address   <= {17{1'b0}};
            state     <= 0;
            we        <= 0;
            pixel_dwn <= 0;
            row_dwn   <= 0;
            prev_href <= 0;
        end else begin
            if (we) begin
                address <= address + 1;
            end
            
            we <= 0; 
            
            // Detect falling edge of href to increment row dropper
            prev_href <= href;
            if (prev_href == 1'b1 && href == 1'b0) begin
                row_dwn <= ~row_dwn; 
            end
            
            if (href == 1'b1) begin
                if (state == 0) begin
                    d_latch <= d; // Camera is outputting LOW BYTE first: GGGBBBBB
                    state   <= 1;
                end else begin
                    // Camera is outputting HIGH BYTE second: RRRRRGGG (this is in 'd')
                    // Target RGB444 for Basys3:
                    // RED (4 bits):   d[7:4]
                    // GREEN (4 bits): {d[2:0], d_latch[7]}
                    // BLUE (4 bits):  d_latch[4:1]
                    dout  <= {d[7:4], d[2:0], d_latch[7], d_latch[4:1]};
                    
                    // Only write to memory if we keep this row AND pixel
                    if (row_dwn == 0 && pixel_dwn == 0) begin
                        we <= 1'b1;
                    end
                    
                    pixel_dwn <= ~pixel_dwn; // Toggle keep/drop vertically
                    state <= 0;
                end
            end else begin
                state <= 0; 
                pixel_dwn <= 0; // Reset pixel dropper at start of each row
            end
        end
    end

endmodule
