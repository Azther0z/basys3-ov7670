import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

@cocotb.test()
async def test_camera_capture(dut):
    """Test camera capture logic and address calculation"""
    
    # 24 MHz pixel clock (period ~41.67ns)
    cocotb.start_soon(Clock(dut.pClk, 41.67, unit="ns").start())
    
    # Reset
    dut.reset.value = 1
    dut.cameraVs.value = 0
    dut.cameraHs.value = 0
    dut.cameraData.value = 0
    await Timer(100, unit="ns")
    dut.reset.value = 0
    await Timer(100, unit="ns")
    
    # Simulate VSync pulse (Active High)
    dut.cameraVs.value = 1
    await Timer(500, unit="ns")
    dut.cameraVs.value = 0
    
    # Wait for frameDone (happens after vsync falls)
    await RisingEdge(dut.frameDone)
    dut._log.info("frameDone detected")
    
    # Small delay before starting line
    await Timer(100, unit="ns")
    
    # Line 0 (Even line)
    dut.cameraHs.value = 1
    captured_pixels = 0
    for p in range(640):
        # Byte 1: High nibble of color
        dut.cameraData.value = 0xA  # Red=A
        await FallingEdge(dut.pClk)
        
        # Byte 2: Low nibble of color
        dut.cameraData.value = 0xBC # Green=B, Blue=C
        await FallingEdge(dut.pClk)
        
        # Wait a tiny bit for non-blocking assignments to update
        await Timer(1, unit="ns")
        
        if dut.writeEnable.value == 1:
            captured_pixels += 1
            if captured_pixels == 1:
                assert dut.writeData.value == 0xABC, f"Data mismatch: got {hex(dut.writeData.value)}"
                assert dut.writeAddress.value == 0, f"Addr mismatch: got {dut.writeAddress.value}, expected 0"

    dut.cameraHs.value = 0
    await Timer(100, unit="ns")
    assert captured_pixels == 320, f"Captured {captured_pixels} pixels, expected 320"
    
    # Line 1 (Odd line) - Should be skipped
    dut.cameraHs.value = 1
    captured_pixels_odd = 0
    for p in range(640):
        dut.cameraData.value = 0x1
        await FallingEdge(dut.pClk)
        dut.cameraData.value = 0x2
        await FallingEdge(dut.pClk)
        await Timer(1, unit="ns")
        if dut.writeEnable.value == 1:
            captured_pixels_odd += 1
    dut.cameraHs.value = 0
    await Timer(100, unit="ns")
    assert captured_pixels_odd == 0, "Odd lines should not be captured"
    
    # Line 2 (Even line) - Should be captured
    dut.cameraHs.value = 1
    captured_pixels_2 = 0
    for p in range(640):
        dut.cameraData.value = 0x3
        await FallingEdge(dut.pClk)
        dut.cameraData.value = 0x45
        await FallingEdge(dut.pClk)
        await Timer(1, unit="ns")
        if dut.writeEnable.value == 1:
            captured_pixels_2 += 1
            # Address for line 2 (vCounter=2 -> vCounter[9:1]=1) should start at 320
            expected_addr = 320 + (captured_pixels_2 - 1)
            if captured_pixels_2 == 1:
                assert dut.writeAddress.value == expected_addr, f"Addr mismatch line 2: got {dut.writeAddress.value}, expected {expected_addr}"
    dut.cameraHs.value = 0
    
    dut._log.info("Camera capture test passed!")
