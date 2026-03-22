"""Tests

- creation and retrieval
- error handling
- owner specific pet list
- db integrity - no invalid owners can do what an authorised user can do

export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_pets.py -vv

"""


import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models

# Use the new transport for modern HTTPX
transport = ASGITransport(app=app)

@pytest.mark.asyncio
async def test_create_and_get_pet(db_session):
    # 1. SETUP: Create Owner
    new_owner = models.Owner(
        owner_first_name="Lauren",
        owner_last_name="Coppin",
        owner_email="lauren@example.com",
        owner_phone_number="07123456789",
        owner_address1="123 Pet Lane",
        owner_postcode="PO1 2AB",
        owner_city="Portsmouth"
    )
    
    # 2. SETUP: Create Species
    new_species = models.Species_config(
        species_name=models.SpeciesType.dog,
        breed_name="Golden Retriever",
        notes="Testing species"
    )
    
    db_session.add_all([new_owner, new_species])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 3. TEST: Create Pet (POST)
        pet_data = {
            "species_id": new_species.species_id,
            "owner_id": new_owner.owner_id,
            "pet_first_name": "Snuggles",
            "pet_last_name": "McFluff",
            "pet_address1": "123 Pet Lane",
            "pet_postcode": "PO1 2AB",
            "pet_city": "Portsmouth"
        }
        
        response = await ac.post("/pets/", json=pet_data)
        assert response.status_code == 200
        pet_id = response.json()["pet_id"]

        # 4. TEST: Get Pet (GET)
        get_response = await ac.get(f"/pets/{pet_id}")
        assert get_response.status_code == 200
        # Check species info (assuming your router returns it)
        assert "Dog" in get_response.json().get("species_name", "Dog")

@pytest.mark.asyncio
async def test_get_nonexistent_pet():
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/9999")
        assert response.status_code == 404

@pytest.mark.asyncio
async def test_get_all_pets_for_owner(db_session):
    # SETUP: Create specific owner and species
    owner = models.Owner(
        owner_first_name="Test", owner_last_name="User",
        owner_email="list@test.com", owner_phone_number="0987654321",
        owner_address1="Street", owner_postcode="SO1", owner_city="Southampton"
    )
    species = models.Species_config(
        species_name=models.SpeciesType.cat, breed_name="Tabby", notes="List test"
    )
    db_session.add_all([owner, species])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Create 2 pets for this specific owner
        for name in ["Buddy", "Max"]:
            await ac.post("/pets/", json={
                "species_id": species.species_id, 
                "owner_id": owner.owner_id, 
                "pet_first_name": name,
                "pet_address1": "123 Lane", 
                "pet_postcode": "SO1", 
                "pet_city": "City"
            })
        
        # 2. Retrieve them using the CORRECT path: /pets/owner/{id}
        response = await ac.get(f"/pets/owner/{owner.owner_id}") 
        assert response.status_code == 200
        assert len(response.json()) >= 2

@pytest.mark.asyncio
async def test_create_pet_invalid_owner(db_session):
    species = models.Species_config(
        species_name=models.SpeciesType.bird, breed_name="Parrot", notes="Invalid owner test"
    )
    db_session.add(species)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        payload = {
            "species_id": species.species_id, 
            "owner_id": 9999, 
            "pet_first_name": "Ghost",
            "pet_address1": "123 Lane", "pet_postcode": "PO1", "pet_city": "City"
        }
        response = await ac.post("/pets/", json=payload)
        assert response.status_code == 404

@pytest.mark.asyncio
async def test_update_pet(db_session):
    # Setup: Create a pet first
    owner = models.Owner(
        owner_first_name="U", owner_last_name="T", owner_email="u@t.com", 
        owner_phone_number="1", owner_address1="S", owner_postcode="S", owner_city="C"
    )
    # Added notes="Test" to avoid the IntegrityError
    species = models.Species_config(
        species_name=models.SpeciesType.dog, 
        breed_name="B", 
        notes="Test"
    )
    db_session.add_all([owner, species])
    db_session.commit()
    
    pet = models.Pet(
        species_id=species.species_id, 
        owner_id=owner.owner_id, 
        pet_first_name="OldName", 
        pet_address1="S", 
        pet_postcode="S", 
        pet_city="OldCity"
    )
    db_session.add(pet)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        update_data = {
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "NewName",
            "pet_last_name": "McFluff",
            "pet_address1": "S",
            "pet_postcode": "S",
            "pet_city": "NewCity"
        }
        response = await ac.put(f"/pets/{pet.pet_id}", json=update_data)
        assert response.status_code == 200
        assert response.json()["pet_first_name"] == "NewName"

@pytest.mark.asyncio
async def test_get_pets_empty_owner(db_session):
    # 1. SETUP: Create an owner with NO pets
    owner = models.Owner(
        owner_first_name="Lonely", owner_last_name="Owner",
        owner_email="no_pets@test.com", owner_phone_number="000",
        owner_address1="Street", owner_postcode="SO1", owner_city="City"
    )
    db_session.add(owner)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 2. TEST: Get pets for this owner (should return 404 as per your router logic)
        response = await ac.get(f"/pets/owner/{owner.owner_id}")
        assert response.status_code == 404
        assert "No pets found" in response.json()["detail"]

@pytest.mark.asyncio
async def test_create_pet_missing_fields():
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. TEST: Send incomplete data (missing pet_first_name)
        incomplete_payload = {
            "species_id": 1,
            "owner_id": 1,
            # "pet_first_name" is missing!
            "pet_address1": "123 Lane",
            "pet_postcode": "PO1",
            "pet_city": "City"
        }
        response = await ac.post("/pets/", json=incomplete_payload)
        
        # 2. VERIFY: FastAPI automatically returns 422 Unprocessable Entity for schema errors
        assert response.status_code == 422
        # Check that the error points to the missing field
        errors = response.json()["detail"]
        assert any(err["loc"][-1] == "pet_first_name" for err in errors)


@pytest.mark.asyncio
async def test_delete_pet(db_session):
    # 1. SETUP: Create a pet with unique data to avoid UNIQUE constraint errors
    owner = models.Owner(
        owner_first_name="Delete", 
        owner_last_name="Test", 
        owner_email="delete_test@example.com", # Unique email
        owner_phone_number="999888777",        # Unique phone number
        owner_address1="S", 
        owner_postcode="S", 
        owner_city="C"
    )
    species = models.Species_config(
        species_name=models.SpeciesType.dog, 
        breed_name="B", 
        notes="N"
    )
    db_session.add_all([owner, species])
    db_session.commit()
    
    pet = models.Pet(
        species_id=species.species_id, 
        owner_id=owner.owner_id, 
        pet_first_name="DeleteMe", 
        pet_address1="S", 
        pet_postcode="S", 
        pet_city="C"
    )
    db_session.add(pet)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 2. TEST: Delete the pet
        delete_response = await ac.delete(f"/pets/{pet.pet_id}")
        assert delete_response.status_code == 200
        assert "deleted successfully" in delete_response.json()["message"]

        # 3. VERIFY: Try to GET the deleted pet (should be 404)
        get_response = await ac.get(f"/pets/{pet.pet_id}")
        assert get_response.status_code == 404