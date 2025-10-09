import pickle
import nannyml as nml
import pandas as pd
import numpy as np
from typing import Dict, Optional, List
from cbpe_esitmator import ModelPerformanceMonitor

reference_df = pd.read_pickle('/home/scalesagx/Scales-ML/nannyml/ref_df')
analysis_df = pd.read_pickle('/home/scalesagx/Scales-ML/nannyml/analysis_df')

# Initialize monitor
monitor = ModelPerformanceMonitor(
    n_classes=100,
    metrics=['accuracy'],
    problem_type="classification_multiclass"
)

# Run monitoring
reference_df, analysis_df, results = monitor.monitor_performance(reference_df, analysis_df)

# Get performance summary
summary = monitor.get_performance_summary(results)