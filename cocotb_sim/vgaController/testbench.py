import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_vga_timings(dut):
    """Test VGA signal timings and address generation"""
    
    # 25 MHz pixel clock
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    
    # Reset
    dut.reset.value = 1
    dut.readData.value = 0
    dut.switch.value = 0
    dut.frameValid.value = 1
    await Timer(100, unit="ns")
    dut.reset.value = 0
    
    # Check H-Sync timing
    # H_DISPLAY = 640
    # H_FRONTPORCH = 16
    # H_PULSEWIDTH = 96
    # H_BACKPORCH = 48
    # H_TOTAL = 800
    
    # Wait for active video to start
    await RisingEdge(dut.clk)
    while dut.vgaHs.value == 0: # hs is active low
        await RisingEdge(dut.clk)
        
    # Start of a line
    # H_DISPLAY cycles of active video (with 3 cycles delay in the dut for sync)
    # The dut delays hs by 3 cycles (hsDelay[2])
    # The active video logic in the dut:
    # vgaActive = (hCounter < 640) && (vCounter < 480)
    # hsRaw is ~((hCounter >= 656) && (hCounter < 752))
    
    # Let's count cycles for HSync
    h_total = 800
    v_total = 521
    
    # Wait for vCounter to be 0
    while dut.vgaVs.value == 0:
        await RisingEdge(dut.clk)
        
    # Check one full line
    h_sync_low_count = 0
    for i in range(h_total):
        if dut.vgaHs.value == 0:
            h_sync_low_count += 1
        await RisingEdge(dut.clk)
        
    assert h_sync_low_count == 96, f"HSync pulse width incorrect: got {h_sync_low_count}, expected 96"
    
    # Check address generation at start of frame
    # Reset to start of frame
    dut.reset.value = 1
    await Timer(100, unit="ns")
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    
    # Address should be row*320 + col
    # hCounter=0, vCounter=0 -> row=0, col=0 -> addr=0
    assert dut.readAddress.value == 0, f"Initial address incorrect: {dut.readAddress.value}"
    
    # Move to next pixel (pixel doubling, so same address for 2 cycles)
    await RisingEdge(dut.clk)
    assert dut.readAddress.value == 0, "Address should stay 0 for 2 cycles (pixel doubling)"
    
    await RisingEdge(dut.clk)
    assert dut.readAddress.value == 1, f"Address should be 1 now, got {dut.readAddress.value}"
    
    # Move to next row (after 800 cycles)
    for _ in range(800 - 2):
        await RisingEdge(dut.clk)
    
    # Now at hCounter=0, vCounter=1 -> row=0, col=0 -> addr=0
    assert dut.readAddress.value == 0, f"Address at start of second line (vCounter=1) should be 0 (row doubling), got {dut.readAddress.value}"
    
    # Move to vCounter=2 -> row=1, col=0 -> addr=320
    for _ in range(800):
        await RisingEdge(dut.clk)
        
    assert dut.readAddress.value == 320, f"Address at start of third line (vCounter=2) should be 320, got {dut.readAddress.value}"
    
    dut._log.info("VGA Controller timing and address tests passed!")
