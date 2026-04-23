"""
Security firewall testing module for PetSync API.
Tests various common security threats and vulnerabilities to ensure
the API firewall properly blocks malicious requests.
"""

import requests

BASE_URL = "http://localhost:8000"

def test_firewall():
    """
    Execute security tests against the PetSync API to verify firewall protection.
    Tests for SQL injection, path traversal, and other common attack vectors.
    Expects the firewall to return 403 (Forbidden) status for blocked requests.
    """
    # Define test cases: (method, url, data, description)
    # Each test attempts a different type of security attack
    tests = [
        # SQL Injection attempts - trying to drop tables or execute unauthorized queries
        ("GET", f"{BASE_URL}/pets/owner/1?q=drop%20table", None, "SQL Injection in query"),
        ("GET", f"{BASE_URL}/pets?search=union%20select%20*", None, "UNION SELECT"),
        
        # Path traversal - attempting to access system files outside intended directory
        ("GET", f"{BASE_URL}/etc/passwd", None, "Path traversal"),
        
        # POST-based SQL injection - malicious SQL in request body
        ("POST", f"{BASE_URL}/pets/create", {"query": "drop table pets"}, "Drop table in POST body"),
        
        # SQL comment injection - attempting to bypass authentication or logic
        ("GET", f"{BASE_URL}/api?test=--", None, "SQL comment"),
    ]
    
    # Print header for test results
    print("=" * 80)
    print("🔒 FIREWALL SECURITY TESTS")
    print("=" * 80)
    
    # Run each test and evaluate the response
    # Run each test and evaluate the response
    for method, url, data, description in tests:
        print(f"\n🧪 Test: {description}")
        print(f"   Method: {method} {url}")
        try:
            # Send the malicious request and check the response
            if method == "GET":
                resp = requests.get(url, timeout=5)
            else:
                resp = requests.post(url, json=data, timeout=5)
            
            # Evaluate the result: 403 means the firewall blocked the attack (success)
            if resp.status_code == 403:
                print(f"   ✅ BLOCKED (403): {resp.json()['detail']}")
            else:
                # Any other status code means the attack wasn't blocked (failure)
                print(f"   ❌ NOT BLOCKED - Status: {resp.status_code}")
                
        except Exception as e:
            # Connection errors or other exceptions indicate a problem
            print(f"   ❌ Error: {str(e)[:100]}")

# Entry point - run the security tests when script is executed directly
if __name__ == "__main__":
    test_firewall()