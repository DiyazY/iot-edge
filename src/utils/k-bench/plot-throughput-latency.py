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
import matplotlib.colors as mcolors
from datetime import datetime
from matplotlib.ticker import FormatStrFormatter

# type,k8s,tests,test-numbers,number-of-pods,metics,value
# pod,k0s,cp_heavy_8client,1,16,throughput,1.9339411
# pod,k0s,cp_heavy_8client,1,16,latency,1.9339411
# deployment,k0s,cp_heavy_8client,1,80,throughput,4.9721656
# deployment,k0s,cp_heavy_8client,1,80,latency,4.9721656
# pod,k0s,cp_heavy_8client,2,16,throughput,2.1950681
# pod,k0s,cp_heavy_8client,2,16,latency,2.1950681

def plot_latency_diagram(file_path, test, saveFile=False):

    all_data = []
    data = pd.read_csv(file_path)

    df = pd.DataFrame(data)

    df = df[df['metics'] == 'throughput']


    df['value'] = df['value'].astype(float)

    # Prepare DataFrame for plotting by melting it
    df_melted = df.melt(id_vars=["type", "k8s", "number-of-pods", "metics"], 
                        value_vars=["value"],
                        var_name="statistic", value_name="value_name")

    print(df_melted)

    colors = ['b', 'r', 'g', 'm', 'y']
    g = sns.FacetGrid(df_melted, col="number-of-pods", height=7, aspect=1, col_wrap=2, sharey=False, sharex=True)
    g.map_dataframe(sns.boxplot, x="k8s", y="value_name", hue="k8s", showfliers=False, palette=colors)
    g.add_legend()
    g.set_titles("{col_name} pods " + f"in {test}")
    g.set_axis_labels("Distributions", "Throughput (pods/min)")

    # Set y-axis step size
    # g.axes[0].yaxis.set_major_locator(plt.MultipleLocator(1))
    # g.axes[0].yaxis.set_minor_locator(plt.MultipleLocator(1000))
    # g.set(yscale='log')

    # Overlay boxplots on bars
    # g.map_dataframe(sns.boxplot, x="type", y="value_name", hue="k8s", showfliers=False, palette=colors)
    # g.ax.set_ylim(bottom=0)
    if saveFile:
        plt.savefig(f'../../diagrams/throughput-latency-statistics/throughput-{test}.pdf', format='pdf')
    else:
        plt.show()


tests=["cp_light_1client", "cp_heavy_8client", "cp_heavy_12client"]

for test in tests:
    plot_latency_diagram(f"../../k-bench-results/throughput-latency-statistics/{test}.csv",test, saveFile=True)