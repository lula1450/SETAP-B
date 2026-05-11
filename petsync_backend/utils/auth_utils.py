from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

_SECRET_KEY = "petsync-dev-secret-change-in-production"
_ALGORITHM = "HS256"
_EXPIRY_DAYS = 30

_security = HTTPBearer()


def create_access_token(owner_id: int) -> str:
    expire = datetime.utcnow() + timedelta(days=_EXPIRY_DAYS)
    return jwt.encode({"sub": str(owner_id), "exp": expire}, _SECRET_KEY, algorithm=_ALGORITHM)


def get_current_owner_id(credentials: HTTPAuthorizationCredentials = Depends(_security)) -> int:
    try:
        payload = jwt.decode(credentials.credentials, _SECRET_KEY, algorithms=[_ALGORITHM])
        return int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired token")
