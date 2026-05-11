# Shared mutable state for the test auth override.
# Both conftest.py and individual test files import from here
# to guarantee they reference the same list object.
_current_test_owner_id: list = [None]
