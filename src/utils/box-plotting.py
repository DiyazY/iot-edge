# TODO: WIP - add more details to the chart itself and learn how to save an image as a file
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# File paths of your test runs
files = ['../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-1-cpu.csv', '../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-3-cpu.csv', '../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-4-cpu.csv']

# List to hold data from all files
all_data = []

for file in files:
    # Read the file
    data = pd.read_csv(file)
    print(f"\nInitial data from {file}:")
    print(data.tail())  # Print the first few rows of the initial data

    # Convert timestamps to datetime and align to start from 0
    data['timestamp'] = pd.to_datetime(data['timestamp'], unit='s')
    min_timestamp = data['timestamp'].min()
    data['timestamp'] -= min_timestamp

    print(f"\nData from {file} after timestamp normalization")
    print(data.tail())  # Print the first few rows after transformation

    # Convert timestamp to minutes and convert to integer
    data['minutes'] = (data['timestamp'].dt.total_seconds() / 60).round().astype(int)

    print(f"\nData from {file} after timestamp normalization and conversion to minutes:")
    print(data.tail())  # Print the first few rows after transformation

    # Append to the list
    all_data.append(data)

# Combine all data into a single DataFrame
combined_data = pd.concat(all_data, ignore_index=True)

# Get unique hostnames
hosts = combined_data['hostname'].unique()

# Create a separate plot for each host
for host in hosts:
    host_data = combined_data[combined_data['hostname'] == host]
    plt.figure(figsize=(15, 8))
    sns.boxplot(data=host_data, x='minutes', y='value')
    plt.title(f'Box Plot of Values Over Time by Minutes for {host}')
    plt.xlabel('Time (minutes)')
    plt.ylabel('Value')
    plt.show()