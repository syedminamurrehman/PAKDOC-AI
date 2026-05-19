import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def test_insert():
    try:
        data = {
            "cnic": "12345-1234567-1",
            "full_name": "Test Patient",
            "age": 30,
            "gender": "Male",
            "allergies": [],
            "medical_history": "None"
        }
        response = supabase.table("patients").upsert(data).execute()
        print(f"Upsert success: {response.data}")
        
        # Now try to read it back
        read_back = supabase.table("patients").select("*").eq("cnic", "12345-1234567-1").execute()
        print(f"Read back: {read_back.data}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_insert()
