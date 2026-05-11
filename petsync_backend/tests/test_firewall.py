"""
Tests for PetSyncFirewall middleware (middleware.py).
Verifies that SQL injection, path traversal, and other attack patterns
are blocked with a 403 before reaching any route handler.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app

transport = ASGITransport(app=app)


@pytest.mark.asyncio
async def test_normal_get_request_is_allowed():
    """Standard requests pass through the firewall unaffected."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/")
        assert response.status_code == 200


@pytest.mark.asyncio
async def test_path_traversal_in_url_is_blocked():
    """/etc/passwd in the URL path returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/etc/passwd")
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_union_select_in_query_param_is_blocked():
    """UNION SELECT in a query parameter value returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/1", params={"filter": "union select password from owners"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_union_select_in_post_body_is_blocked():
    """UNION SELECT in a POST body returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"metric_name": "union select 1,2,3"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_drop_table_in_post_body_is_blocked():
    """DROP TABLE in a POST body returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/auth/login", json={"email": "drop table owners", "password": "x"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_drop_database_in_post_body_is_blocked():
    """DROP DATABASE in a POST body returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"cmd": "drop database petsync"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_truncate_in_post_body_is_blocked():
    """TRUNCATE in a POST body returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"note": "truncate pets"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_sql_comment_injection_in_body_is_blocked():
    """SQL comment sequence (--) in a POST body returns 403."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/auth/login", json={"email": "admin'--", "password": "x"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_blocked_response_has_correct_detail():
    """Blocked requests return the standard firewall error message."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"cmd": "union select 1"})
        assert response.status_code == 403
        assert response.json()["detail"] == "Security Threat Blocked by PetSync Firewall"


@pytest.mark.asyncio
async def test_put_body_is_also_scanned():
    """SQL injection in a PUT body is blocked, not just POST."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.put("/owners/1", json={"owner_email": "x union select password from owners"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_patch_body_is_also_scanned():
    """SQL injection in a PATCH body is blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.patch("/owners/1", json={"owner_email": "x union select password from owners"})
        assert response.status_code == 403


@pytest.mark.asyncio
async def test_attack_pattern_matching_is_case_insensitive():
    """Mixed-case attack patterns (e.g., UNION SELECT) are still blocked."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"cmd": "UNION SELECT secret FROM owners"})
        assert response.status_code == 403
