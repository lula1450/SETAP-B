Backend Documentation
======================

SystemOverview
--------------
The SETAP-B backend is a FastAPI application that provides a comprehensive REST API for the PetSync pet management system. 
It includes user authentication, pet profile management, health record tracking, scheduling features, vet contact management
and more. It is respodible for handling requests from the frontend, prcessing application logic and managing data storage. 
The backend follows a layered architecture consisting of an API layer built with FastAPI, a servie layer that handles the 
main application logic and a data layer using SQLAlchemy for database interactions. Data is stored in the database using 
SQLite. This structure of the backend ensures that the system is scalable which allows for efficient communication between
the application and the database.

Purpose
-------
What the backend does...

Responsibilities
----------------
- Handling API requests from the frontend
- Processing application logic and rules
- Managing storage and retreival of data from the database
- Providing user authentication and authorization
- Generating reports and analytics based on pet health data

Architecture
------------
Layered design explanation...

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
- FastAPI
- SQLAlchemy
- SQLite

API Reference
--------------
.. toctree::
   :maxdepth: 2

   overview
   models
   database

