`timescale 1ns / 1ps

module sccb_master (
    input  wire       clk,        // System clock (e.g. 100 MHz or 25 MHz)
    input  wire       rst,        // Active high synchronous reset
    input  wire       start,      // Assert high to start transmission
    input  wire [7:0] reg_addr,   // Register address to write
    input  wire [7:0] reg_data,   // Data to write to register
    output reg        ready,      // High when idle and ready for new operation
    output reg        sccb_c,     // SCCB Clock (SIO_C)
    inout  wire       sccb_d      // SCCB Data (SIO_D)
);

    // I2C/SCCB Device Address for OV7670 Write
    localparam ID_ADDR = 8'h42; 

    // Adjust divider based on input clock. For 25MHz clk to get ~100kHz I2C:
    // 25MHz / 250 = 100kHz. So counter max around 249.
    // Let's use a conservative 400kHz for initialization.
    // Note: We need 4 states per I2C clock cycle (low, rise, high, fall).
    // If clk=25MHz. Wait wait, usually clk could be 100MHz from Basys3 directly.
    // Let's assume 100MHz input clock.
    // 100MHz / (4 * 100kHz) = 250 ticks per quarter cycle.
    localparam DIVIDER = 250; 
    
    // States
    localparam IDLE         = 0;
    localparam START_COND   = 1;
    localparam PHASE1_ID    = 2;
    localparam PHASE1_ACK   = 3;
    localparam PHASE2_ADDR  = 4;
    localparam PHASE2_ACK   = 5;
    localparam PHASE3_DATA  = 6;
    localparam PHASE3_ACK   = 7;
    localparam STOP_COND    = 8;
    localparam WAIT_END     = 9;

    reg [3:0]  state;
    reg [15:0] count;
    reg [2:0]  bit_count;
    reg [7:0]  shift_reg;

    reg sccb_d_out;
    reg sccb_d_oe;

    assign sccb_d = sccb_d_oe ? sccb_d_out : 1'bz;

    // Single unified block to avoid cycle mismatches and lock-ups between state/count
    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            sccb_c     <= 1;
            sccb_d_out <= 1;
            sccb_d_oe  <= 1;
            ready      <= 1;
            bit_count  <= 0;
            shift_reg  <= 0;
            count      <= 0;
        end else begin
            if (state == IDLE) begin
                count      <= 0;
                sccb_c     <= 1;
                sccb_d_out <= 1;
                sccb_d_oe  <= 1;
                ready      <= 1;
                if (start) begin
                    state <= START_COND;
                    ready <= 0;
                end
            end else begin
                // Active State: always increment unless explicitly resetting
                count <= count + 1;
                
                case (state)
                    START_COND: begin
                        if (count == DIVIDER*1) sccb_d_out <= 0; // SDA goes low
                        if (count == DIVIDER*3) begin
                            sccb_c    <= 0; // SCL goes low
                            state     <= PHASE1_ID;
                            shift_reg <= ID_ADDR;
                            bit_count <= 7;
                            count     <= 0; // Reset counter for new state!
                        end
                    end

                    PHASE1_ID, PHASE2_ADDR, PHASE3_DATA: begin
                        if (count == 0) sccb_d_out <= shift_reg[bit_count];
                        if (count == DIVIDER*1) sccb_c <= 1;
                        if (count == DIVIDER*3) begin
                            sccb_c <= 0;
                            count  <= 0;
                            if (bit_count == 0) begin
                                if (state == PHASE1_ID) state <= PHASE1_ACK;
                                else if (state == PHASE2_ADDR) state <= PHASE2_ACK;
                                else state <= PHASE3_ACK;
                            end else begin
                                bit_count <= bit_count - 1;
                            end
                        end
                    end

                    PHASE1_ACK, PHASE2_ACK, PHASE3_ACK: begin
                        if (count == 0) sccb_d_oe <= 0; // Let camera ACK
                        if (count == DIVIDER*1) sccb_c <= 1;
                        if (count == DIVIDER*3) begin
                            sccb_c    <= 0;
                            sccb_d_oe <= 1; // Take back SDA
                            count     <= 0;
                            if (state == PHASE1_ACK) begin
                                state     <= PHASE2_ADDR;
                                shift_reg <= reg_addr;
                                bit_count <= 7;
                            end else if (state == PHASE2_ACK) begin
                                state     <= PHASE3_DATA;
                                shift_reg <= reg_data;
                                bit_count <= 7;
                            end else begin
                                state <= STOP_COND;
                            end
                        end
                    end

                    STOP_COND: begin
                        if (count == 0) sccb_d_out <= 0;    
                        if (count == DIVIDER*1) sccb_c <= 1; 
                        if (count == DIVIDER*3) begin
                            sccb_d_out <= 1; 
                            state      <= WAIT_END;
                            count      <= 0;
                        end
                    end

                    WAIT_END: begin
                        if (count == DIVIDER*2) begin
                            state <= IDLE;
                            count <= 0;
                        end
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule
