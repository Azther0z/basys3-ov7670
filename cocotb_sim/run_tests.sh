#!/bin/bash

# List of modules to test (each has its own directory now)
MODULES=("pulseSync" "filter" "vgaController" "sccbMaster" "cameraCapture" "cameraConfig" "topModule")

echo "Starting cocotb tests for all modules..."

for MOD in "${MODULES[@]}"
do
    echo "----------------------------------------------------"
    echo "Running test for: $MOD"
    echo "----------------------------------------------------"
    
    # Enter the module directory
    cd "$MOD" || continue
    
    # Run cocotb (Makefile is local)
    conda run -n cocotb make
    
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo "✅ $MOD passed"
    else
        echo "❌ $MOD failed"
    fi
    
    # Return to parent directory
    cd ..
done

echo "Tests completed."
