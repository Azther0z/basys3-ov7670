set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

create_clock -period 40.000 -name pClk [get_ports pClk]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks clk] \
    -group [get_clocks pClk]

set_property PACKAGE_PIN U18  [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property PACKAGE_PIN P17  [get_ports {cameraData[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[0]}]

set_property PACKAGE_PIN N17  [get_ports {cameraData[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[1]}]

set_property PACKAGE_PIN M19  [get_ports {cameraData[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[2]}]

set_property PACKAGE_PIN M18  [get_ports {cameraData[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[3]}]

set_property PACKAGE_PIN L17  [get_ports {cameraData[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[4]}]

set_property PACKAGE_PIN K17  [get_ports {cameraData[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[5]}]

set_property PACKAGE_PIN C16  [get_ports {cameraData[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[6]}]

set_property PACKAGE_PIN B16  [get_ports {cameraData[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cameraData[7]}]

set_property PACKAGE_PIN A17  [get_ports cameraHs]
set_property IOSTANDARD LVCMOS33 [get_ports cameraHs]

set_property PACKAGE_PIN A16  [get_ports pClk]
set_property IOSTANDARD LVCMOS33 [get_ports pClk]

set_property PACKAGE_PIN R18  [get_ports cameraPwdn]
set_property IOSTANDARD LVCMOS33 [get_ports cameraPwdn]

set_property PACKAGE_PIN P18  [get_ports cameraReset]
set_property IOSTANDARD LVCMOS33 [get_ports cameraReset]

set_property PACKAGE_PIN A14  [get_ports sioC]
set_property IOSTANDARD LVCMOS33 [get_ports sioC]

set_property PACKAGE_PIN A15  [get_ports sioD]
set_property IOSTANDARD LVCMOS33 [get_ports sioD]

set_property PACKAGE_PIN B15  [get_ports cameraVs]
set_property IOSTANDARD LVCMOS33 [get_ports cameraVs]

set_property PACKAGE_PIN C15  [get_ports xClk]
set_property IOSTANDARD LVCMOS33 [get_ports xClk]

set_property PACKAGE_PIN G19  [get_ports {vgaRed[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]

set_property PACKAGE_PIN H19  [get_ports {vgaRed[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]

set_property PACKAGE_PIN J19  [get_ports {vgaRed[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]

set_property PACKAGE_PIN N19  [get_ports {vgaRed[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]

set_property PACKAGE_PIN J17  [get_ports {vgaGreen[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]

set_property PACKAGE_PIN H17  [get_ports {vgaGreen[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]

set_property PACKAGE_PIN G17  [get_ports {vgaGreen[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]

set_property PACKAGE_PIN D17  [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]

set_property PACKAGE_PIN N18  [get_ports {vgaBlue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]

set_property PACKAGE_PIN L18  [get_ports {vgaBlue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]

set_property PACKAGE_PIN K18  [get_ports {vgaBlue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]

set_property PACKAGE_PIN J18  [get_ports {vgaBlue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]

set_property PACKAGE_PIN P19  [get_ports vgaHs]
set_property IOSTANDARD LVCMOS33 [get_ports vgaHs]

set_property PACKAGE_PIN R19  [get_ports vgaVs]
set_property IOSTANDARD LVCMOS33 [get_ports vgaVs]

set_property PACKAGE_PIN V17  [get_ports {switch[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[0]}]
set_property PACKAGE_PIN V16  [get_ports {switch[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[1]}]
set_property PACKAGE_PIN W16  [get_ports {switch[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[2]}]
set_property PACKAGE_PIN W17  [get_ports {switch[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[3]}]
set_property PACKAGE_PIN W15  [get_ports {switch[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[4]}]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
