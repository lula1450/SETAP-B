import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_firewall.py -vv
"""

transport = ASGITransport(app=app)


# --- SQL Injection Tests ---

@pytest.mark.asyncio
async def test_sql_injection_in_query_param():
    """SQL injection via query parameter is blocked by the firewall."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/owner/1?q=drop%20table")
        assert response.status_code == 403
        assert "detail" in response.json()


@pytest.mark.asyncio
async def test_union_select_injection():
    """UNION SELECT injection attempt in query string is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets?search=union%20select%20*")
        assert response.status_code == 403
        assert "detail" in response.json()


@pytest.mark.asyncio
async def test_sql_injection_in_post_body():
    """SQL injection via POST request body is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/pets/create", json={"query": "drop table pets"})
        assert response.status_code == 403
        assert "detail" in response.json()


@pytest.mark.asyncio
async def test_sql_comment_injection():
    """SQL comment injection attempt in query string is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/api?test=--")
        assert response.status_code == 403
        assert "detail" in response.json()


# --- Path Traversal Tests ---

@pytest.mark.asyncio
async def test_path_traversal_etc_passwd():
    """Attempt to access /etc/passwd via path traversal is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/etc/passwd")
        assert response.status_code == 403
        assert "detail" in response.json()


@pytest.mark.asyncio
async def test_path_traversal_with_dots():
    """Directory traversal using ../ sequences is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/../../etc/passwd")
        assert response.status_code == 403
        assert "detail" in response.json()


# --- Clean Request Tests ---

@pytest.mark.asyncio
async def test_normal_request_not_blocked():
    """A normal clean request is not blocked by the firewall."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/1")
        assert response.status_code != 403


@pytest.mark.asyncio
async def test_normal_owner_request_not_blocked():
    """A legitimate owner request passes through the firewall."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/owners/1")
        assert response.status_code != 403