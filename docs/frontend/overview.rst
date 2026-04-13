Overview
========

Flutter Application Structure
------------------------------

The frontend is organized as follows:

::

   lib/
   ├── main.dart                 # Application entry point
   ├── login_page.dart          # User authentication
   ├── register.dart            # User registration
   ├── dashboard.dart           # Main dashboard
   ├── add_pet.dart             # Add pet functionality
   ├── petinfo.dart             # Pet information display
   ├── edit_profile.dart        # Profile editing
   ├── feeding_schedule.dart    # Feeding management
   ├── health_records.dart      # Health tracking
   ├── report.dart              # Report generation
   ├── report_history.dart      # Report history
   ├── metrics.dart             # Health metrics
   ├── vet_contacts.dart        # Vet information
   ├── recentlylogged.dart      # Recently logged activities
   ├── services/                # API and service layer
   └── utils/                   # Utility functions

Screen Organization
~~~~~~~~~~~~~~~~~~~

**Authentication Flow**

- ``login_page.dart`` - Login screen
- ``register.dart`` - Registration screen

**Main Application**

- ``dashboard.dart`` - Main dashboard with pet overview
- ``add_pet.dart`` - Add new pet
- ``petinfo.dart`` - View/manage pet details
- ``edit_profile.dart`` - Edit user profile

**Pet Management**

- ``feeding_schedule.dart`` - View and manage feeding schedules
- ``health_records.dart`` - Track pet health records
- ``metrics.dart`` - View health metrics and charts

**Reports & Contacts**

- ``report.dart`` - Create health reports
- ``report_history.dart`` - View past reports
- ``vet_contacts.dart`` - Manage veterinarian contacts
- ``recentlylogged.dart`` - View recently logged activities
