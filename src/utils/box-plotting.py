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

def box_plotting(all_data, title, xlabel, ylabel, toSave=False):
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
        sns.boxplot(data=host_data, x='minutes', y='value', hue='dist')
        plt.title(f'{title} for {host}')
        plt.xlabel(xlabel)
        plt.ylabel(ylabel)
        plt.legend(title='Distribution')

        if toSave:
            snake_title = title.replace(' ', '_').lower()
            file_name = f'{snake_title}_for_{host}.png'
            plt.savefig(f'../diagrams/{file_name}')
        else:
            plt.show()

def line_plotting(all_data, title, xlabel, ylabel, toSave=False):
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
            plt.savefig(f'../diagrams/{file_name}')
        else:
            plt.show()

def create_plots(files, title, xlabel, ylabel, toSave=False, plot_type='scatter'):
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
        path_components = file.split('/')
        dist = path_components[2]
        unit = path_components[-1].split('-')[-1].split('.')[0]
        data = pd.read_csv(file)
        data['timestamp'] = pd.to_datetime(data['timestamp'], unit='s')
        if unit == 'cpu':
            data['value'] = 100 - data['value']
        min_timestamp = data['timestamp'].min()
        data['timestamp'] -= min_timestamp
        data['minutes'] = (data['timestamp'].dt.total_seconds() / 60).round().astype(int)
        data['dist'] = dist
        all_data.append(data)

    if plot_type == 'box':
        box_plotting(all_data, title, xlabel, ylabel, toSave)
    elif plot_type == 'line':
        line_plotting(all_data, title, xlabel, ylabel, toSave)
    else:
        scatter_plots_with_trend_lines(all_data, title, xlabel, ylabel, toSave)
    

toSave = False
distributions = ['k3s', 'k8s', 'k0s', 'kubeEdge']
testCases = ['idle', 'cp_heavy_12client', 'cp_heavy_8client', 'dp_redis_density']
metrics = ['cpu'] #, 'ram', 'net', 'disk'] # TODO: think how to present net and disk.
files = []
def create_plots_time_series(plot_type='scatter'):
    for unit in metrics:
        for test in testCases:
            for dist in distributions:
                for i in range(1, 5):
                    files.append(f'../k-bench-results/{dist}/{test}/{test}-{i}/{test}-{i}-{unit}.csv')
            create_plots(files, f'{dist} - {test}', 'Minutes', 'Value (%)', toSave, plot_type)

create_plots_time_series('line')