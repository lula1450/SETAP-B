import pytest
from petsync_backend.calculations import check_15_percent_deviation, calculate_daily_mean

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_calculations.py -vv
"""

# --- check_15_percent_deviation ---

def test_deviation_single_entry_no_flag():
    """With only one historical entry, no risk flag is raised."""
    is_risk, baseline = check_15_percent_deviation([10.0], 12.0)
    assert is_risk == False
    assert baseline == 12.0

def test_no_deviation_stable():
    """Stable data with no significant change returns no risk."""
    is_risk, _ = check_15_percent_deviation([10.0, 10.0], 10.0)
    assert is_risk == False

def test_spike_over_15_percent_flagged():
    """A spike greater than 15% triggers a risk flag."""
    is_risk, _ = check_15_percent_deviation([10.0, 10.0, 10.0], 12.1)
    assert is_risk == True

def test_drop_over_15_percent_flagged():
    """A drop greater than 15% triggers a risk flag."""
    is_risk, _ = check_15_percent_deviation([10.0, 10.0, 10.0], 7.9)
    assert is_risk == True

def test_zero_baseline_safe():
    """Zero values in historical data do not cause a crash."""
    is_risk, baseline = check_15_percent_deviation([0.0, 0.0], 5.0)
    assert is_risk == False
    assert baseline == 0.0


# --- calculate_daily_mean ---

def test_daily_mean_empty_returns_zero():
    """Empty metric data returns 0.0."""
    assert calculate_daily_mean([]) == 0.0

def test_daily_mean_single_entry():
    """A single entry returns its own value as the mean."""
    assert calculate_daily_mean([{"value": 50.0}]) == 50.0

def test_daily_mean_multiple_entries():
    """The mean is correctly calculated across multiple entries."""
    result = calculate_daily_mean([{"value": 10.0}, {"value": 20.0}, {"value": 30.0}])
    assert result == 20.0

def test_daily_mean_floats():
    """The mean handles floating point values correctly."""
    result = calculate_daily_mean([{"value": 15.5}, {"value": 24.5}])
    assert result == 20.0