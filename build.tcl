# Create project
create_project -force basys3_camera ./vivado_project -part xc7a35tcpg236-1

# Add source files
add_files ./src

# Add constraints
add_files -fileset constrs_1 ./constraints/basys3.xdc

# Ensure files are recognized
update_compile_order -fileset sources_1

# Synthesize
synth_design -top top -part xc7a35tcpg236-1

# Implement (Optimize, Place, Route)
opt_design
place_design
route_design

# Generate bitstream
write_bitstream -force ./basys3_camera.bit

# Close
exit
