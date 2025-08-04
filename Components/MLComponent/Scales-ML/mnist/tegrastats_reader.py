import subprocess
import time
import csv

def main():
    csv_file = 'tegra.csv'

    try:
        while True:
            with open(csv_file, 'a', newline='') as file:
                writer = csv.writer(file)

                process = subprocess.Popen(['tegrastats'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

                for stdout_line in iter(process.stdout.readline, ''):
                    output = stdout_line.rstrip()

                    output = output.split(' ')

                    ram_usage = output[3]
                    cpu_usage = output[11]
                    
                    cpu_usage = cpu_usage.split(',')
                    cpu_usage = cpu_usage[1:-1]
                    cpu_stats = []

                    for i in range(len(cpu_usage)):
                        index = cpu_usage[i].find('@')
                        usage = cpu_usage[i][0:index]
                        clock = f'{cpu_usage[i][index+1::]}MHz'
                        cpu = (usage, clock)

                        cpu_stats.append(cpu)

                    gpu_usage = output[13]

                    cpu_temp = output[14]
                    board_temp = output[15]
                    soc2_temp = output[16]
                    diode_temp = output[17]
                    soc0_temp = output[18]
                    gpu_temp = output[19]
                    junction_temp = output[20]
                    soc1_temp = output[21]

                    gpu_power = output[23]
                    cpu_power = output[25]
                    system_power = output[27]
                    component_power = output[29]
                    """
                    row = [ram_usage]
                    for stat in cpu_stats:
                        row.append(stat)

                    row.append([gpu_usage, cpu_temp, board_temp, diode_temp, junction_temp, soc0_temp, soc1_temp, soc2_temp, cpu_power, gpu_power, system_power, component_power, full_power])

                    print(row)
                    """
                    print('')
                    print('---------------------------------------------------------')
                    print('Usage: ')
                    print(f'  RAM: {ram_usage}')
                    print('\n  CPU:')

                    for index, stat in enumerate(cpu_stats):
                        print(f'    {index}: {stat[0]} Load - {stat[1]} Clock')

                    print(f'\n  GPU: {gpu_usage} Load')

                    print('Temperature: ')
                    print(f'  CPU: {cpu_temp[4:]}')
                    print(f'  GPU: {gpu_temp[4:]}')
                    print(f'  Board: {board_temp[7:]}')
                    print(f'  Diode: {diode_temp[7:]}')
                    print(f'  Junction: {junction_temp[3:]}')
                    print(f'  SOC0: {soc0_temp[5:]}')
                    print(f'  SOC1: {soc1_temp[5:]}')
                    print(f'  SOC2: {soc2_temp[5:]}')

                    print('Power: ')
                    print(f'  CPU: {cpu_power}')
                    print(f'  GPU: {gpu_power}')
                    print(f'  System: {system_power}')
                    print(f'  Component: {component_power}')

                    cpu_power = cpu_power.split('/')
                    cpu_running = int(cpu_power[0][:-2])
                    cpu_max = int(cpu_power[1][:-2])

                    gpu_power = gpu_power.split('/')
                    gpu_running = int(gpu_power[0][:-2])
                    gpu_max = int(gpu_power[1][:-2])

                    system_power = system_power.split('/')
                    system_running = int(system_power[0][:-2])
                    system_max = int(system_power[1][:-2])

                    component_power = component_power.split('/')
                    component_running = int(component_power[0][:-2])
                    component_max = int(component_power[1][:-2])

                    full_running = cpu_running + gpu_running + system_running + component_running
                    full_max = cpu_max + gpu_max + system_max + component_max

                    full_power = f'{full_running}mW/{full_max}mW'

                    print(f'  Total: {full_power}')

                    

                


    except KeyboardInterrupt:
        if process:
            process.terminate()
        exit()


if __name__ == '__main__':
    main()