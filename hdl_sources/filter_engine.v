// =============================================================================
// Module      : filter_engine
// Purpose     : Combinational logic to apply various image filters to a
//               16-bit RGB444 pixel based on switch inputs.
//
// Filters:
//   sw = 00 -> Pass-through (Raw)
//   sw = 01 -> Grayscale (Rec.601 luminance)
//   sw = 10 -> Color Isolation (Red channel only)
//   sw = 11 -> Color Inversion (Negative)
//
// Ports:
//   pixel_in  [11:0] — 12-bit RGB444 input pixel (format: RRRR GGGG BBBB)
//   sw        [1:0]  — 2-bit filter selection
//   pixel_out [11:0] — 12-bit RGB444 filtered output pixel
// =============================================================================

module filter_engine (
    input  wire [11:0] pixel_in,
    input  wire [1:0]  sw,
    output reg  [11:0] pixel_out
);

    // Extract RGB444 components
    // R: [11:8] (4 bits), G: [7:4] (4 bits), B: [3:0] (4 bits)
    wire [3:0] r4 = pixel_in[11:8];
    wire [3:0] g4 = pixel_in[7:4];
    wire [3:0] b4 = pixel_in[3:0];

    // -----------------------------------------------------------------------
    // Grayscale Conversion (Rec.601)
    // Formula: Y = (R4*54 + G4*183 + B4*18) >> 8
    // Note: R4, G4, B4 are 4 bits.
    // -----------------------------------------------------------------------
    wire [11:0] y_scaled = (r4 * 12'd54) + (g4 * 12'd183) + (b4 * 12'd18);
    wire [3:0]  y_4bit = y_scaled[11:8];
    
    // -----------------------------------------------------------------------
    // Filter selection
    // -----------------------------------------------------------------------
    always @(*) begin
        case (sw)
            2'b00: begin // Raw
                pixel_out = pixel_in;
            end
            2'b01: begin // Grayscale
                pixel_out = {y_4bit, y_4bit, y_4bit};
            end
            2'b10: begin // Color Isolation (Red)
                pixel_out = {r4, 8'b0};
            end
            2'b11: begin // Color Inversion
                pixel_out = ~pixel_in;
            end
            default: pixel_out = pixel_in;
        endcase
    end

endmodule
