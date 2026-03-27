# petsync_backend/calculations.py
import pandas as pd

def check_15_percent_deviation(historical_values: list, new_value: float):
    """
    Analyzes health trends to see if a new entry is a statistical outlier.
    Returns: (is_risk: bool, baseline_mean: float)
    """
    # Requirement: We need a baseline to compare against. 
    # If there are fewer than 2 previous entries, we establish the current as baseline.
    if not historical_values or len(historical_values) < 2:
        return False, new_value

    # Convert to Pandas Series for calculation
    series = pd.Series(historical_values)
    baseline_mean = series.mean()

    if baseline_mean == 0:
        return False, 0.0

    # Calculate percentage difference (catching both sudden drops and spikes)
    percentage_diff = abs(new_value - baseline_mean) / baseline_mean

    # Flag as risk if change is > 15% (SR 4.1)
    is_risk = percentage_diff > 0.15

    return is_risk, float(baseline_mean)

def calculate_daily_mean(metric_data: list):
    """
    Helper to aggregate multiple daily logs into one average for the dashboard.
    """
    if not metric_data:
        return 0.0
    df = pd.DataFrame(metric_data)
    return float(df['value'].mean())