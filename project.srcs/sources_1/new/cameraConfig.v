module cameraConfig (
    input wire clk,  // 100 MHz clock
    input wire reset,
    output sioC,
    output sioD
);

  // Register ROM — {addr, data} pairs
  reg [15:0] romValue;
  reg [ 6:0] romIndex;

  always @(*) begin
    case (romIndex)
      // Soft Reset
      7'd0: romValue = {8'h12, 8'h80};  // COM7: Reset all registers to default values

      // Clocking & PLL
      7'd1: romValue = {8'h11, 8'h00};  // CLKRC: Internal clock pre-scalar = 1 (F_int = F_ext / 1)
      7'd2: romValue = {8'h6b, 8'h4a};  // DBLV: PLL control: Bypass PLL (0x0A) -> PLL x4 (0x4a)
      7'd3:
      romValue = {
        8'h3b, 8'h0a
      };  // COM11: Night mode disable, exposure timing can be less than banding limit

      // Format & Scaling
      7'd4: romValue = {8'h12, 8'h04};  // COM7: Select RGB output format
      7'd5: romValue = {8'h40, 8'hD0};  // COM15: RGB 565, Output range [00] to [FF] (Full range)
      7'd6: romValue = {8'h3a, 8'h04};  // TSLB: Output sequence Y U Y V, auto output window enable
      7'd7: romValue = {8'h0c, 8'h00};  // COM3: Scale disable, DCW disable
      7'd8: romValue = {8'h3e, 8'h00};  // COM14: Normal PCLK, manual scaling disable
      7'd9: romValue = {8'h70, 8'h3a};  // SCALING_XSC: Horizontal scale factor = 0x3a
      7'd10: romValue = {8'h71, 8'h35};  // SCALING_YSC: Vertical scale factor = 0x35
      7'd11: romValue = {8'h72, 8'h11};  // SCALING_DCWCTR: Vertical/Horizontal down sampling by 2
      7'd12:
      romValue = {
        8'h73, 8'hf1
      };  // SCALING_PCLK_DIV: Bypass clock divider for DSP scale control, PCLK div by 2
      7'd13: romValue = {8'ha2, 8'h02};  // SCALING_PCLK_DELAY: Scaling output delay = 0x02

      // Windowing
      7'd14: romValue = {8'h17, 8'h13};  // HSTART: Horizontal Frame start high 8-bit
      7'd15: romValue = {8'h18, 8'h01};  // HSTOP: Horizontal Frame end high 8-bit
      7'd16: romValue = {8'h32, 8'hbf};  // HREF: HREF edge offset and start/stop low 3-bits
      7'd17: romValue = {8'h19, 8'h02};  // VSTART: Vertical Frame start high 8-bit
      7'd18: romValue = {8'h1a, 8'h7a};  // VSTOP: Vertical Frame end high 8-bit
      7'd19: romValue = {8'h03, 8'h0a};  // VREF: Vertical Frame start/stop low 2-bits
      7'd20: romValue = {8'h4f, 8'hb3};  // MTX1: Color matrix coefficient 1
      7'd21: romValue = {8'h50, 8'hb3};  // MTX2: Color matrix coefficient 2
      7'd22: romValue = {8'h51, 8'h00};  // MTX3: Color matrix coefficient 3
      7'd23: romValue = {8'h52, 8'h3d};  // MTX4: Color matrix coefficient 4
      7'd24: romValue = {8'h53, 8'ha7};  // MTX5: Color matrix coefficient 5
      7'd25: romValue = {8'h54, 8'he4};  // MTX6: Color matrix coefficient 6
      7'd26: romValue = {8'h58, 8'h5e};  // MTXS: Matrix coefficient sign control

      // AEC/AGC/AWB
      7'd27: romValue = {8'h13, 8'hef};  // COM8: Enable AEC, AGC, AWB, Fast AEC/AGC algorithm
      7'd28: romValue = {8'h00, 8'h00};  // GAIN: AGC gain control
      7'd29: romValue = {8'h10, 8'h00};  // AECH: Exposure Value (AEC[9:2])
      7'd30: romValue = {8'h0d, 8'h40};  // COM4: Window average option (1/2 window)
      7'd31: romValue = {8'h14, 8'h38};  // COM9: Automatic Gain Ceiling = 8x
      7'd32: romValue = {8'h24, 8'h95};  // AEW: AGC/AEC Stable Operating Region (Upper Limit)
      7'd33: romValue = {8'h25, 8'h33};  // AEB: AGC/AEC Stable Operating Region (Lower Limit)
      7'd34: romValue = {8'h26, 8'he3};  // VPT: AGC/AEC Fast Mode Operating Region

      // Gamma Curve
      7'd35: romValue = {8'h7a, 8'h20};  // SLOP: Gamma curve highest segment slope
      7'd36: romValue = {8'h7b, 8'h10};  // GAM1: Gamma curve 1st segment output value
      7'd37: romValue = {8'h7c, 8'h1e};  // GAM2: Gamma curve 2nd segment output value
      7'd38: romValue = {8'h7d, 8'h35};  // GAM3: Gamma curve 3rd segment output value
      7'd39: romValue = {8'h7e, 8'h5a};  // GAM4: Gamma curve 4th segment output value
      7'd40: romValue = {8'h7f, 8'h69};  // GAM5: Gamma curve 5th segment output value
      7'd41: romValue = {8'h80, 8'h76};  // GAM6: Gamma curve 6th segment output value
      7'd42: romValue = {8'h81, 8'h80};  // GAM7: Gamma curve 7th segment output value
      7'd43: romValue = {8'h82, 8'h88};  // GAM8: Gamma curve 8th segment output value
      7'd44: romValue = {8'h83, 8'h8f};  // GAM9: Gamma curve 9th segment output value
      7'd45: romValue = {8'h84, 8'h96};  // GAM10: Gamma curve 10th segment output value
      7'd46: romValue = {8'h85, 8'ha3};  // GAM11: Gamma curve 11th segment output value
      7'd47: romValue = {8'h86, 8'haf};  // GAM12: Gamma curve 12th segment output value
      7'd48: romValue = {8'h87, 8'hc4};  // GAM13: Gamma curve 13th segment output value
      7'd49: romValue = {8'h88, 8'hd7};  // GAM14: Gamma curve 14th segment output value
      7'd50: romValue = {8'h89, 8'he8};  // GAM15: Gamma curve 15th segment output value

      // DSP & Denoise
      7'd51: romValue = {8'h41, 8'h38};  // COM16: De-noise threshold auto-adj + AWB gain ENABLED
      7'd52:
      romValue = {
        8'h76, 8'he1
      };  // REG76: Black/White pixel correction enable, edge enhancement limit
      7'd53: romValue = {8'h33, 8'h0b};  // CHLF: Array current control
      7'd54: romValue = {8'h3c, 8'h78};  // COM12: Always has HREF (HREF option)
      7'd55: romValue = {8'h69, 8'h00};  // GFIX: Fix gain for RGB channels = 1x
      7'd56: romValue = {8'h74, 8'h00};  // REG74: Digital gain manual control bypass
      7'd57: romValue = {8'hb0, 8'h84};  // RSVD: Undocumented / Factory-reserved
      7'd58: romValue = {8'hb1, 8'h0c};  // ABLC1: Enable Automatic Black Level Calibration
      7'd59: romValue = {8'hb2, 8'h0e};  // RSVD: Undocumented / Factory-reserved
      7'd60: romValue = {8'hb3, 8'h82};  // THL_ST: ABLC Target value

      // Saturation & Contrast
      7'd61: romValue = {8'h67, 8'hc0};  // MANU: Manual U Value (Saturation Boost)
      7'd62: romValue = {8'h68, 8'hc0};  // MANV: Manual V Value (Saturation Boost)
      7'd63: romValue = {8'h56, 8'h40};  // CONTRAS: Contrast Control

      // Frame Stability & Color
      7'd64: romValue = {8'h15, 8'h00};  // COM10: PCLK output option, VSYNC/HREF/HSYNC polarity
      7'd65: romValue = {8'h0e, 8'h61};  // COM6: Reset all timing when format changes
      7'd66: romValue = {8'h16, 8'h00};  // RSVD: Reserved
      7'd67: romValue = {8'h1e, 8'h07};  // MVFP: Mirror/VFlip enable, black sun enable
      7'd68: romValue = {8'h3d, 8'hc0};  // COM13: Gamma enable, UV saturation auto adjustment
      7'd69: romValue = {8'h8c, 8'h02};  // RGB444: RGB444 enable, xR GB format

      default: romValue = {8'hFF, 8'hFF};
    endcase
  end

  // Wait after soft reset, then write all registers
  localparam RESET_WAIT_COUNTER = 200_000;
  reg [17:0] waitCounter;

  localparam RESET_WAIT = 2'd0;
  localparam START = 2'd1;
  localparam WAIT_DONE = 2'd2;
  localparam DONE = 2'd3;

  reg [1:0] state;
  reg sccbStart;
  wire sccbDone, sccbBusy;
  reg [7:0] address;
  reg [7:0] data;

  sccbMaster sccbMasterModule (
      .clk(clk),
      .reset(reset),
      .start(sccbStart),
      .device(8'h42),
      .address(address),
      .data(data),
      .sioC(sioC),
      .sioD(sioD),
      .done(sccbDone),
      .busy(sccbBusy)
  );

  always @(posedge clk) begin
    if (reset) begin
      state       <= RESET_WAIT;
      romIndex    <= 7'd0;
      sccbStart   <= 1'b0;
      address     <= 8'd0;
      data        <= 8'd0;
      waitCounter <= 18'd0;
    end else begin
      sccbStart <= 1'b0;  // default
      case (state)
        RESET_WAIT: begin
          if (waitCounter == RESET_WAIT_COUNTER - 1) begin
            waitCounter <= 18'd0;
            state       <= START;
          end else begin
            waitCounter <= waitCounter + 18'd1;
          end
        end
        START: begin
          if (romValue == 16'hFFFF) begin
            state <= DONE;
          end else begin
            address   <= romValue[15:8];
            data      <= romValue[7:0];
            sccbStart <= 1'b1;
            state     <= WAIT_DONE;
            if (romIndex == 7'd0) waitCounter <= 18'd0;
          end
        end
        WAIT_DONE: begin
          if (sccbDone) begin
            romIndex    <= romIndex + 7'd1;
            waitCounter <= 18'd0;
            state       <= RESET_WAIT;
          end
        end
        DONE: begin
        end
        default: state <= RESET_WAIT;
      endcase
    end
  end

endmodule
