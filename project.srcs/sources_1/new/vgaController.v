module vgaController (
    input  wire        clk,          // 25 MHz pixel clock
    input  wire        reset,        // synchronous active-high reset
    input  wire [11:0] readData,     // Raw pixel data from BRAM
    input  wire [ 4:0] switch,       // Filter control switches
    input  wire        frameValid,   // Signal from top indicating frame is ready
    output wire [16:0] readAddress,
    output wire [ 3:0] vgaRed,
    output wire [ 3:0] vgaGreen,
    output wire [ 3:0] vgaBlue,
    output wire        vgaHs,
    output wire        vgaVs
);

  localparam H_DISPLAY = 640;
  localparam H_FRONTPORCH = 16;
  localparam H_PULSEWIDTH = 96;
  localparam H_BACKPORCH = 48;
  localparam H_TOTAL = H_DISPLAY + H_FRONTPORCH + H_PULSEWIDTH + H_BACKPORCH;

  localparam V_DISPLAY = 480;
  localparam V_FRONTPORCH = 10;
  localparam V_PULSEWIDTH = 2;
  localparam V_BACKPORCH = 29;
  localparam V_TOTAL = V_DISPLAY + V_FRONTPORCH + V_PULSEWIDTH + V_BACKPORCH;

  localparam H_SYNC_START = H_DISPLAY + H_FRONTPORCH;
  localparam H_SYNC_END = H_DISPLAY + H_FRONTPORCH + H_PULSEWIDTH;
  localparam V_SYNC_START = V_DISPLAY + V_FRONTPORCH;
  localparam V_SYNC_END = V_DISPLAY + V_FRONTPORCH + V_PULSEWIDTH;

  reg [9:0] hCounter = 10'd0;
  reg [9:0] vCounter = 10'd0;

  // Horizontal counter
  always @(posedge clk) begin
    if (reset) hCounter <= 10'd0;
    else if (hCounter == H_TOTAL - 1) hCounter <= 10'd0;
    else hCounter <= hCounter + 10'd1;
  end

  // Vertical counter
  always @(posedge clk) begin
    if (reset) vCounter <= 10'd0;
    else if (hCounter == H_TOTAL - 1) begin
      if (vCounter == V_TOTAL - 1) vCounter <= 10'd0;
      else vCounter <= vCounter + 10'd1;
    end
  end

  // Address Logic
  // Pixel doubling: 320x240 buffer -> 640x480 display
  wire [8:0] col = hCounter[9:1];
  wire [8:0] row = vCounter[9:1];
  wire vgaActive = (hCounter < H_DISPLAY) && (vCounter < V_DISPLAY);
  assign readAddress = vgaActive ? (row * 320 + col) : 17'd0;

  // Pipeline Delays
  // Delay vgaActive to match BRAM latency (2 cycles)
  reg vgaActiveD1, vgaActiveD2;
  // Delay sync signals to match BRAM + Color registration (3 cycles total)
  reg [2:0] hsDelay, vsDelay;
  wire hsRaw = ~((hCounter >= H_SYNC_START) && (hCounter < H_SYNC_END));
  wire vsRaw = ~((vCounter >= V_SYNC_START) && (vCounter < V_SYNC_END));

  always @(posedge clk) begin
    if (reset) begin
      vgaActiveD1 <= 1'b0;
      vgaActiveD2 <= 1'b0;
      hsDelay     <= 3'b111;
      vsDelay     <= 3'b111;
    end else begin
      vgaActiveD1 <= vgaActive;
      vgaActiveD2 <= vgaActiveD1;
      hsDelay     <= {hsDelay[1:0], hsRaw};
      vsDelay     <= {vsDelay[1:0], vsRaw};
    end
  end

  // Filter Logic
  wire [11:0] filteredData;
  filter filterModule (
      .rawData     (readData),
      .switch      (switch),
      .filteredData(filteredData)
  );

  // Final Color Output
  reg [3:0] redReg, greenReg, blueReg;
  always @(posedge clk) begin
    if (reset || !vgaActiveD2 || !frameValid) begin
      redReg   <= 4'd0;
      greenReg <= 4'd0;
      blueReg  <= 4'd0;
    end else begin
      redReg   <= filteredData[11:8];
      greenReg <= filteredData[7:4];
      blueReg  <= filteredData[3:0];
    end
  end

  assign vgaRed   = redReg;
  assign vgaGreen = greenReg;
  assign vgaBlue  = blueReg;
  assign vgaHs    = hsDelay[2];
  assign vgaVs    = vsDelay[2];

endmodule
