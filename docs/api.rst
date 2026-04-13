API Documentation
==================

Backend API
-----------

The SETAP-B backend is built with FastAPI and provides RESTful APIs for managing:

- **Authentication**: User login and registration
- **Pets**: Pet information and management
- **Health Records**: Pet health tracking
- **Feeding Schedule**: Meal scheduling and tracking
- **Reports**: Health reports and analytics
- **Vet Contacts**: Veterinarian information

Core Modules
~~~~~~~~~~~~

.. autosummary::
   :toctree: modules

   petsync_backend.models
   petsync_backend.database
   petsync_backend.schemas
   petsync_backend.calculations

API Endpoints
~~~~~~~~~~~~~

Authentication
^^^^^^^^^^^^^^^^^^^

.. http:post:: /api/auth/register

   Register a new user.

.. http:post:: /api/auth/login

   Login with username and password.

Pets
^^^^^^^^^^^^^^^^^^^

.. http:get:: /api/pets

   Get all pets for the authenticated user.

.. http:post:: /api/pets

   Create a new pet.

.. http:get:: /api/pets/{pet_id}

   Get pet details.

.. http:put:: /api/pets/{pet_id}

   Update pet information.

Health Records
^^^^^^^^^^^^^^^^^^^

.. http:get:: /api/health/{pet_id}

   Get health records for a pet.

.. http:post:: /api/health/{pet_id}

   Create a new health record.

Feeding Schedule
^^^^^^^^^^^^^^^^^^^

.. http:get:: /api/schedule/{pet_id}

   Get feeding schedule for a pet.

.. http:post:: /api/schedule/{pet_id}

   Create a feeding schedule entry.

For detailed endpoint documentation, see the interactive API docs at ``/docs`` when the backend is running.
