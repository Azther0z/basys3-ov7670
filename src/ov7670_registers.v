`timescale 1ns / 1ps

module ov7670_registers (
    input  wire       clk,        // System clock
    input  wire       rst,        // Synchronous reset
    input  wire       sccb_ready, // Master is ready
    output reg        sccb_start, // Start SCCB transmission
    output reg  [7:0] reg_addr,   // Register address
    output reg  [7:0] reg_data,   // Register data
    output reg        done        // Configuration is complete
);

    // Number of configuration registers to write
    localparam NUM_REGS = 18; 

    reg [23:0] delay_cnt; // 24-bit covers up to 16,777,215 cycles @ 100MHz = 167ms
    reg [7:0] reg_index;

    // FSM States
    localparam INIT      = 0;
    localparam WRITE     = 1;
    localparam WAIT      = 2;
    localparam WAIT_DONE = 3;
    localparam DELAY     = 4;
    localparam FINISH    = 5;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= INIT;
            sccb_start <= 0;
            reg_index <= 0;
            done <= 0;
            delay_cnt <= 0;
        end else begin
            case (state)
                INIT: begin
                    done <= 0;
                    // 100ms boot-up delay: OV7670 needs time to power up and stabilize
                    if (delay_cnt == 24'd10_000_000) begin
                        state <= WRITE;
                        delay_cnt <= 0;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                WRITE: begin
                    if (sccb_ready) begin
                        sccb_start <= 1;
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    sccb_start <= 0;
                    // Wait for the master to acknowledge the start and drop ready
                    if (!sccb_ready) begin
                        state <= WAIT_DONE;
                    end
                end

                WAIT_DONE: begin
                    // Wait for master to finish I2C transaction
                    if (sccb_ready) begin
                        state <= DELAY;
                        delay_cnt <= 0;
                    end
                end

                DELAY: begin
                    // 1ms delay between register writes (especially important after 0x80 soft reset)
                    if (delay_cnt == 24'd100_000) begin
                        if (reg_index == NUM_REGS - 1) begin
                            state <= FINISH;
                        end else begin
                            reg_index <= reg_index + 1;
                            state <= WRITE;
                        end
                        delay_cnt <= 0; // ready for next use
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

    // ROM containing register config: {Address, Data}
    always @(*) begin
        case (reg_index)
            // Reset to defaults
            0:  begin reg_addr = 8'h12; reg_data = 8'h80; end // COM7: Reset all registers
            // Delay after reset (handled externally or implied by SCCB speed)
            
            // Output format: RGB565 Setup, Default VGA resolution (640x480)
            // Enabling Color Bar test pattern (Bit 1) to verify byte alignment
            1:  begin reg_addr = 8'h12; reg_data = 8'h06; end // COM7: RGB formatting + Color Bar
            2:  begin reg_addr = 8'h40; reg_data = 8'hd0; end // COM15: RGB565, full range
            
            // Resolution (VGA)
            3:  begin reg_addr = 8'h32; reg_data = 8'h80; end // HREF
            4:  begin reg_addr = 8'h17; reg_data = 8'h16; end // HSTART
            5:  begin reg_addr = 8'h18; reg_data = 8'h04; end // HSTOP
            6:  begin reg_addr = 8'h19; reg_data = 8'h02; end // VSTRT
            7:  begin reg_addr = 8'h1a; reg_data = 8'h7b; end // VSTOP
            8:  begin reg_addr = 8'h03; reg_data = 8'h0a; end // VREF
            
            // Clock control
            9:  begin reg_addr = 8'h11; reg_data = 8'h00; end // CLKRC: No prescaler

            // Basic color metrics and scaling
            10: begin reg_addr = 8'hf6; reg_data = 8'h22; end // ABLC1
            11: begin reg_addr = 8'h1e; reg_data = 8'h37; end // MVFP: Mirror/flip etc. Currently default.
            12: begin reg_addr = 8'h3a; reg_data = 8'h04; end // TSLB

            // AGC, AWB, AEC (Auto settings turn ON)
            13: begin reg_addr = 8'h13; reg_data = 8'he7; end // COM8: Enable AGC, AWB, AEC
            14: begin reg_addr = 8'h00; reg_data = 8'h00; end // GAIN
            15: begin reg_addr = 8'h01; reg_data = 8'h00; end // BLUE
            16: begin reg_addr = 8'h02; reg_data = 8'h00; end // RED
            
            // End
            17: begin reg_addr = 8'h09; reg_data = 8'h00; end // COM2
            default: begin reg_addr = 8'hff; reg_data = 8'hff; end 
        endcase
    end

endmodule
