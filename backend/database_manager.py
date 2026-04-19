import json
import os

DB_FILE = "database.json"

def load_db():
    if not os.path.exists(DB_FILE):
        return {"users": [], "pets": []}
    try:
        with open(DB_FILE, "r") as f:
            return json.load(f)
    except:
        return {"users": [], "pets": []}

def save_db(data):
    with open(DB_FILE, "w") as f:
        json.dump(data, f, indent=4, default=str)

def get_users():
    return load_db()["users"]

def get_pets():
    return load_db()["pets"]

def update_users(users):
    db = load_db()
    db["users"] = users
    save_db(db)

def update_pets(pets):
    db = load_db()
    db["pets"] = pets
    save_db(db)
