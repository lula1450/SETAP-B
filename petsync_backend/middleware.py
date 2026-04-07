"""
PetSync Security Middleware
Web Application Firewall (WAF) for protecting the PetSync API
Blocks common SQL injection, path traversal, and other security threats
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
from urllib.parse import unquote


class PetSyncFirewall(BaseHTTPMiddleware):
    """
    Web Application Firewall (WAF) middleware for PetSync API.
    Protects against SQL injection, path traversal, and other common attacks.
    """
    
    # Security patterns to block
    FORBIDDEN_PATTERNS = [
        "union select",
        "drop table",
        "truncate",
        "--",
        "/etc/passwd",
        "drop database"
    ]
    
    async def dispatch(self, request: Request, call_next):
        """
        Intercept and validate all incoming requests before they reach route handlers.
        Checks request path, query parameters, and body for malicious patterns.
        """
        
        path = request.url.path.lower()
        
        # Build a comprehensive check string from path and all query parameters
        check_parts = [path]
        
        # Get all query parameter values (not keys)
        for key, value in request.query_params.items():
            check_parts.append(unquote(str(value)).lower())
        
        check_string = " ".join(check_parts)
        
        # Debug: Log all requests
        print(f"🔍 [FIREWALL] {request.method} {path} | Check: {check_string[:100]}")
        
        # Check path and query parameters for threats
        if any(pattern in check_string for pattern in self.FORBIDDEN_PATTERNS):
            print(f"🚨 FIREWALL BLOCKED: {request.method} {request.url}")
            print(f"   Check string: {check_string}")
            return JSONResponse(
                status_code=403,
                content={"detail": "Security Threat Blocked by PetSync Firewall"}
            )
        
        # For POST/PUT/PATCH, also check the request body
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()
                body_str = body.decode("utf-8").lower()
                
                # Check body for malicious patterns
                if any(pattern in body_str for pattern in self.FORBIDDEN_PATTERNS):
                    print(f"🚨 FIREWALL BLOCKED (BODY): {request.method} {request.url}")
                    print(f"   Body snippet: {body_str[:100]}")
                    return JSONResponse(
                        status_code=403,
                        content={"detail": "Security Threat Blocked by PetSync Firewall"}
                    )
                
                # Re-create the request body for downstream handlers
                # (reading the body consumes the stream, so we need to restore it)
                async def receive():
                    return {"type": "http.request", "body": body}
                request._receive = receive
                
            except Exception as e:
                print(f"⚠️ Firewall error: {e}")
            
        return await call_next(request)
