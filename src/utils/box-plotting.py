import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def scatter_plots_with_trend_lines(all_data, title, xlabel, ylabel, toSave=False):
    combined_data = pd.concat(all_data, ignore_index=True)
    hosts = combined_data['hostname'].unique()

    for host in hosts:
        plt.figure(figsize=(15, 8))
        host_data = combined_data[combined_data['hostname'] == host]
        
        # Plot scatter with trend lines for each distribution
        for dist in host_data['dist'].unique():
            dist_data = host_data[host_data['dist'] == dist]
            sns.regplot(data=dist_data, x='minutes', y='value', scatter_kws={'s': 20, 'alpha': 0.5}, line_kws={'label': dist}, ci=None)

        plt.title(f'{title} for {host}')
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.legend(title='Distribution')

        if toSave:
            snake_title = title.replace(' ', '_').lower()
            file_name = f'{snake_title}_for_{host}.png'
            plt.savefig(file_name)
        else:
            plt.show()

# TODO: remove outliers and check
def box_plotting(all_data, title, xlabel, ylabel, toSave=False, unit='', showfliers=False):
    """
    Create and save or display box plots for given data files.

    Args:
    all_data (list): A list of dataframes.
    title (str): The title for the plots.
    xlabel (str): The label for the x-axis.
    ylabel (str): The label for the y-axis.
    toSave (bool): If True, save the plots instead of displaying them.
    """
    combined_data = pd.concat(all_data, ignore_index=True)
    hosts = combined_data['hostname'].unique()

    for host in hosts:
        host_data = combined_data[combined_data['hostname'] == host]
        plt.figure(figsize=(15, 8))
        sns.boxplot(data=host_data, x='minutes', y='value', hue='dist', showfliers=showfliers)
        plt.title(f'{title} for {host}')
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.legend(title='Distribution')

        if toSave:
            snake_title = title.replace(' ', '_').lower()
            file_name = f'{snake_title}_for_{host}.png'
            sub_dir = 'box' if showfliers == True else 'box-without-fliers'
            plt.savefig(f'../diagrams/results/{sub_dir}/{unit}/{file_name}')
        else:
            plt.show()

def line_plotting(all_data, title, xlabel, ylabel, toSave=False, unit=''):
    """
    Create and save or display line plots for given data files.

    Args:
    all_data (list): A list of dataframes.
    title (str): The title for the plots.
    xlabel (str): The label for the x-axis.
    ylabel (str): The label for the y-axis.
    toSave (bool): If True, save the plots instead of displaying them.
    """
    combined_data = pd.concat(all_data, ignore_index=True)
    hosts = combined_data['hostname'].unique()

    for host in hosts:
        host_data = combined_data[combined_data['hostname'] == host]
        plt.figure(figsize=(15, 8))
        sns.lineplot(data=host_data, x='minutes', y='value', hue='dist')
        plt.title(f'{title} for {host}')
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.legend(title='Distribution')

        if toSave:
            snake_title = title.replace(' ', '_').lower()
            file_name = f'{snake_title}_for_{host}.png'
            plt.savefig(f'../diagrams/results/line/{unit}/{file_name}')
        else:
            plt.show()

def create_plots(files, title, xlabel, ylabel, toSave=False, plot_type='scatter', workersOnly=False):
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
    unit = ''
    for file in files:
        path_components = file.split('/')
        dist = path_components[2]
        unit = path_components[-1].split('-')[-1].split('.')[0]
        data = pd.read_csv(file)

        if workersOnly:
            data = data[data['hostname'].str.match('^node_.*')].copy()
            # Assign 'worker' to the 'hostname' column for the remaining data
            data['hostname'] = 'worker'

        data['timestamp'] = pd.to_datetime(data['timestamp'], unit='s')


        if unit == 'cpu':
            data['value'] = 100 - data['value']

        if unit == 'net':
            # Ensure 'value' is positive for all rows, assuming negative values indicate outgoing data
            data['value'] = data['value'].abs()
            # Group by 'hostname' and 'timestamp' to calculate total traffic (sum of InOctets and OutOctets)
            data_grouped = data.groupby(['hostname', 'timestamp']).agg(TotalTraffic=('value', 'sum')).reset_index()

            # Replace the original 'data' DataFrame with the grouped one
            data = data_grouped
            data['value'] = data['TotalTraffic'] / 1024  # Convert bytes to kilobytes
        

        min_timestamp = data['timestamp'].min()
        data['timestamp'] -= min_timestamp
        data['minutes'] = (data['timestamp'].dt.total_seconds() / 60).round().astype(int)
        data['dist'] = dist
        all_data.append(data)

    if plot_type == 'box':
        box_plotting(all_data, title, xlabel, ylabel, toSave, unit, showfliers=False)
    elif plot_type == 'line':
        line_plotting(all_data, title, xlabel, ylabel, toSave, unit)
    else:
        scatter_plots_with_trend_lines(all_data, title, xlabel, ylabel, toSave, unit)
    

toSave = True
distributions = ['k3s', 'k8s', 'k0s', 'kubeEdge', 'openYurt']
testCases = ['idle', 'cp_light_1client', 'cp_heavy_8client', 'cp_heavy_12client', 'dp_redis_density'] # TODO: reliability tests needs different plotting
metrics = ['disk'] #'cpu', 'ram', 'net', 'disk'] # TODO: think how to present net and disk. # TOOD: ram should be in percentage (though 64gb and 4Gb are different, but percentage is more meaningful)
files = []
def create_plots_time_series(plot_type='scatter'):
    for unit in metrics:
        for test in testCases:
            for dist in distributions:
                for i in range(2, 5):
                    files.append(f'../k-bench-results/{dist}/{test}/{test}-{i}/{test}-{i}-{unit}.csv')
            create_plots(files, f'{test}', 'Minutes', 'Disk Usage (%)', toSave, plot_type, True)
            #create_plots(files, f'{test}', 'Minutes', 'Memory Usage (Mb)', toSave, plot_type, True)
            #create_plots(files, f'{test}', 'Minutes', 'Network load (kB)', toSave, plot_type, False)
            #create_plots(files, f'{test}', 'Minutes', 'Network load (kB)', toSave, plot_type)

create_plots_time_series('line')