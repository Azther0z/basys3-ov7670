module topModule (
    // Basys 3 input/output
    input wire       clk,    // Basys 3 clock, 100 MHz
    input wire       reset,  // BTNC, active-high
    input wire [4:0] switch,

    // Camera config
    output wire sioC,  // SCCB clock
    inout  wire sioD,  // SCCB data

    // Camera capture
    input  wire [7:0] cameraData,   // D7..D0 pixel data
    output wire       xClk,         // Master clock to camera
    output wire       cameraPwdn,   // Power-down (drive LOW)
    output wire       cameraReset,  // Reset (drive HIGH to operate)
    input  wire       pClk,         // Pixel clock from camera
    input  wire       cameraHs,     // Horizontal reference
    input  wire       cameraVs,     // Vertical sync (active-high)

    // VGA
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire       vgaHs,
    output wire       vgaVs
);

  wire vgaClk;
  wire xClkOut;
  wire locked;

  ODDR #(
      .DDR_CLK_EDGE("OPPOSITE_EDGE"),
      .INIT        (1'b0),
      .SRTYPE      ("SYNC")
  ) oddrXclk (
      .Q (xClk),
      .C (xClkOut),
      .CE(1'b1),
      .D1(1'b1),
      .D2(1'b0),
      .R (1'b0),
      .S (1'b0)
  );

  clk_wiz clkWiz (
      .clk_in1 (clk),
      .clk_out1(vgaClk),   // 25 MHz
      .clk_out2(xClkOut),  // 24 MHz (Preferred for OV7670)
      .reset   (reset),
      .locked  (locked)
  );

  assign cameraPwdn  = 1'b0;
  assign cameraReset = 1'b1;

  // Power-on Reset Counter
  // Ensures all modules start in a known state after clocks are stable.
  reg [23:0] resetCounter = 24'd0;
  reg        globalReset = 1'b1;
  always @(posedge clk) begin
    if (reset || !locked) begin
      resetCounter <= 24'd0;
      globalReset  <= 1'b1;
    end else if (resetCounter < 24'hFFFFFF) begin
      resetCounter <= resetCounter + 24'd1;
      globalReset  <= 1'b1;
    end else begin
      globalReset <= 1'b0;
    end
  end

  // Synchronize globalReset to each domain
  reg vgaResetSync, vgaResetReg;
  always @(posedge vgaClk) begin
    vgaResetSync <= globalReset;
    vgaResetReg  <= vgaResetSync;
  end

  reg cameraResetSync, cameraResetReg;
  always @(posedge pClk) begin
    cameraResetSync <= globalReset;
    cameraResetReg  <= cameraResetSync;
  end

  wire sioDOut;
  assign sioD = sioDOut ? 1'bz : 1'b0;

  cameraConfig cameraConfigModule (
      .clk  (clk),
      .reset(globalReset),
      .sioC (sioC),
      .sioD (sioDOut)
  );

  // Frame Buffer
  wire        writeEnable;
  wire [16:0] writeAddress;
  wire [11:0] writeData;
  wire [16:0] readAddress;
  wire [11:0] readData;

  blk_mem_gen frameBuffer (
      .clka (pClk),
      .wea  (writeEnable),
      .addra(writeAddress),
      .dina (writeData),
      .douta(),
      .clkb (vgaClk),
      .web  (1'b0),
      .addrb(readAddress),
      .dinb (12'd0),
      .doutb(readData)
  );

  // Camera Capture
  wire frameDone;

  cameraCapture cameraCaptureModule (
      .pClk        (pClk),
      .reset       (cameraResetReg),
      .cameraVs    (cameraVs),
      .cameraHs    (cameraHs),
      .cameraData  (cameraData),
      .writeEnable (writeEnable),
      .writeAddress(writeAddress),
      .writeData   (writeData),
      .frameDone   (frameDone)
  );

  // Frame-done CDC: Synchronize frameDone pulse from pClk to vgaClk
  wire frameDoneVga;
  pulseSync frameDoneSyncModule (
      .srcClk   (pClk),
      .srcReset (cameraResetReg),
      .srcPulse (frameDone),
      .destClk  (vgaClk),
      .destReset(vgaResetReg),
      .destPulse(frameDoneVga)
  );

  reg frameValid = 1'b0;
  always @(posedge vgaClk) begin
    if (vgaResetReg) frameValid <= 1'b0;
    else if (frameDoneVga) frameValid <= 1'b1;
  end

  // VGA Controller
  vgaController vgaControllerModule (
      .clk        (vgaClk),
      .reset      (vgaResetReg),
      .readData   (readData),
      .switch     (switch),
      .frameValid (frameValid),
      .readAddress(readAddress),
      .vgaRed     (vgaRed),
      .vgaGreen   (vgaGreen),
      .vgaBlue    (vgaBlue),
      .vgaHs      (vgaHs),
      .vgaVs      (vgaVs)
  );

endmodule
