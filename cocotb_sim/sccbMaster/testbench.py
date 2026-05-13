import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge

@cocotb.test()
async def test_sccb_transaction(dut):
    """Test SCCB (I2C-like) write transaction"""
    
    # 100 MHz clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    
    # Reset
    dut.reset.value = 1
    dut.start.value = 0
    dut.device.value = 0x42
    dut.address.value = 0x12
    dut.data.value = 0x80
    await Timer(100, unit="ns")
    dut.reset.value = 0
    await Timer(100, unit="ns")
    
    # Start transaction
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for busy
    while dut.busy.value == 0:
        await RisingEdge(dut.clk)
        
    # Check for Start condition (SDA goes low while SCL is high)
    await FallingEdge(dut.sioD)
    assert dut.sioC.value == 1, "SDA fell but SCL was not high (Start condition error)"
    
    # Monitor the bits
    # Expected sequence: ID(0x42), DC, REG(0x12), DC, DATA(0x80), DC, STOP
    
    async def read_byte():
        byte = 0
        for i in range(8):
            await RisingEdge(dut.sioC)
            # Use integer conversion for cocotb v2.0+ Logic objects
            byte = (byte << 1) | int(dut.sioD.value)
            await FallingEdge(dut.sioC)
        # Read Don't Care bit
        await RisingEdge(dut.sioC)
        await FallingEdge(dut.sioC)
        return byte

    # Wait for first SCL falling edge after start
    await FallingEdge(dut.sioC)
    
    id_byte = await read_byte()
    assert id_byte == 0x42, f"Device ID mismatch: got {hex(id_byte)}"
    
    reg_byte = await read_byte()
    assert reg_byte == 0x12, f"Register address mismatch: got {hex(reg_byte)}"
    
    data_byte = await read_byte()
    assert data_byte == 0x80, f"Data mismatch: got {hex(data_byte)}"
    
    # Check Stop condition (SDA goes high while SCL is high)
    while dut.sioC.value == 0:
        await RisingEdge(dut.clk)
    
    await RisingEdge(dut.sioD)
    assert dut.sioC.value == 1, "SDA rose but SCL was not high (Stop condition error)"
    
    # Wait for done
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
        
    dut._log.info("SCCB transaction test passed!")
