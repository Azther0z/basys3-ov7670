import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_filter_logic(dut):
    """Test VGA filter logic (Greyscale, Inverse, Isolation)"""
    
    # Raw data: R=12 (0xC), G=8 (0x8), B=4 (0x4) -> 0xC84
    dut.rawData.value = 0xC84
    
    # Test Raw (switch = 0)
    dut.switch.value = 0
    await Timer(1, unit="ns")
    assert dut.filteredData.value == 0xC84, f"Raw failed: expected 0xC84, got {hex(dut.filteredData.value)}"
    
    # Test Inverse (switch[4] = 1)
    dut.switch.value = 0x10 # 5'b10000
    await Timer(1, unit="ns")
    assert dut.filteredData.value == 0xFFF ^ 0xC84, "Inverse failed"
    
    # Test Greyscale (switch[0] = 1)
    # Formula: Y = (R4*54 + G4*183 + B4*18) >> 8
    # Y = (12*54 + 8*183 + 4*18) = 648 + 1464 + 72 = 2184
    # 2184 >> 8 = 8.53... -> 8 (0x8)
    dut.switch.value = 0x01
    await Timer(1, unit="ns")
    # Grayscale should be 0x888
    assert dut.filteredData.value == 0x888, f"Grayscale failed: expected 0x888, got {hex(dut.filteredData.value)}"
    
    # Test Color Isolation (Red)
    dut.switch.value = 0x08 # switch[3]
    await Timer(1, unit="ns")
    assert dut.filteredData.value == 0xC00, "Red isolation failed"
    
    # Test Color Isolation (Green)
    dut.switch.value = 0x04 # switch[2]
    await Timer(1, unit="ns")
    assert dut.filteredData.value == 0x080, "Green isolation failed"
    
    # Test Color Isolation (Blue)
    dut.switch.value = 0x02 # switch[1]
    await Timer(1, unit="ns")
    assert dut.filteredData.value == 0x004, "Blue isolation failed"
    
    dut._log.info("Filter logic tests passed!")
