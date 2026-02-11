# allows the api gateway to handle concurrent requests
from fastapi import FastAPI, HTTPException

# ensures that data entering the user manager or pet manager is typed
from pydantic import BaseModel 

# process historical health data stored in the database
# make comparisons between data entries
import pandas as pd

# validatae that appointments are not set in the past - allows timestamps - chronological order
from datetime import datetime


# pip install - uvicorn - environment to host api - ensures the application layer remains stable

# background dependency
# pip install - python-multipart - allows FastAPI to handle form data and file uploads - HRM from AUTH UI to OSS