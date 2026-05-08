Screens
=======

System Overview
---------------
The frontend is built arounf multiple screens that allow users to navigate through the main features
of PetSyncs application. Each screen is stored in a seperate dart file to keep the projects modular 
and easy to maintain.

Authentication Screens
----------------------
Login Page
~~~~~~~~~~
``login_page.dart`` is used for user authentication. It allows users to input their information and 
access the application securely.

Main functions:
- User login
- Credential validation
- Navigation to registration page

Register Page
~~~~~~~~~~~~~
``register.dart`` allows new users to create an account.

Main functions:
- Create new account
- Enter user details
- Submit registration data

Main Application Screens
------------------------
Dashboard
~~~~~~~~~
``dashboard.dart`` acts as the central hub of the application.

Main functions:
- Display pet overview
- Quick navigation to features
- Summary of recent activity

Add Pet
~~~~~~~
``add_pet.dart`` allows users to create a new pet profile.

Main functions:
- Enter pet details
- Select species or breed
- Save pet profile

Pet Information
~~~~~~~~~~~~~~~
``petinfo.dart`` displays detailed pet species information.

Main functions:
- View pet profile
- Access pet records
- Open related features

Edit Profile
~~~~~~~~~~~~
``edit_profile.dart`` allows users to update personal account details.

Main functions:
- Change personal details
- Update profile information

Health Management Screens
-------------------------

Health Records
~~~~~~~~~~~~~~
``health_records.dart`` is used to log and view pet health entries.

Main functions:
- Add health logs
- View previous records
- Monitor wellbeing

Metrics
~~~~~~~
``metrics.dart`` displays tracked health measurements.

Main functions:
- View trends
- Show measurements
- Display progress

Feeding Schedule
~~~~~~~~~~~~~~~~
``feeding_schedule.dart`` manages meal planning.

Main functions:
- Set feeding times
- Adjust schedules
- Manage food portions

Reports and Activity
--------------------
Report Generation
~~~~~~~~~~~~~~~~~
``report.dart`` is used to create reports from pet data.

Main functions:

- Generate summaries
- View health insights
- Export results

Report History
~~~~~~~~~~~~~~
``report_history.dart`` stores previously generated report.

Main functions:
- View past reports
- Reopen summaries
- Compare previous data

Recently Logged
~~~~~~~~~~~~~~~
``recentlylogged.dart`` shows recent data logged in by the users.

Main functions:
- Display latest entries
- Quick history review

Support Screens
---------------
Notifications
~~~~~~~~~~~~~
``notifications.dart`` displays alerts and reminders.

Main functions:
- Feeding reminders
- Appointment alerts
- Important updates

Vet Contacts
~~~~~~~~~~~~
``vet_contacts.dart`` stores pet vet information.

Main functions:
- Save clinic contacts
- View phone numbers
- Manage emergency details

Navigation Design
-----------------
The application uses a user-friendly navigation flow that allows users to move between screens efficiently. 
The dashboard acts as the main entry point afterlogin, while additional screens provide focused feature access.

Benefits
--------
- Clear separation of features
- Easier maintenance
- Better user experience
- Scalable screen structure