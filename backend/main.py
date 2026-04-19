from fastapi import FastAPI, HTTPException, Header, Depends, UploadFile, File
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timezone
import uuid
import shutil
import os
import database_manager as db

app = FastAPI(title="PetPulse API")

# Ensure uploads directory exists
if not os.path.exists("uploads"):
    os.makedirs("uploads")

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# --- Models ---
class User(BaseModel):
    username: str
    full_name: str
    email: str
    password: str
    token: Optional[str] = None
    avatar_url: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class UserCreate(BaseModel):
    username: str
    password: str
    full_name: str
    email: str

class FeedingLog(BaseModel):
    id: str
    timestamp: datetime
    amount: str

class Pet(BaseModel):
    id: str
    name: str
    type: str  # Dog, Cat, Parrot, Rabbit, Hamster, Fish
    is_fed: bool
    owner_username: str
    birth_date: Optional[datetime] = None # New
    feeding_history: List[FeedingLog] = []

class PetCreate(BaseModel):
    name: str
    type: str
    birth_date: Optional[datetime] = None # New

class PetUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    is_fed: Optional[bool] = None
    birth_date: Optional[datetime] = None

# --- Auth Dependency ---
def verify_token(api_key: str = Header(None)):
    users = db.get_users()
    for user_data in users:
        if user_data.get("token") == api_key:
            return User(**user_data)
    raise HTTPException(status_code=401, detail="Unauthorized: Invalid Token")

# --- Auth Endpoints ---

@app.post("/register")
def register(user: UserCreate):
    users = db.get_users()
    for u in users:
        if u["username"] == user.username:
            raise HTTPException(status_code=400, detail="Username already exists")
    
    new_user = User(
        username=user.username,
        full_name=user.full_name,
        email=user.email,
        password=user.password,
        token=str(uuid.uuid4())
    )
    users.append(new_user.dict())
    db.update_users(users)
    return {"token": new_user.token, "user": new_user}

@app.post("/login")
def login(login_data: UserLogin):
    users = db.get_users()
    for user_data in users:
        if user_data["username"] == login_data.username and user_data["password"] == login_data.password:
            user_data["token"] = str(uuid.uuid4())
            db.update_users(users)
            return {"token": user_data["token"], "user": User(**user_data)}
    raise HTTPException(status_code=401, detail="Invalid username or password")

@app.get("/me", response_model=User)
def get_me(user: User = Depends(verify_token)):
    return user

@app.post("/upload_avatar")
async def upload_avatar(file: UploadFile = File(...), user: User = Depends(verify_token)):
    file_extension = file.filename.split(".")[-1]
    file_name = f"{user.username}_avatar.{file_extension}"
    file_path = os.path.join("uploads", file_name)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    avatar_url = f"http://localhost:8000/uploads/{file_name}"
    
    users = db.get_users()
    for u in users:
        if u["username"] == user.username:
            u["avatar_url"] = avatar_url
            break
    db.update_users(users)
    
    return {"avatar_url": avatar_url}

# --- Pet Endpoints ---

@app.get("/pets", response_model=List[Pet])
def get_pets(user: User = Depends(verify_token)):
    all_pets = db.get_pets()
    return [Pet(**p) for p in all_pets if p["owner_username"] == user.username]

@app.post("/pets", response_model=Pet)
def create_pet(pet_data: PetCreate, user: User = Depends(verify_token)):
    new_pet = Pet(
        id=str(uuid.uuid4()),
        name=pet_data.name,
        type=pet_data.type,
        is_fed=False,
        owner_username=user.username,
        birth_date=pet_data.birth_date,
        feeding_history=[]
    )
    pets = db.get_pets()
    pets.append(new_pet.dict())
    db.update_pets(pets)
    return new_pet

@app.put("/pets/{pet_id}", response_model=Pet)
def update_pet(pet_id: str, pet_data: PetUpdate, user: User = Depends(verify_token)):
    pets = db.get_pets()
    for p in pets:
        if p["id"] == pet_id and p["owner_username"] == user.username:
            if pet_data.name is not None: p["name"] = pet_data.name
            if pet_data.type is not None: p["type"] = pet_data.type
            if pet_data.is_fed is not None: p["is_fed"] = pet_data.is_fed
            if pet_data.birth_date is not None: p["birth_date"] = pet_data.birth_date
            db.update_pets(pets)
            return Pet(**p)
    raise HTTPException(status_code=404, detail="Pet not found")

@app.delete("/pets/{pet_id}")
def delete_pet(pet_id: str, user: User = Depends(verify_token)):
    pets = db.get_pets()
    initial_len = len(pets)
    pets = [p for p in pets if not (p["id"] == pet_id and p["owner_username"] == user.username)]
    if len(pets) == initial_len:
        raise HTTPException(status_code=404, detail="Pet not found")
    db.update_pets(pets)
    return {"status": "success"}

@app.post("/pets/{pet_id}/feed", response_model=Pet)
def feed_pet(pet_id: str, amount: str = "Standard", user: User = Depends(verify_token)):
    pets = db.get_pets()
    for p in pets:
        if p["id"] == pet_id and p["owner_username"] == user.username:
            log = FeedingLog(id=str(uuid.uuid4()), timestamp=datetime.now(timezone.utc), amount=amount)
            if "feeding_history" not in p: p["feeding_history"] = []
            p["feeding_history"].append(log.dict())
            p["is_fed"] = True
            db.update_pets(pets)
            return Pet(**p)
    raise HTTPException(status_code=404, detail="Pet not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
