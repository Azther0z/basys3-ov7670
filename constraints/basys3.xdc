# Clock (100MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

# Reset Button (btnC)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# VGA Pins
set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN P19 [get_ports vga_hsync]
set_property PACKAGE_PIN R19 [get_ports vga_vsync]

set_property IOSTANDARD LVCMOS33 [get_ports -filter { NAME =~ "*vga*" }]

# OV7670 Pins (As per Lab Document)
set_property PACKAGE_PIN P17 [get_ports {ov7670_d[0]}]
set_property PACKAGE_PIN N17 [get_ports {ov7670_d[1]}]
set_property PACKAGE_PIN M19 [get_ports {ov7670_d[2]}]
set_property PACKAGE_PIN M18 [get_ports {ov7670_d[3]}]
set_property PACKAGE_PIN L17 [get_ports {ov7670_d[4]}]
set_property PACKAGE_PIN K17 [get_ports {ov7670_d[5]}]
set_property PACKAGE_PIN C16 [get_ports {ov7670_d[6]}]
set_property PACKAGE_PIN B16 [get_ports {ov7670_d[7]}]
set_property PACKAGE_PIN A17 [get_ports ov7670_href]
set_property PACKAGE_PIN A16 [get_ports ov7670_pclk]
set_property PACKAGE_PIN R18 [get_ports ov7670_pwdn]
set_property PACKAGE_PIN P18 [get_ports ov7670_reset]
set_property PACKAGE_PIN A14 [get_ports ov7670_sioc]
set_property PACKAGE_PIN A15 [get_ports ov7670_siod]
set_property PACKAGE_PIN B15 [get_ports ov7670_vsync]
set_property PACKAGE_PIN C15 [get_ports ov7670_xclk]

set_property IOSTANDARD LVCMOS33 [get_ports -filter { NAME =~ "*ov7670*" }]

# Set pullups for I2C (SCCB) pins as required by protocol
set_property PULLUP true [get_ports ov7670_sioc]
set_property PULLUP true [get_ports ov7670_siod]

# Since a PMOD pin is used as a clock, we must tell Vivado to allow it.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ov7670_pclk_IBUF]
