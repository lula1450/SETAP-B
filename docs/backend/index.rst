Backend Documentation
======================

System Overview
---------------
The SETAP-B backend is a FastAPI application that provides a comprehensive REST API for the PetSync pet management system. 
It includes user authentication, pet profile management, health record tracking, scheduling features, vet contact management
and more. It is respodible for handling requests from the frontend, prcessing application logic and managing data storage. 
The backend follows a layered architecture consisting of an API layer built with FastAPI, a servie layer that handles the 
main application logic and a data layer using SQLAlchemy for database interactions. Data is stored in the database using 
SQLite. This structure of the backend ensures that the system is scalable which allows for efficient communication between
the application and the database.

Purpose
-------
The purpose of the backend is to power the PetSync platform by providing secure and reliable services for managing pets, 
owners, health records, scheduling, and related data. It acts as the bridge between the frontend and the database, ensuring 
that all operations are processed effeciently and consistently.

Responsibilities
----------------
- Handling API requests from the frontend
- Processing application logic and rules
- Managing storage and retreival of data from the database
- Providing user authentication and authorization
- Generating reports and analytics based on pet health data

System Architecture
-------------------
The backend uses layered architecture to sesperate the responsibilities and improve organisation of the code.

1. API Layer 
   - Defines routes and endpoints using FastAPI
   - Handling request validation
   - Returns JSON responses to the frontend
2. Service Layer 
   - Main Business logic implementation
   - Coordinates operations between API and the database
   - Applies rules such as reminders, scheduling checks, and validation
3. Data Layer 
   - Uses SQLAlchemy ORM for database communication and data storage.
   - Maintains relationships between users, pets, records, and scheduling.

Key Features
~~~~~~~~~~~~
- User authentication and authorization
- Pet profile management
- Health record tracking
- Feeding schedule management
- Health reports and analytics
- Veterinarian contact management
- Database persistence with SQLite

Tech Stack
~~~~~~~~~~
- FastAPI --> High performance Python web framework
- SQLAlchemy --> Used for database operations
- SQLite --> Relational database
- Pydantic --> Data validation and serialization
- Uvicorn --> ASGI server for running the application
- Python --> Core/Base programming language

API Reference
--------------
.. toctree::
   :maxdepth: 2

   overview
   models
   database

