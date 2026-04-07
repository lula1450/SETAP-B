import requests

BASE_URL = "http://localhost:8000"

def test_firewall():
    # Simpler tests with more obvious patterns
    tests = [
        ("GET", f"{BASE_URL}/pets/owner/1?q=drop%20table", None, "SQL Injection in query"),
        ("GET", f"{BASE_URL}/pets?search=union%20select%20*", None, "UNION SELECT"),
        ("GET", f"{BASE_URL}/etc/passwd", None, "Path traversal"),
        ("POST", f"{BASE_URL}/pets/create", {"query": "drop table pets"}, "Drop table in POST body"),
        ("GET", f"{BASE_URL}/api?test=--", None, "SQL comment"),
    ]
    
    print("=" * 80)
    print("🔒 FIREWALL SECURITY TESTS")
    print("=" * 80)
    
    for method, url, data, description in tests:
        print(f"\n🧪 Test: {description}")
        print(f"   Method: {method} {url}")
        try:
            if method == "GET":
                resp = requests.get(url, timeout=5)
            else:
                resp = requests.post(url, json=data, timeout=5)
            
            if resp.status_code == 403:
                print(f"   ✅ BLOCKED (403): {resp.json()['detail']}")
            else:
                print(f"   ❌ NOT BLOCKED - Status: {resp.status_code}")
                
        except Exception as e:
            print(f"   ❌ Error: {str(e)[:100]}")

if __name__ == "__main__":
    test_firewall()

