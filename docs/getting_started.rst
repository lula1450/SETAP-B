Getting Started
===============

Installation
------------

Backend Setup
~~~~~~~~~~~~~

1. Clone the repository:

   .. code-block:: bash

      git clone https://github.com/lula1450/SETAP-B.git
      cd SETAP-B

2. Create a virtual environment:

   .. code-block:: bash

      cd petsync_backend
      python3 -m venv venv
      source venv/bin/activate

3. Install dependencies:

   .. code-block:: bash

      pip install -r requirement.txt

4. Run the backend server:

   .. code-block:: bash

      python main.py

Frontend Setup
~~~~~~~~~~~~~~

1. Navigate to the frontend directory:

   .. code-block:: bash

      cd frontend/maincode

2. Install Flutter dependencies:

   .. code-block:: bash

      flutter pub get

3. Run the application:

   .. code-block:: bash

      # iOS
      flutter run -d ios

      # Android
      flutter run -d android

Project Structure
-----------------

::

   SETAP-B/
   ├── petsync_backend/          # Python FastAPI backend
   │   ├── main.py
   │   ├── models.py
   │   ├── database.py
   │   ├── routers/              # API endpoints
   │   └── utils/
   ├── frontend/maincode/        # Flutter mobile app
   │   ├── lib/                  # Dart source files
   │   ├── android/
   │   ├── ios/
   │   └── pubspec.yaml
   └── docs/                     # Documentation
