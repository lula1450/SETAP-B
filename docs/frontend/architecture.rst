Architecture
============

Application Design
------------------
The frontend is structured to keep the codebase clean, organised, and easy todevelop further. Different 
parts of the application are separated based on their responsibilities, allowing features to be updated 
without affecting the#entire system.

This approach helps improve code quality and simplifies future maintenance.

Development Approach
--------------------
The frontend was developed using the following principles:

- **Independent Pages**  
  Each page is stored in a separate Dart file to keep features isolated.

- **Logic Separation**  
  Backend requests and processing tasks are separated from the user interface.

- **Reusable Components**  
  Shared interface elements are created once and reused across screens.

- **Helper Modules**  
  Common functions and constants are grouped into utility files.

- **Local State Handling**  
  Flutter's built-in tools are used to refresh screens when data changes.

System Layers
-------------
The frontend can be viewed in the following parts:
- *User Interface* – Screens, forms, navigation, and visual layout
- *Data Access* – Communication with backend endpoints
- *Shared Components* – Buttons, cards, dialogs, and common widgets
- *Support Functions* – Validation, formatting, and helper logic

Backend Connectivity
--------------------
The application exchanges data with the FastAPI backend using HTTP requests.
Information is sent and received in JSON format.

Typical operations include:
- Signing in users
- Loading pet profiles
- Updating health records
- Managing feeding schedules
- Viewing reports and history

Core Functional Modules
-----------------------
Examples of internal modules include:
- *Login Module* – User sign-in and account creation
- *Pet Module* – Manage pet information
- *Health Module* – Store and display health data
- *Schedule Module* – Feeding plans and reminders
- *Report Module* – Create and view summaries

Advantages
----------
- Easier to update features
- Cleaner project structure
- Better code reuse
- Simpler debugging