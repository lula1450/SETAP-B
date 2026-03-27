import pytest
from petsync_backend.calculations import check_15_percent_deviation

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_calculations.py -vv

"""

def test_deviation_low_data():
    """Requirement: If only 1 historical entry exists, do not flag risk."""
    is_risk, baseline = check_15_percent_deviation([10.0], 12.0)
    assert is_risk is False
    assert baseline == 12.0

def test_no_deviation():
    """Verifies stable health data remains 'Green'."""
    is_risk, baseline = check_15_percent_deviation([10.0, 10.0], 10.0)
    # Change 'is' to '=='
    assert is_risk == False 

def test_significant_spike_deviation():
    """Verifies a >15% spike triggers a risk flag."""
    is_risk, baseline = check_15_percent_deviation([10.0, 10.0, 10.0], 12.1)
    # Change 'is' to '=='
    assert is_risk == True

def test_significant_drop_deviation():
    """Verifies a >15% drop triggers a risk flag."""
    is_risk, baseline = check_15_percent_deviation([10.0, 10.0, 10.0], 7.9)
    # Change 'is' to '=='
    assert is_risk == True

def test_division_by_zero_safety():
    """Ensures the code doesn't crash if the data contains zeros."""
    is_risk, baseline = check_15_percent_deviation([0.0, 0.0], 5.0)
    assert is_risk is False
    assert baseline == 0.0