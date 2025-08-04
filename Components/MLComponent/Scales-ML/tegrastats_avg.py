import pandas as pd
from datetime import datetime

def parse_timestamp(timestamp_str):
    """Parse the timestamp string from the first line of the file."""
    try:
        return datetime.strptime(timestamp_str.strip('"'), '%a %b %d %H:%M:%S UTC %Y')
    except ValueError:
        return None

def calculate_total_power(row):
    """Calculate total power for a single row by summing specified power measurements."""
    power_components = [
        row['VDD_GPU_SOC Current (mW)'],
        row['VDD_CPU_CV Current (mW)'],
        row['VIN_SYS_5V0 Current (mW)'],
        row['VDDQ_VDD2_1V8AO Current (mW)'],
    ]
    return sum(power_components)

def analyze_csv(file_path, columns_to_analyze=None, window_size=None):
    """
    Analyze CSV file and calculate averages for specified columns.
    
    Args:
        file_path (str): Path to the CSV file
        columns_to_analyze (list): List of column names to analyze. If None, analyzes all numeric columns
        window_size (int): Rolling window size for moving averages. If None, calculates overall average only
    
    Returns:
        dict: Dictionary containing analysis results and DataFrame with rolling averages if window_size is specified
    """
    # Read the timestamp from the first line
    with open(file_path, 'r') as f:
        timestamp = parse_timestamp(f.readline())
    
    # Read the CSV data, skipping the timestamp line
    df = pd.read_csv(file_path, skiprows=1)
    
    # Calculate total power for each row
    df['Total Power (mW)'] = df.apply(calculate_total_power, axis=1)
    
    # If no columns specified, use all numeric columns plus the new total power column
    if columns_to_analyze is None:
        columns_to_analyze = df.select_dtypes(include=['float64', 'int64']).columns.tolist()
    else:
        columns_to_analyze = list(columns_to_analyze) + ['Total Power (mW)']
    
    results = {
        'timestamp': timestamp,
        'total_samples': len(df),
        'analysis': {},
        'rolling_averages_df': None
    }
    
    # Create a DataFrame for rolling averages if window_size is specified
    if window_size:
        rolling_averages = pd.DataFrame()
        rolling_averages['Time (mS)'] = df['Time (mS)']
    
    # Analyze each column
    for column in columns_to_analyze:
        if column not in df.columns:
            print(f"Warning: Column '{column}' not found in CSV. Skipping.")
            continue
            
        column_data = df[column].dropna()
        
        # Calculate statistics
        analysis = {
            'mean': column_data.mean(),
            'min': column_data.min(),
            'max': column_data.max(),
            'std': column_data.std()
        }
        
        # Calculate moving averages if window_size is specified
        if window_size:
            rolling_mean = column_data.rolling(window=window_size).mean()
            rolling_averages[f'{column}_rolling_avg'] = rolling_mean
        
        results['analysis'][column] = analysis
    
    # Add rolling averages DataFrame to results if calculated
    if window_size:
        results['rolling_averages_df'] = rolling_averages
    
    return results

def print_results(results):
    """Print the analysis results in a readable format."""
    if results['timestamp']:
        print(f"Timestamp: {results['timestamp']}")
    print(f"Total Samples: {results['total_samples']}\n")
    
    # Print total power stats first
    if 'Total Power (mW)' in results['analysis']:
        power_stats = results['analysis']['Total Power (mW)']
        print("Total Power (mW):")
        print(f"  Mean: {power_stats['mean']:.2f}")
        print(f"  Min:  {power_stats['min']:.2f}")
        print(f"  Max:  {power_stats['max']:.2f}")
        print(f"  Std:  {power_stats['std']:.2f}")
        print()
    
    # Print other columns
    for column, stats in results['analysis'].items():
        if column != 'Total Power (mW)':
            print(f"{column}:")
            print(f"  Mean: {stats['mean']:.2f}")
            print(f"  Min:  {stats['min']:.2f}")
            print(f"  Max:  {stats['max']:.2f}")
            print(f"  Std:  {stats['std']:.2f}")
            print()

def save_results(results, output_file):
    """Save the analysis results to a file."""
    with open(output_file, 'w') as f:
        if results['timestamp']:
            f.write(f"Timestamp: {results['timestamp']}\n")
        f.write(f"Total Samples: {results['total_samples']}\n\n")
        
        # Save total power stats first
        if 'Total Power (mW)' in results['analysis']:
            power_stats = results['analysis']['Total Power (mW)']
            f.write("Total Power (mW):\n")
            f.write(f"  Mean: {power_stats['mean']:.2f}\n")
            f.write(f"  Min:  {power_stats['min']:.2f}\n")
            f.write(f"  Max:  {power_stats['max']:.2f}\n")
            f.write(f"  Std:  {power_stats['std']:.2f}\n")
            f.write("\n")
        
        # Save other columns
        for column, stats in results['analysis'].items():
            if column != 'Total Power (mW)':
                f.write(f"{column}:\n")
                f.write(f"  Mean: {stats['mean']:.2f}\n")
                f.write(f"  Min:  {stats['min']:.2f}\n")
                f.write(f"  Max:  {stats['max']:.2f}\n")
                f.write(f"  Std:  {stats['std']:.2f}\n")
                f.write("\n")

# Example usage
if __name__ == "__main__":
    # Example with power analysis
    columns_of_interest = [
        'Used RAM (MB)',
        'Used GR3D (%)',
        'tboard Temperature (C)',
        'Total RAM (MB)',
        'Total Power (mW)'  # Added new total power column
    ]
    results_with_rolling = analyze_csv(
        file_path='/home/scalesagx/scales-hardware/docs/data/resnet_training_15W.csv',
        columns_to_analyze=columns_of_interest,
        window_size=5
    )
    
    # Print results
    print_results(results_with_rolling)
    
    # Save results to file
    save_results(results_with_rolling, 'analysis_results.txt')
    
    # Access rolling averages DataFrame
    rolling_averages = results_with_rolling['rolling_averages_df']
    if rolling_averages is not None:
        rolling_averages.to_csv('rolling_averages.csv', index=False)