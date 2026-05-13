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
    
    # The module has a RESET_WAIT_COUNTER of 200,000.
    # To speed up simulation, we can force the counter or just wait.
    # Since it's a test, let's wait or modify the parameter if possible.
    # In cocotb we can't easily modify internal regs unless we use 'dut.waitCounter.value = ...'
    
    # Skip the wait
    await RisingEdge(dut.clk)
    dut.waitCounter.value = 199998
    
    # Wait for the first SCCB start
    # romIndex 0: 0x12, 0x80
    while dut.sccbStart.value == 0:
        await RisingEdge(dut.clk)
        
    assert dut.address.value == 0x12, f"Expected 0x12, got {hex(dut.address.value)}"
    assert dut.data.value == 0x80, f"Expected 0x80, got {hex(dut.data.value)}"
    
    # Simulate SCCB completion
    await RisingEdge(dut.clk)
    # We need to wait for state to change to WAIT_DONE
    # Then force sccbDone
    while dut.state.value != 2: # WAIT_DONE
        await RisingEdge(dut.clk)
        
    # Send done
    # Note: sccbDone is an input from sccbMasterModule. 
    # Since we are testing cameraConfig, sccbMaster is instantiated.
    # We should let sccbMaster run OR force its 'done' output if we can access it.
    # Better: just wait for sccbMaster to finish one transaction.
    
    while dut.sccbDone.value == 0:
        await RisingEdge(dut.clk)
        
    # Now it should move to romIndex 1: 0x11, 0x00
    while dut.sccbStart.value == 0:
        await RisingEdge(dut.clk)
        
    assert dut.address.value == 0x11, f"Expected 0x11, got {hex(dut.address.value)}"
    assert dut.data.value == 0x00, f"Expected 0x00, got {hex(dut.data.value)}"
    
    dut._log.info("Camera config sequence tests started successfully!")
