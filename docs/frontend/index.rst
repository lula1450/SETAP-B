Frontend Documentation
======================

System Overview
---------------
The frontend of SETAP-B is a cross-platform mobile application developed using Dart and Flutter. 
It provides users with an interactive interface for managing pets, tracking health records, 
creating and viewing schedules, and accessing reports.

Built with a single codebase, the application supports Android, iOS, Web, Windows, Linux, 
and macOS platforms.

The frontend is responsible for presnting the data to users and interacting with the backend API.
It allows pet owners to manage profiles, monitor the pets health, scheduling appointments and 
feeding times, and recieve insights through reports.

The user interface is designed to be responsive, modern, and easy to navigate.

Purpose
-------
The purpose of the frontend is to provide users with a simple and efficient wat to interact with the
backend system through a mobile-friendly iterface. It does this by converting the backend data into 
user-friendly workflows.

Key Features
------------
- User authentication and login
- Pet profile creation and management
- Dashboard with pet overview
- Health records tracking
- Feeding schedule management
- Appointment reminders
- Veterinarian contact management
- Health reports and analytics
- Responsive cross-platform UI
- Backend API integration

Technology Stack
----------------
- Flutter
- Dart
- Material Design
- REST API integration
- Cross-platform deployment

Project Structure
-----------------

The frontend source code is mainly organised inside the ``lib`` folder:

- ``screens`` – Application pages and views
- ``services`` – API calls and business logic
- ``utils`` – Helper functions and utilities
- ``widgets`` – Reusable UI components
- ``main.dart`` – Application entry point

API Reference
-------------
.. toctree::
   :maxdepth: 2

   overview
   architecture
   screens
   widgets
   services