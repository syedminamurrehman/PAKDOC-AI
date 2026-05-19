import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_schema():
    try:
        # We can't directly query information_schema via RPC usually, 
        # but we can try to select a single row and see what columns are returned if we don't specify them.
        # Or just try to see what the error says for 'date_of_birth'
        response = supabase.table("patients").select("*").limit(1).execute()
        if response.data:
            print(f"Columns in patients: {response.data[0].keys()}")
        else:
            print("Table is empty, can't infer columns easily. Trying explicit select.")
            try:
                supabase.table("patients").select("cnic, full_name, age").limit(1).execute()
                print("Columns 'cnic, full_name, age' exist.")
            except Exception as e:
                print(f"Error selecting 'age': {e}")
                
            try:
                supabase.table("patients").select("cnic, full_name, date_of_birth").limit(1).execute()
                print("Columns 'cnic, full_name, date_of_birth' exist.")
            except Exception as e:
                print(f"Error selecting 'date_of_birth': {e}")
                
    except Exception as e:
        print(f"General error: {e}")

if __name__ == "__main__":
    check_schema()
