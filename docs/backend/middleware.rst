Middleware
==========

System Overview
---------------


Security Middleware
-------------------
The backend uses custom FastAPI middleware to asses incomming HTTP requests before they
reach API endpoints.
A custom Web Application Firewall (WAF) called ``PetSyncFirewall`` is used to improve 
API security by detecting and blocking suspicious requests.

Purpose
-------
The middleware

API Reference
-------------
.. toctree::
   :maxdepth: 2

   overview
   models
   database
   middleware