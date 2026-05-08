Overview
========

Frontend Structure
------------------
The Flutter frontend is organised using a modular structure inside the ``lib/`` directory. Screens, services, 
widgets, and utility files are separated to improve maintainability, readability, and scalability.

::
   lib/
   ├── main.dart
   ├── screens/
   ├── services/
   ├── utils/
   └── widgets/

Main Directories
----------------
**main.dart**
Applications entry point. Initializes Flutter and launches the main app widgets.

**screens/**
Contains all user-facing pages used throughout the application.

**services/**
Handles backend API communication, HTTP requests, and business logic.

**utils/**
Contains helper methods, constants, and reusable utility functions.

**widgets/**
Reusable custom UI components shared across multiple screens.

Screens
-------

Authentication Screens
~~~~~~~~~~~~~~~~~~~~~~
- ``login_page.dart`` – User login screen
- ``register.dart`` – User registration screen

Core Screens
~~~~~~~~~~~~
- ``dashboard.dart`` – Main dashboard and pet overview
- ``add_pet.dart`` – Add a new pet
- ``petinfo.dart`` – View pet details
- ``edit_profile.dart`` – Edit user profile

Health & Scheduling
~~~~~~~~~~~~~~~~~~~
- ``feeding_schedule.dart`` – Manage feeding plans
- ``health_records.dart`` – Record health entries
- ``metrics.dart`` – View tracked health metrics
- ``notifications.dart`` – View reminders and alerts

Reports & Activity
~~~~~~~~~~~~~~~~~~
- ``report.dart`` – Generate reports
- ``report_history.dart`` – View report history
- ``recentlylogged.dart`` – Recently logged activity
- ``vet_contacts.dart`` – Veterinarian contacts

Architecture Notes
------------------
The frontend follows a screen-based architecture where each page is separated into individual 
Dart files. Shared logic is placed in services, while reusable UI elements are stored in widgets.

This approach improves code reuse and keeps the project clean and organised.