import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import math

from matplotlib.patches import Circle, RegularPolygon
from matplotlib.path import Path
from matplotlib.projections import register_projection
from matplotlib.projections.polar import PolarAxes
from matplotlib.spines import Spine
from matplotlib.transforms import Affine2D

# TODO: add some labels for marking of network outage

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
            file_name = f'{snake_title}_for_{host}'
            plt.savefig(file_name, format='pdf')
            # plt.savefig(file_name)
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
            file_name = f'{snake_title}_for_{host}.pdf'
            sub_dir = 'box' if showfliers == True else 'box-without-fliers'
            plt.savefig(f'../diagrams/results/{sub_dir}/{unit}-{file_name}', format='pdf')
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
            file_name = f'{snake_title}_for_{host}.pdf'
            plt.savefig(f'../diagrams/results/line/{unit}-{file_name}', format='pdf')
        else:
            plt.show()

def create_plots(files, title, xlabel, ylabel, toSave=False, plot_type='scatter', uniteWorkers=False, reliabilityTests=False):
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

        if reliabilityTests:
            paths = file.split('/')[:-1]
            filePath = '/'.join(paths) + f'/ansible_output_{dist}_{title}-{paths[-1][-1]}.txt'
            file = open(filePath, 'r')
            first_line = file.readline()
            file.close()
            node_number = first_line.split(' ')[-1].split(':')[0]
            data['hostname'] = data['hostname'].apply(lambda x: 'failed' if x == f'node_{int(node_number)+1}' else 'worker' if 'node' in x else x)
        else:
            if uniteWorkers:
                data['hostname'] = data['hostname'].apply(lambda x: 'worker' if 'node' in x else x)

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
    

toSave = True # saved them manually since it is not worth handling them via code
distributions = ['k3s', 'k8s', 'k0s', 'kubeEdge', 'openYurt']
testCases = ['idle', 'cp_light_1client', 'cp_heavy_8client', 'cp_heavy_12client', 'dp_redis_density', 'reliability-control', 'reliability-control-no-pressure-long', 'reliability-worker', 'reliability-worker-no-pressure-long'] # TODO: reliability tests needs different plotting
metrics = ['cpu', 'ram', 'net', 'disk']
uniteWorkers=True
def create_plots_time_series(plot_type='scatter'):
    for unit in metrics:
        for test in testCases:
            files = [] 
            if 'worker' in test:
                reliabilityTestsForWorker = True
            else:
                reliabilityTestsForWorker = False
            for dist in distributions:
                for i in range(2, 5):
                    files.append(f'../k-bench-results/{dist}/{test}/{test}-{i}/{test}-{i}-{unit}.csv')
            ylabel = 'CPU Usage (%)' if unit == 'cpu' else 'Memory Usage (Mb)' if unit == 'ram' else 'Network load (kB)' if unit == 'net' else 'Disk Usage (%)'
            create_plots(files, f'{test}', 'Minutes', ylabel, toSave, plot_type, uniteWorkers, reliabilityTestsForWorker)

create_plots_time_series('line')




######## spider plots below
def radar_factory(num_vars, frame='circle'):
    """
    Create a radar chart with `num_vars` axes.

    This function creates a RadarAxes projection and registers it.

    Parameters
    ----------
    num_vars : int
        Number of variables for radar chart.
    frame : {'circle', 'polygon'}
        Shape of frame surrounding axes.

    """
    # calculate evenly-spaced axis angles
    theta = np.linspace(0, 2*np.pi, num_vars, endpoint=False)

    class RadarTransform(PolarAxes.PolarTransform):

        def transform_path_non_affine(self, path):
            # Paths with non-unit interpolation steps correspond to gridlines,
            # in which case we force interpolation (to defeat PolarTransform's
            # autoconversion to circular arcs).
            if path._interpolation_steps > 1:
                path = path.interpolated(num_vars)
            return Path(self.transform(path.vertices), path.codes)

    class RadarAxes(PolarAxes):

        name = 'radar'
        PolarTransform = RadarTransform

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            # rotate plot such that the first axis is at the top
            self.set_theta_zero_location('N')

        def fill(self, *args, closed=True, **kwargs):
            """Override fill so that line is closed by default"""
            return super().fill(closed=closed, *args, **kwargs)

        def plot(self, *args, **kwargs):
            """Override plot so that line is closed by default"""
            lines = super().plot(*args, **kwargs)
            for line in lines:
                self._close_line(line)

        def _close_line(self, line):
            x, y = line.get_data()
            # FIXME: markers at x[0], y[0] get doubled-up
            if x[0] != x[-1]:
                x = np.append(x, x[0])
                y = np.append(y, y[0])
                line.set_data(x, y)

        def set_varlabels(self, labels):
            self.set_thetagrids(np.degrees(theta), labels)

        def _gen_axes_patch(self):
            # The Axes patch must be centered at (0.5, 0.5) and of radius 0.5
            # in axes coordinates.
            if frame == 'circle':
                return Circle((0.5, 0.5), 0.5)
            elif frame == 'polygon':
                return RegularPolygon((0.5, 0.5), num_vars,
                                      radius=.5, edgecolor="k")
            else:
                raise ValueError("Unknown value for 'frame': %s" % frame)

        def _gen_axes_spines(self):
            if frame == 'circle':
                return super()._gen_axes_spines()
            elif frame == 'polygon':
                # spine_type must be 'left'/'right'/'top'/'bottom'/'circle'.
                spine = Spine(axes=self,
                              spine_type='circle',
                              path=Path.unit_regular_polygon(num_vars))
                # unit_regular_polygon gives a polygon of radius 1 centered at
                # (0, 0) but we want a polygon of radius 0.5 centered at (0.5,
                # 0.5) in axes coordinates.
                spine.set_transform(Affine2D().scale(.5).translate(.5, .5)
                                    + self.transAxes)
                return {'polar': spine}
            else:
                raise ValueError("Unknown value for 'frame': %s" % frame)

    register_projection(RadarAxes)
    return theta


