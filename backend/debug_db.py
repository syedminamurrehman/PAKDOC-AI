import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def debug_patients():
    try:
        response = supabase.table("patients").select("*").execute()
        print(f"Total patients in DB: {len(response.data)}")
        for p in response.data:
            print(f"CNIC: '{p['cnic']}', Name: {p['full_name']}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_patients()
