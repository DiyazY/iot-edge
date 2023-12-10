import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def create_plots(files, title, xlabel, ylabel, toSave=False):
    """
    Create and save or display box plots for given data files.

    Args:
    files (list): A list of file paths to the data files.
    title (str): The title for the plots.
    xlabel (str): The label for the x-axis.
    ylabel (str): The label for the y-axis.
    toSave (bool): If True, save the plots instead of displaying them.
    """
    all_data = []

    for file in files:
        data = pd.read_csv(file)
        data['timestamp'] = pd.to_datetime(data['timestamp'], unit='s')
        min_timestamp = data['timestamp'].min()
        data['timestamp'] -= min_timestamp
        data['minutes'] = (data['timestamp'].dt.total_seconds() / 60).round().astype(int)
        all_data.append(data)

    combined_data = pd.concat(all_data, ignore_index=True)
    hosts = combined_data['hostname'].unique()

    for host in hosts:
        host_data = combined_data[combined_data['hostname'] == host]
        plt.figure(figsize=(15, 8))
        sns.boxplot(data=host_data, x='minutes', y='value')
        plt.title(f'{title} (node name: {host})')
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)

        if toSave:
            snake_title = title.replace(' ', '_').lower()
            file_name = f'{snake_title}_for_{host}.png'
            plt.savefig(f'../diagrams/{file_name}')
        else:
            plt.show()

toSave = False
# Example usage:
files = ['../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-1-cpu.csv', '../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-3-cpu.csv', '../k-bench-results/k3s/cp_heavy_12client/k3s-cp-heavy-12client-4-cpu.csv']
create_plots(files, 'CPU heavy - 12 clients', 'Minutes', 'Value (%)', toSave)

files = ['../k-bench-results/k3s/cp_heavy_8client/k3s-cp-heavy-8client-2-cpu.csv', '../k-bench-results/k3s/cp_heavy_8client/k3s-cp-heavy-8client-3-cpu.csv', '../k-bench-results/k3s/cp_heavy_8client/k3s-cp-heavy-8client-4-cpu.csv']
create_plots(files, 'CPU heavy - 8 clients', 'Minutes', 'Value (%)', toSave)

files = ['../k-bench-results/k3s/dp_redis_density/k3s-dp-redis-density-34/k3s-dp-redis-density-34-cpu.csv', '../k-bench-results/k3s/dp_redis_density/k3s-dp-redis-density-35/k3s-dp-redis-density-35-cpu.csv', '../k-bench-results/k3s/dp_redis_density/k3s-dp-redis-density-36/k3s-dp-redis-density-36-cpu.csv']
create_plots(files, 'Density', 'Minutes', 'Value (%)', toSave)