def return_single_avg_value(files, metric, machine):
    all_data = []
    avg_value = 0
    for file in files:
        data = pd.read_csv(file)
        if metric == 'cpu':
            data['value'] = 100 - data['value']
        if metric == 'net':
            data['value'] = data['value'].abs()
            # Group by 'hostname' and 'timestamp' to calculate total traffic (sum of InOctets and OutOctets)
            data_grouped = data.groupby(['hostname', 'timestamp']).agg(TotalTraffic=('value', 'sum')).reset_index()

            # Replace the original 'data' DataFrame with the grouped one
            data = data_grouped
            data['value'] = data['TotalTraffic'] / 1024  # Convert bytes to kilobytes

        if machine == 'worker':
            data = data[data['hostname'].str.match('^node_.*')].copy()
        else:
            data = data[data['hostname'].str.match('^master$')].copy()       
        all_data.append(data)
    combined_data = pd.concat(all_data, ignore_index=True)
    avg_value = combined_data['value'].mean()
    if (metric == 'ram'):
        if machine == 'worker':
            avg_value =( avg_value * 100) / 4096
        else:
            avg_value  = (avg_value * 100) / 65336
    # if (metric == 'net'):
    #     avg_value = (avg_value * 100) / 3
    return avg_value
    

def prepare_data_set_for_machine(machine):
    data = dict()
    for test in testCases:
        data[test] = dict()
        for dist in distributions:
            data[test][dist] = []
            for metric in metrics:
                files = []
                for i in range(2, 5):
                    files.append(f'../k-bench-results/{dist}/{test}/{test}-{i}/{test}-{i}-{metric}.csv')
                avg = return_single_avg_value(files, metric, machine)
                # print(f'{test} for {dist} and {metric} is {avg}')
                data[test][dist].append(avg)
    return data




def create_spider_plots_for_test_cases(toSave=False):

    data_set = [prepare_data_set_for_machine('master'), prepare_data_set_for_machine('worker')]
    
    N = len(metrics)
    theta = radar_factory(N, frame='polygon')
    spoke_labels = metrics

    fig, axs = plt.subplots(figsize=(10, 35), nrows=len(testCases), ncols=2, # each distribution should be presented as two diagrams: master and worker
                            subplot_kw=dict(projection='radar'))
    fig.subplots_adjust(wspace=0.25, hspace=0.20, top=0.90, bottom=0.05)
    colors = ['b', 'r', 'g', 'm', 'y']

    # I want to have plots a bit far from each other
    fig.tight_layout(pad=3.0)

    for p, data in enumerate(data_set):
        for i, (test, dists) in enumerate(data.items()):
            max_value = 0
            for j, (dist, values) in enumerate(dists.items()):
                # if (i >= 2 or j >= 2):
                #     print(f' i = {i} and j = {j}, test = {test} and dist = {dist}')
                if (len(values) == 0):
                    print(f'No data for {test} and {dist}')
                    continue
                # print(values)
                axs[i, p].plot(theta, values, color=colors[j])
                axs[i, p].fill(theta, values, facecolor=colors[j], alpha=0.5)   
                max_value = max(max_value, max(values)) 
            
            axs[i, p].set_varlabels(spoke_labels)
            noteType = 'Master' if p == 0 else 'Worker'
            axs[i, p].set_title(f'{test} for {noteType} (%)')
            axs[i, p].set_ylim(0, math.ceil(max_value))

    legend = axs[0, 0].legend(distributions, loc=(1.2, .80),
                              labelspacing=0.2, fontsize='small')

    # fig.text(0.5, 0.965, 'Some descriptive title',
    #          horizontalalignment='center', color='black', weight='bold',
    #          size='large')

    if toSave:
            plt.savefig('../diagrams/spider_diagrams.pdf', format='pdf')
    else:
        plt.show()
    
# create_spider_plots_for_test_cases(True)
