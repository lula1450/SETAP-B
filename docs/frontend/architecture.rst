Architecture
=============

Design Patterns
---------------

The Flutter application follows these design patterns:

- **Screen Separation**: Each screen is a separate Dart file for modularity
- **Service Layer**: API calls are abstracted into services
- **State Management**: Uses Flutter's built-in state management
- **Utility Functions**: Common functionality is extracted into utils

Communication with Backend
--------------------------

The frontend communicates with the FastAPI backend through HTTP requests:

- Base URL: (configured in services)
- Authentication: Token-based (JWT)
- Content Type: JSON

Key Services
~~~~~~~~~~~~

- **Authentication Service**: Handles login and registration
- **Pet Service**: Manages pet data operations
- **Health Service**: Manages health records
- **Schedule Service**: Manages feeding schedules
- **Report Service**: Generates and retrieves reports
