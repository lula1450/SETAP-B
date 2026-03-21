import requests
import pytest

BASE_URL = "http://127.0.0.1:8000/owners/owners"

@pytest.fixture
def test_owner():
    payload = {
        "owner_first_name": "Test",
        "owner_last_name": "User",
        "owner_email": "pytest_unique@example.com",
        "owner_phone_number": "0000000000",
        "owner_address1": "123 Test St",
        "owner_postcode": "TS1 1ST",
        "owner_city": "London"
    }
    response = requests.post(f"{BASE_URL}/", json=payload)
    
    if response.status_code != 201:
        pytest.fail(f"Fixture Setup Failed: {response.status_code} - {response.text}")
    
    owner_data = response.json()

    yield owner_data  # This provides the owner data to the test

    # 2. Teardown: Clean up after the test is done
    owner_id = owner_data.get("owner_id")
    if owner_id:
        requests.delete(f"{BASE_URL}/{owner_id}")

def test_create_owner():
    payload = {
        "owner_first_name": "New",
        "owner_last_name": "Owner",
        "owner_email": "brand_new@example.com",
        "owner_phone_number": "1111111111",
        "owner_address1": "456 New St",
        "owner_postcode": "NW1 1NW",
        "owner_city": "London"
    }
    response = requests.post(f"{BASE_URL}/", json=payload)
    assert response.status_code == 201
    assert response.json()["owner_first_name"] == "New"

def test_delete_owner(test_owner):
    owner_id = test_owner["owner_id"]
    response = requests.delete(f"{BASE_URL}/{owner_id}")
    assert response.status_code == 200

if __name__ == "__main__":
    new_id = test_create_owner()
    if new_id:
        test_delete_owner(new_id)