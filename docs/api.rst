Application Programming Interface (API) Documentation
=================

Backend API
-----------
The SETAP-B backend uses FastAPI to provide RESTful API endpoints for managing
application data and frontend communication.

The API supports:
- User authentication
- Pet profile management
- Health record tracking
- Feeding schedules
- Report generation
- Owner account management

Main Route Groups
-----------------
Authentication
~~~~~~~~~~~~~~
Routes under:
::

   /auth

Used for:
- User login
- User registration
- Authentication tasks

Pets
~~~~
Routes under:
::

   /pets

Used for:
- Create pets
- View pet profiles
- Update pet details
- Delete pets

Health
~~~~~~
Routes under:
::

   /health

Used for:
- Store health records
- Track metrics
- View pet health history

Schedule
~~~~~~~~
Routes under:
::

   /schedule

Used for:
- Feeding schedules
- Appointment reminders
- Scheduled events

Reports
~~~~~~~
Routes under:
::

   /reports

Used for:

- Generate reports
- View historical reports
- Health analytics

Owners
~~~~~~
Routes under:
::

   /owners

Used for:

- Owner profile management
- Account deletion requests
- Owner account operations

Additional Routes
-----------------
Root Endpoint:
::

   /

Returns confirmation that the API is running.

Middleware
----------
The backend also includes:

- Custom PetSyncFirewall security middleware
- CORS middleware for frontend communication

Interactive API Docs
--------------------
When running locally, FastAPI automatically provides documentation at:
::

   /docs

and

::

   /redoc