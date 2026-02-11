import pandas as pd # for statistical analysis

# threshold check for alerts and reporting engine
def check_15_percent_deviation(historical_values: list, new_value: float):

    if len(historical_values) < 3:

        # returns current average but keeps risk_flag false until enough data is collected
        current_avg = sum(historical_values) / len(historical_values) if historical_values else 0.0 # prevents errors if no historical data exists
        return False, current_avg

    # series = array with any data type
    series = pd.Series(historical_values) # converts historical values quickly
    
    baseline_mean = series.mean() # calculates average of health metric over period of time

    # abs = ensures the result is always a positive number
    # SR 4.1
    percentage_diff = abs(new_value - baseline_mean) / baseline_mean

    is_risk = percentage_diff > 0.15

    return is_risk, baseline_mean


def calculate_daily_mean(metric_data: list):

    if not metric_data:
        return 0.0 # ensures the presentation layer doesn't crash when a new pet dashboard is created

    # converts pyhton dictionary into pandas dataframe
    df = pd.DataFrame(metric_data) # dataframe = table
    # aggregates metrics into daily average for the dashboard aggregator

    return df['value'].mean() # calculates the mean on 'value'