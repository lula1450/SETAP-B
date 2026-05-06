Database Documentation
======================

System Overview
--------
This module provides the necessary functionality for configuring and managing the database for the backend of PetSync. 
It is responisble for initializing the database, managing sessions and providing communication between the application
and the database.

Database Technology
-----------------
The system uses SQLite as the DBMS(Database Management System). SQLite is a lightweight, serverless database engine 
that is ideal for applications that require a simple and efficient database solution. It was selected due to the fact
that it is easy to set up and integrates with SQALchemy which is used for the ORM layer. 

Connection Management
---------------------
The database connection is configured using SQLAlchemy, which provides an ORM layer for interacting wiht the database.
Using SQLAlchemy as an ORM improves maintainablity and allows developers to interact with the database using Python 
objects. It is repsonsile for creating and managing database sessions, ensuring that connections are properly handled 
and closed after use.

During the setup process, all tables get dropped and recreated to ensure a clean state for the database. This is done 
using the `Base.metadata.drop_all()` and `Base.metadata.create_all()` methods provided by SQLAlchemy.

This approach is useful as it ensures that there are no schema mismatches or old data from past runs whcih could 
interfere with the current state of the application. However, this approach would not be suitable for production
environments as it would lead to data loss.

Data Representation
-------------------
The models define the structure of the database tables and act as an interface between the database and the backend 
logic. This allows for the application to interact with stored data using objects rather than raw SQL queries, which 
improves the maintainability of the code.

API Reference
-------------
.. automodule:: petsync_backend.database
   :members:
   :undoc-members:
   :show-inheritance:



