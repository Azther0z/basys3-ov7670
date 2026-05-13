module filter (
    input  wire [11:0] rawData,
    input  wire [ 4:0] switch,
    output reg  [11:0] filteredData
);

  // Extract RGB444 components
  wire [ 3:0] red = rawData[11:8];
  wire [ 3:0] green = rawData[7:4];
  wire [ 3:0] blue = rawData[3:0];

  // Grayscale Conversion (Rec.601)
  // Formula: Y = (R4*54 + G4*183 + B4*18) >> 8
  wire [11:0] yScaled = (red * 12'd54) + (green * 12'd183) + (blue * 12'd18);
  wire [ 3:0] y4Bit = yScaled[11:8];

  // Filter selection logic:
  // 1XXXX: Color Inverse
  // XXXX1: Grayscale (if not Inverse)
  // XABCX: Color Isolation (A=Red, B=Green, C=Blue)
  // 00000: Raw
  always @(*) begin
    if (switch[4]) begin
      filteredData = ~rawData;
    end else if (switch[0]) begin
      filteredData = {y4Bit, y4Bit, y4Bit};
    end else if (switch == 5'b00000) begin
      filteredData = rawData;
    end else begin
      // Color isolation combination (Bits 3, 2, 1)
      filteredData[11:8] = (switch[3]) ? red : 4'd0;
      filteredData[7:4]  = (switch[2]) ? green : 4'd0;
      filteredData[3:0]  = (switch[1]) ? blue : 4'd0;
    end
  end

endmodule
