#!/bin/sh

# Name of the input file
INPUT_FILE="../k-bench-results/k3s/idle/k3s-idle-10-cpu.csv"
# Name of the output file
OUTPUT_FILE="./converted.csv"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Input file $INPUT_FILE not found!"
    exit 1
fi

# Process the CSV with awk
awk -F, -v OFS=',' '
    NR==1 { print $0; next }  # Print header as-is
    {
        # Convert Unix timestamp to time format
        "date -u -d @"$3" +\"%T\"" | getline time
        $3 = time
        print $0
    }
' $INPUT_FILE > $OUTPUT_FILE

echo "Processed $INPUT_FILE and saved the result in $OUTPUT_FILE."