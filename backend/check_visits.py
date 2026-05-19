import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_visits_schema():
    try:
        # Try to select a row to see columns
        response = supabase.table("patient_visits").select("*").limit(1).execute()
        if response.data:
            print(f"Columns in patient_visits: {response.data[0].keys()}")
        else:
            print("patient_visits is empty. Trying common columns.")
            cols = ["id", "patient_cnic", "weight_kg", "blood_pressure", "heart_rate", "temperature_f", "chief_complaint", "visit_date"]
            found = []
            for c in cols:
                try:
                    supabase.table("patient_visits").select(c).limit(1).execute()
                    found.append(c)
                except:
                    pass
            print(f"Found columns: {found}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_visits_schema()
