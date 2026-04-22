`timescale 1ns / 1ps

module frame_buffer(
    input  wire        clka,
    input  wire        wea,
    input  wire [16:0] addra,
    input  wire [11:0] dina,
    
    input  wire        clkb,
    input  wire [16:0] addrb,
    output reg  [11:0] doutb
);

    // Frame resolution: 320 x 240 = 76800 pixels.
    // Each pixel is 12 bits (RGB444).
    // Total memory: ~921 Kbits, which comfortably fits in the Basys 3's 1800 Kbits BRAM.
    (* ram_style = "block" *) reg [11:0] ram [0:76799];

    // Port A: written synchronously with the camera pixel clock
    always @(posedge clka) begin
        if (wea) begin
            if (addra < 76800) begin
                ram[addra] <= dina;
            end
        end
    end

    // Port B: read synchronously with the VGA clock
    always @(posedge clkb) begin
        if (addrb < 76800) begin
            doutb <= ram[addrb];
        end else begin
            doutb <= 12'h000;
        end
    end

endmodule
