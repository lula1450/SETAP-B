Middleware
==========

System Overview
---------------
The middleware layer is key as it is responsible for processing incoming requests before they 
reach the backend API routes. It acts as an additional control layer which improves security 
and handles request filtering.

In the backend, custom middleware is used to analyse incoming requests before they reach the 
application or database.

Security Middleware
-------------------
The backend uses custom FastAPI middleware to asses incomming HTTP requests before they
reach API endpoints.
A custom Web Application Firewall (WAF) called ``PetSyncFirewall`` is used to improve 
API security by detecting and blocking suspicious requests.

Purpose
-------
The middleware helps protect the backend from web attacks such as:
- SQL injection attempts
- Path traversal attacks
- Malicious request payloads
- Suspicious query parameters

How it Works
------------
It works by intercepting requests and checks:
- URL path
- Query parameter values
- Request body (POST, PUT, PATCH requests)

If a forbidden pattern is detected, the request will be blocked and a ``403 Forbidden`` response 
is returned.

Blocked Patterns
----------------
- ``union select``
- ``drop table``
- ``truncate``
- ``--``
- ``/etc/passwd``
- ``drop database``

Advantages of Middleware 
------------------------
- Adds an extra layer of security
- Prevents common attacks
- Protects the database
- Help secure public API endpoints

API Reference
-------------
.. toctree::
   :maxdepth: 2

   overview
   models
   database
   middleware