module sccbMaster #(
    parameter CLOCK_FREQUENCY = 100_000_000,  // system clock frequency in Hz
    parameter SCCB_FREQUENCY  = 100_000       // target SCCB clock in Hz
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [7:0] device,   // 8-bit device address
    input  wire [7:0] address,  // 8-bit register address
    input  wire [7:0] data,     // 8-bit write data
    output reg        sioC,
    output reg        sioD,
    output reg        done,
    output reg        busy
);

  // Clock divider — generate quarter-period tick for SCL generation
  // One SCL period = 4 ticks: low0, low1 (SDA change here), high0, high1
  localparam CLK_DIVIDER = CLOCK_FREQUENCY / (SCCB_FREQUENCY * 4);  // quarter-period count

  reg [31:0] clkCounter;
  reg        tick;  // 1-cycle pulse at each quarter period

  always @(posedge clk) begin
    if (reset) begin
      clkCounter <= 0;
      tick       <= 1'b0;
    end else begin
      tick <= 1'b0;
      if (clkCounter == CLK_DIVIDER - 1) begin
        clkCounter <= 0;
        tick       <= 1'b1;
      end else begin
        clkCounter <= clkCounter + 1;
      end
    end
  end

  // State machine
  localparam IDLE = 4'd0;
  localparam START = 4'd1;
  localparam ID = 4'd2;  // transmit device address + W bit
  localparam DC_ID = 4'd3;  // don't-care bit after ID byte
  localparam REG = 4'd4;  // transmit register address
  localparam DC_REG = 4'd5;  // don't-care bit after reg byte
  localparam DATA = 4'd6;  // transmit data byte
  localparam DC_DATA = 4'd7;  // don't-care bit after data byte
  localparam STOP = 4'd8;
  localparam DONE = 4'd9;

  reg [3:0] state;
  reg [3:0] bitCount;  // counts 7..0 during byte transmission
  reg [1:0] phase;  // quarter-period phase: 0=SCL low, 1=SDA change,
                    //                       2=SCL rise, 3=SCL high
  reg [7:0] buffer;  // current byte being shifted out

  always @(posedge clk) begin
    if (reset) begin
      state    <= IDLE;
      sioC     <= 1'b1;
      sioD     <= 1'b1;
      done     <= 1'b0;
      busy     <= 1'b0;
      bitCount <= 4'd7;
      phase    <= 2'd0;
      buffer   <= 8'd0;
    end else begin
      done <= 1'b0;  // default: done is a single-cycle pulse
      case (state)
        IDLE: begin
          sioC <= 1'b1;
          sioD <= 1'b1;
          busy <= 1'b0;
          if (start) begin
            busy    <= 1'b1;
            buffer <= device;
            bitCount <= 4'd7;
            phase   <= 2'd0;
            state   <= START;
          end
        end
        START: begin
          if (tick) begin
            case (phase)
              2'd0: begin
                sioC  <= 1'b1;
                sioD  <= 1'b1;
                phase <= 2'd1;
              end
              2'd1: begin
                sioD  <= 1'b0;
                phase <= 2'd2;
              end  // SDA↓ while SCL=1
              2'd2: begin
                sioC  <= 1'b0;
                phase <= 2'd3;
              end
              2'd3: begin
                phase <= 2'd0;
                bitCount <= 4'd7;
                buffer <= device;
                state <= ID;
              end
            endcase
          end
        end
        ID, REG, DATA: begin
          if (tick) begin
            case (phase)
              2'd0: begin
                sioC  <= 1'b0;
                phase <= 2'd1;
              end
              2'd1: begin
                sioD  <= buffer[bitCount];
                phase <= 2'd2;
              end
              2'd2: begin
                sioC  <= 1'b1;
                phase <= 2'd3;
              end
              2'd3: begin
                phase <= 2'd0;
                if (bitCount == 4'd0) begin
                  // move to don't-care phase
                  case (state)
                    ID: state <= DC_ID;
                    REG: state <= DC_REG;
                    DATA: state <= DC_DATA;
                    default: state <= STOP;
                  endcase
                end else begin
                  bitCount <= bitCount - 4'd1;
                end
              end
            endcase
          end
        end
        DC_ID, DC_REG, DC_DATA: begin
          if (tick) begin
            case (phase)
              2'd0: begin
                sioC  <= 1'b0;
                sioD  <= 1'b1;
                phase <= 2'd1;
              end
              2'd1: begin
                phase <= 2'd2;
              end
              2'd2: begin
                sioC  <= 1'b1;
                phase <= 2'd3;
              end
              2'd3: begin
                phase   <= 2'd0;
                sioC    <= 1'b0;
                bitCount <= 4'd7;
                case (state)
                  DC_ID: begin
                    buffer <= address;
                    state  <= REG;
                  end
                  DC_REG: begin
                    buffer <= data;
                    state  <= DATA;
                  end
                  DC_DATA: state <= STOP;
                  default: state <= STOP;
                endcase
              end
            endcase
          end
        end
        STOP: begin
          if (tick) begin
            case (phase)
              2'd0: begin
                sioC  <= 1'b0;
                sioD  <= 1'b0;
                phase <= 2'd1;
              end
              2'd1: begin
                sioC  <= 1'b1;
                phase <= 2'd2;
              end
              2'd2: begin
                sioD  <= 1'b1;
                phase <= 2'd3;
              end
              2'd3: begin
                phase <= 2'd0;
                state <= DONE;
              end
            endcase
          end
        end
        DONE: begin
          done  <= 1'b1;
          busy  <= 1'b0;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
