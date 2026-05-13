// Xilinx Primitive and IP Core Stubs for Simulation
module ODDR #(
    parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
) (
    output reg Q,
    input wire C,
    input wire CE,
    input wire D1,
    input wire D2,
    input wire R,
    input wire S
);
    always @(posedge C) begin
        if (R) Q <= 1'b0;
        else if (S) Q <= 1'b1;
        else if (CE) Q <= D1; // Simplified DDR: just pass D1
    end
endmodule

module clk_wiz (
    input wire clk_in1,
    output wire clk_out1,
    output wire clk_out2,
    input wire reset,
    output wire locked
);
    // 100 MHz -> 25 MHz (clk_out1) and 24 MHz (clk_out2)
    reg r_clk_25 = 0;
    reg [1:0] cnt_25 = 0;
    always @(posedge clk_in1) begin
        cnt_25 <= cnt_25 + 1;
        if (cnt_25 == 1) r_clk_25 <= ~r_clk_25;
    end
    assign clk_out1 = r_clk_25;

    reg r_clk_24 = 0;
    reg [1:0] cnt_24 = 0;
    always @(posedge clk_in1) begin
        cnt_24 <= cnt_24 + 1; 
        if (cnt_24 == 1) r_clk_24 <= ~r_clk_24; 
    end
    assign clk_out2 = r_clk_24;
    
    assign locked = !reset;
endmodule

module blk_mem_gen (
    input wire clka,
    input wire wea,
    input wire [16:0] addra,
    input wire [11:0] dina,
    output reg [11:0] douta,
    input wire clkb,
    input wire web,
    input wire [16:0] addrb,
    input wire [11:0] dinb,
    output reg [11:0] doutb
);
    reg [11:0] ram [0:131071]; 

    always @(posedge clka) begin
        if (wea) ram[addra] <= dina;
        douta <= ram[addra];
    end

    always @(posedge clkb) begin
        if (web) ram[addrb] <= dinb;
        doutb <= ram[addrb];
    end
endmodule

// Helper to dump waveforms for Icarus Verilog
module cocotb_dump();
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0);
    end
endmodule
