# #!/bin/sh

# Agg_throughput=0;

# throughput=`cat ../k-bench-results/**/dp_redis_density/dp_redis_density-*/memtier.out  | grep "Totals" | awk {'print $2'}`
# echo "Throughput of pod $num is $throughput";
# Agg_throughput=`echo "$throughput + $Agg_throughput" | bc`
# echo "Aggregate throughput = $Agg_throughput";



import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


def get_metrics(file_path):
    ops_sec = []
    latency = []
    with open(file_path, 'r') as file:
        # Read the file line by line
        for line in file:
            # Check if the line contains 'Totals'
            if 'Totals' in line:
                # Split the line into columns
                columns = line.split()
                # Check if there are at least two columns
                if len(columns) >= 2:
                    # Append the second column value to the list
                    ops_sec.append(float(columns[1]))
                    latency.append(float(columns[4]))
    return ops_sec, latency

def create_plots(files, title, xlabel, ylabel, toSave=False, plot_type='scatter'):
    all_data = []

    for file in files:
        path_components = file.split('/')
        dist = path_components[2]
        # data is DataFrame
        data = pd.DataFrame()
        data['ops_sec'], data['latency'] = get_metrics(file)
        data['dist'] = dist
        all_data.append(data)
    # print(all_data)
    combined_data = pd.concat(all_data, ignore_index=True)

    plt.figure(figsize=(6, 6))
    colors = ['b', 'r', 'g', 'm', 'y']
    if plot_type == 'latency':
        sns.boxplot(data=combined_data, x='dist', y='latency', palette=colors)
    elif plot_type == 'ops_sec':
        sns.boxplot(data=combined_data, x='dist', y='ops_sec', palette=colors)
    plt.title(f'{title}')
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)

    if toSave:
        snake_title = title.replace(' ', '_').lower()
        file_name = f'{snake_title}.pdf'
        plt.savefig(f'../diagrams/{file_name}', format='pdf')
    else:
        plt.show()
    



toSave = True
distributions = ['k0s', 'k3s', 'k8s', 'kubeEdge', 'openYurt']
files = []
for dist in distributions:
    for i in range(1, 5):
        files.append(f'../k-bench-results/{dist}/dp_redis_density/dp_redis_density-{i}/memtier.out')
create_plots(files, 'Data plane - Latency', 'Distributions', 'Avg Latency (ms)', toSave, 'latency')
# create_plots(files, 'Data plane - Throughput', 'Distributions', 'Throughput operations (Ops/sec)', toSave, 'ops_sec')