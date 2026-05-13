import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_top_integration(dut):
    """System-level test: Camera data path to VGA output"""
    
    # 100 MHz main clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    # 24 MHz camera pixel clock
    cocotb.start_soon(Clock(dut.pClk, 41.67, unit="ns").start())
    
    # Reset
    dut.reset.value = 1
    dut.cameraVs.value = 0
    dut.cameraHs.value = 0
    dut.cameraData.value = 0
    dut.switch.value = 0
    await Timer(100, unit="ns")
    dut.reset.value = 0
    
    # Wait for locked signal from clk_wiz
    for _ in range(10):
        await RisingEdge(dut.clk)
    
    # Skip the massive reset counter (24-bit)
    # We force the counter to just before it expires
    dut.resetCounter.value = 0xFFFFFE
    # Wait for the counter to increment and the reset to deassert
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    if dut.globalReset.value != 0:
        dut._log.warning(f"globalReset is still {dut.globalReset.value}, forcing to 0 for simulation")
        dut.globalReset.value = 0
    
    # Now simulate one frame from camera
    # 1. VSync
    dut.cameraVs.value = 1
    await Timer(1000, unit="ns")
    dut.cameraVs.value = 0
    
    # 2. One line of data (Pixel 0,0)
    await RisingEdge(dut.pClk)
    dut.cameraHs.value = 1
    for i in range(10):
        dut.cameraData.value = 0xA
        await RisingEdge(dut.pClk)
        dut.cameraData.value = 0xBC
        await RisingEdge(dut.pClk)
    dut.cameraHs.value = 0
    
    # 3. End of frame (VSync again to trigger frameDone)
    await Timer(1000, unit="ns")
    dut.cameraVs.value = 1
    await Timer(1000, unit="ns")
    dut.cameraVs.value = 0
    
    # 4. Wait for frameValid in VGA domain
    found_valid = False
    for _ in range(500):
        await RisingEdge(dut.vgaControllerModule.clk)
        if dut.frameValid.value == 1:
            found_valid = True
            break
            
    assert found_valid, "frameValid did not assert after frame capture"
    
    # 5. Verify VGA output
    # Wait for VGA active video
    found_data = False
    for _ in range(5000):
        await RisingEdge(dut.vgaControllerModule.clk)
        if dut.vgaRed.value == 0xA and dut.vgaGreen.value == 0xB and dut.vgaBlue.value == 0xC:
            found_data = True
            break
            
    assert found_data, "Captured camera data never appeared on VGA output"
    dut._log.info("Top module integration test passed!")
