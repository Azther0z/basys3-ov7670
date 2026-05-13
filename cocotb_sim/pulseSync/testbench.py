import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_pulse_sync(dut):
    """Test pulse synchronization across clock domains"""
    
    # Create clocks
    cocotb.start_soon(Clock(dut.srcClk, 10, unit="ns").start())  # 100MHz
    cocotb.start_soon(Clock(dut.destClk, 40, unit="ns").start()) # 25MHz
    
    # Reset
    dut.srcReset.value = 1
    dut.destReset.value = 1
    dut.srcPulse.value = 0
    await Timer(100, unit="ns")
    dut.srcReset.value = 0
    dut.destReset.value = 0
    await Timer(100, unit="ns")
    
    # Send a pulse
    await RisingEdge(dut.srcClk)
    dut.srcPulse.value = 1
    await RisingEdge(dut.srcClk)
    dut.srcPulse.value = 0
    
    # Wait for synchronization (should take ~3 destClk cycles)
    found_pulse = False
    for _ in range(20):
        await RisingEdge(dut.destClk)
        if dut.destPulse.value == 1:
            found_pulse = True
            dut._log.info("Pulse successfully synchronized to destination domain")
            break
            
    assert found_pulse, "Pulse was not synchronized!"
    
    # Check that it's exactly one cycle long
    await RisingEdge(dut.destClk)
    assert dut.destPulse.value == 0, "Pulse in destination domain was longer than 1 cycle!"
    
    # Wait for the sync chain to clear before next pulse
    await Timer(200, unit="ns")
    
    # Send another pulse
    dut.srcPulse.value = 1
    await RisingEdge(dut.srcClk)
    dut.srcPulse.value = 0
    
    found_pulse = False
    for _ in range(20):
        await RisingEdge(dut.destClk)
        if dut.destPulse.value == 1:
            found_pulse = True
            break
    assert found_pulse, "Second pulse was not synchronized!"
    
    dut._log.info("Pulse synchronization tests passed!")
