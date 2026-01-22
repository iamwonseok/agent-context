"""Py-08-01: Functions do one thing only (FAIL)"""

import json


def process_user_data(user_id: int, data: dict) -> dict:
    """Bad: This function does too many things."""
    # 1. Validate input
    if not isinstance(user_id, int) or user_id < 0:
        raise ValueError("Invalid user ID")
    if not data:
        raise ValueError("Empty data")
    
    # 2. Transform data
    transformed = {
        "id": user_id,
        "name": data.get("name", "").upper(),
        "email": data.get("email", "").lower(),
    }
    
    # 3. Save to database (simulated)
    print(f"Saving user {user_id} to database")
    
    # 4. Write to log file
    with open("/tmp/users.log", "a") as f:
        f.write(json.dumps(transformed) + "\n")
    
    # 5. Send notification
    print(f"Sending welcome email to {transformed['email']}")
    
    # 6. Update cache
    print(f"Updating cache for user {user_id}")
    
    # 7. Generate report
    report = {
        "status": "success",
        "user": transformed,
        "timestamp": "2024-01-01",
    }
    
    return report
