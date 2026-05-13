module cameraCapture #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 240
) (
    input wire       pClk,       // Camera PCLK
    input wire       reset,
    input wire       cameraVs,
    input wire       cameraHs,
    input wire [7:0] cameraData,

    output reg        writeEnable,
    output reg [16:0] writeAddress,
    output reg [11:0] writeData,
    output reg        frameDone
);

  reg [7:0] firstByte;
  reg       byteCount;
  reg       vsyncPrev;
  reg       hrefPrev;
  reg [9:0] hCounter;
  reg [9:0] vCounter;

  always @(negedge pClk) begin
    if (reset) begin
      writeAddress <= 17'd0;
      byteCount    <= 1'b0;
      writeEnable  <= 1'b0;
      frameDone    <= 1'b0;
      hCounter     <= 10'd0;
      vCounter     <= 10'd0;
      hrefPrev     <= 1'b0;
      vsyncPrev    <= 1'b0;
    end else begin
      writeEnable <= 1'b0;
      frameDone   <= 1'b0;
      vsyncPrev   <= cameraVs;
      hrefPrev    <= cameraHs;

      // Frame Reset on VSYNC (Active High)
      if (cameraVs) begin
        writeAddress <= 17'd0;
        byteCount    <= 1'b0;
        hCounter     <= 10'd0;
        vCounter     <= 10'd0;
      end else begin
        // Pulse frame_done at the end of VSYNC
        if (vsyncPrev) begin
          frameDone <= 1'b1;
        end

        // Increment Vertical Counter on falling edge of HREF
        if (!cameraHs && hrefPrev) begin
          vCounter <= vCounter + 10'd1;
        end

        // Pixel Capture on HREF
        if (cameraHs) begin
          if (!byteCount) begin
            firstByte <= cameraData;
            byteCount <= 1'b1;
          end else begin
            // Pixel Capture logic: Downscale 640x480 to 320x240
            if (hCounter < 10'd640 && vCounter < 10'd480) begin
              // Drop odd pixels and lines
              if (hCounter[0] == 1'b0 && vCounter[0] == 1'b0) begin
                writeData <= {firstByte[3:0], cameraData};
                writeEnable <= 1'b1;
                writeAddress <= (vCounter[9:1] * FRAME_WIDTH) + hCounter[9:1];
              end
            end
            hCounter  <= hCounter + 10'd1;
            byteCount <= 1'b0;
          end
        end else begin
          byteCount <= 1'b0;  // Reset byte count between lines
          hCounter  <= 10'd0;  // Reset horizontal count at end of line
        end
      end
    end
  end

endmodule
