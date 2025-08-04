import nannyml as nml
import pandas as pd
import numpy as np
from typing import Dict, Optional, List
import logging

class ModelPerformanceMonitor:
    """
    A class to monitor model performance using NannyML's CBPE estimator.
    Handles multiclass classification monitoring with automated chunking and visualization.
    """
    
    def __init__(
        self,
        n_classes: int = 100,
        chunk_multiplier: int = 2,
        metrics: List[str] = ['accuracy'],
        problem_type: str = "classification_multiclass",
        timestamp_col: str = 'time',
        y_true_col: str = 'y_true',
        y_pred_col: str = 'y_pred'
    ):
        """
        Initialize the monitor with configuration parameters.
        
        Args:
            n_classes: Number of classes in the classification problem
            chunk_multiplier: Multiplier for minimum samples per chunk
            metrics: List of metrics to monitor
            problem_type: Type of ML problem (classification_binary or classification_multiclass)
            timestamp_col: Name of timestamp column
            y_true_col: Name of true label column
            y_pred_col: Name of predicted label column
        """
        self.n_classes = n_classes
        self.chunk_multiplier = chunk_multiplier
        self.metrics = metrics
        self.problem_type = problem_type
        self.timestamp_col = timestamp_col
        self.y_true_col = y_true_col
        self.y_pred_col = y_pred_col
        
        # Initialize logger
        self.logger = logging.getLogger(__name__)
        
        # Create probability column mappings
        self.y_pred_proba = {i: f'pred_proba_{i}' for i in range(n_classes)}
        
        # Initialize estimator as None (will be created during setup)
        self.estimator = None
        
    def validate_data(self, df: pd.DataFrame, is_reference: bool = True) -> bool:
        """
        Validate input dataframe has required columns and format.
        
        Args:
            df: Input dataframe to validate
            is_reference: Whether this is reference data (True) or analysis data (False)
            
        Returns:
            bool: True if validation passes
        """
        required_cols = [self.timestamp_col, self.y_pred_col]
        if is_reference:
            required_cols.append(self.y_true_col)
            
        # Check required columns exist
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            self.logger.error(f"Missing required columns: {missing_cols}")
            return False
            
        # Check probability columns exist
        missing_proba_cols = [
            col for col in self.y_pred_proba.values() 
            if col not in df.columns
        ]
        if missing_proba_cols:
            self.logger.error(f"Missing probability columns: {missing_proba_cols}")
            return False
            
        return True
        
    def setup_estimator(self, reference_df: pd.DataFrame) -> None:
        """
        Set up the CBPE estimator based on reference data characteristics.
        
        Args:
            reference_df: Reference dataset to determine chunking parameters
        """
        # Calculate minimum samples needed per class
        min_samples_per_class = len(reference_df) // self.n_classes
        chunk_size = min_samples_per_class * self.chunk_multiplier
        
        self.estimator = nml.CBPE(
            y_pred_proba=self.y_pred_proba,
            y_pred=self.y_pred_col,
            y_true=self.y_true_col,
            timestamp_column_name=self.timestamp_col,
            metrics=self.metrics,
            problem_type=self.problem_type,
            chunk_size=chunk_size
        )
        
    def calculate_class_distribution(self, df: pd.DataFrame) -> Dict[int, float]:
        """
        Calculate class distribution in the dataset.
        
        Args:
            df: Input dataframe
            
        Returns:
            Dict mapping class labels to their frequencies
        """
        return df[self.y_true_col].value_counts(normalize=True).to_dict()
        
    def monitor_performance(
        self, 
        reference_df: pd.DataFrame, 
        analysis_df: pd.DataFrame
    ) -> tuple[pd.DataFrame, pd.DataFrame, Optional[nml.CBPE]]:
        """
        Monitor model performance using reference and analysis data.
        
        Args:
            reference_df: Reference dataset with ground truth labels
            analysis_df: Analysis dataset to monitor
            
        Returns:
            Tuple containing:
            - Processed reference dataframe
            - Processed analysis dataframe
            - Estimated results from CBPE
        """
        # Validate inputs
        if not self.validate_data(reference_df, is_reference=True):
            raise ValueError("Invalid reference data")
        if not self.validate_data(analysis_df, is_reference=False):
            raise ValueError("Invalid analysis data")
            
        # Setup estimator if not already done
        if self.estimator is None:
            self.setup_estimator(reference_df)
            
        # Calculate and log class distributions
        ref_dist = self.calculate_class_distribution(reference_df)
        self.logger.info("Reference set class distribution:")
        for class_label, freq in ref_dist.items():
            self.logger.info(f"Class {class_label}: {freq:.3f}")
            
        # Fit estimator on reference set and estimate on analysis set
        try:
            self.estimator.fit(reference_df)
            estimated_results = self.estimator.estimate(analysis_df)
            
            # Log performance metrics
            self.logger.info("\nModel Performance Monitoring Results:")
            self.logger.info(f"Reference Set Accuracy: "
                           f"{(reference_df[self.y_pred_col] == reference_df[self.y_true_col]).mean():.3f}")
            
            if self.y_true_col in analysis_df.columns:
                self.logger.info(f"Analysis Set Accuracy: "
                               f"{(analysis_df[self.y_pred_col] == analysis_df[self.y_true_col]).mean():.3f}")
            
            # Generate performance plots
            estimated_results.plot().show()
            
            return reference_df, analysis_df, estimated_results
            
        except Exception as e:
            self.logger.error(f"Error during monitoring: {str(e)}")
            return reference_df, analysis_df, None
            
    def get_performance_summary(self, estimated_results: nml.CBPE) -> Dict:
        """
        Generate a summary of performance monitoring results.
        
        Args:
            estimated_results: Results from CBPE estimation
            
        Returns:
            Dict containing summary statistics
        """
        if estimated_results is None:
            return {"error": "No results available"}
            
        summary = {
            "mean_estimated_performance": estimated_results.estimates.mean().to_dict(),
            "std_estimated_performance": estimated_results.estimates.std().to_dict(),
            "drift_detected": estimated_results.drift_detected if hasattr(estimated_results, 'drift_detected') else None
        }
        
        return summary
    
