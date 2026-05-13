module pulseSync (
    input  wire srcClk,
    input  wire srcReset,
    input  wire srcPulse,
    input  wire destClk,
    input  wire destReset,
    output wire destPulse
);

  reg srcToggle = 1'b0;
  always @(posedge srcClk) begin
    if (srcReset) srcToggle <= 1'b0;
    else if (srcPulse) srcToggle <= ~srcToggle;
  end

  reg [2:0] destSyncReg = 3'b0;
  always @(posedge destClk) begin
    if (destReset) destSyncReg <= 3'b0;
    else destSyncReg <= {destSyncReg[1:0], srcToggle};
  end

  assign destPulse = destSyncReg[2] ^ destSyncReg[1];

endmodule
