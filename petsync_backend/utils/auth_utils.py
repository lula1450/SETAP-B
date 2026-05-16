from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

_SECRET_KEY = "petsync-dev-secret-change-in-production"
_ALGORITHM = "HS256"
_EXPIRY_DAYS = 30

_security = HTTPBearer()


def create_access_token(owner_id: int) -> str:
    """Creates a signed JWT for the given owner, valid for 30 days. The owner_id is stored in the 'sub' claim."""
    expire = datetime.utcnow() + timedelta(days=_EXPIRY_DAYS)
    return jwt.encode({"sub": str(owner_id), "exp": expire}, _SECRET_KEY, algorithm=_ALGORITHM)


def get_current_owner_id(credentials: HTTPAuthorizationCredentials = Depends(_security)) -> int:
    """
    FastAPI dependency that validates the Bearer JWT from the Authorization header.
    Returns the authenticated owner's ID extracted from the token payload.
    Raises 401 if the token is missing, expired, or invalid.
    """
    try:
        payload = jwt.decode(credentials.credentials, _SECRET_KEY, algorithms=[_ALGORITHM])
        return int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")
