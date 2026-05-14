import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_camera_config_sequence(dut):
    """Test that cameraConfig writes the expected sequence of registers"""
    
    # 100 MHz clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    
    # Reset
    dut.reset.value = 1
    await Timer(100, unit="ns")
    dut.reset.value = 0
    
    # Expected first few registers
    expected_rom = [
        (0x12, 0x80), # COM7: Reset
        (0x11, 0x00), # CLKRC
        (0x6b, 0x4a), # DBLV
        (0x3b, 0x0a), # COM11
        (0x12, 0x04), # COM7: RGB
        (0x40, 0xD0), # COM15
    ]
    
    # We'll check the first 10 registers or until the end
    # Since there are ~70 registers, checking all might be overkill for a unit test, 
    # but let's check at least the first 6.
    
    for i, (addr, data) in enumerate(expected_rom):
        # If we are in RESET_WAIT state (0), skip the counter
        if int(dut.state.value) == 0:
            dut.waitCounter.value = 199998
            
        # Wait for sccbStart to go high
        while int(dut.sccbStart.value) == 0:
            await RisingEdge(dut.clk)
            # If it enters RESET_WAIT while we are waiting, skip it
            if int(dut.state.value) == 0 and int(dut.waitCounter.value) < 199990:
                dut.waitCounter.value = 199998
                
        # Check values
        assert int(dut.address.value) == addr, f"Index {i}: Expected addr {hex(addr)}, got {hex(int(dut.address.value))}"
        assert int(dut.data.value) == data, f"Index {i}: Expected data {hex(data)}, got {hex(int(dut.data.value))}"
        dut._log.info(f"Verified register {i}: {hex(addr)}={hex(data)}")

        # Wait for WAIT_DONE state (2)
        while int(dut.state.value) != 2:
            await RisingEdge(dut.clk)
            
        # The sccbMaster is internal, so we wait for it to finish naturally 
        # or we could force it, but let's let it run.
        # Wait for sccbDone
        while int(dut.sccbDone.value) == 0:
            await RisingEdge(dut.clk)
            
        # After sccbDone, it should move to RESET_WAIT (0) or DONE (3)
        await RisingEdge(dut.clk)

    dut._log.info("Camera configuration sequence test passed!")
