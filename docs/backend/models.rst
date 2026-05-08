Models
======

Database Models
---------------
The backend uses SQLAlchemy ORM to define database tables as python classes. These models represent
the key entities of PetSync system such as owners, pet, health records, schedules, reminders, and 
reports.

Main Models
-----------
1. Owner --> Stores user account informations
2. Pet --> Stores the pet profile details and links to owners account
3. Species_config --> Defines pet species and breed
4. PetMetaData --> Stores additional notes for pets
5. Metric Definition --> Defines health metric for each species
6. Health Metric --> Stores recorded health data for pets
7. PetAppointment --> Manages vet appointments and reminders
8. FeedingSchedule --> Stores feeding schedule for pets
9. Reminder --> Handles notifications for scheduling appointments/feeding reminders/advice reminders..
10. PetGoal --> Tracks pet health goals
11. PetReport --> Stores generated reports and analytics.

Relationships
-------------
The models are linked using Foreign Keys. For example:

- One Owner can have many pets (1-M)
- One Pet can have many health records (1-M)
- One Pet can have many appointments and feeding schedule (1-M)

API Reference
-------------
.. automodule:: petsync_backend.models
   :members:
   :undoc-members:
   :show-inheritance:
