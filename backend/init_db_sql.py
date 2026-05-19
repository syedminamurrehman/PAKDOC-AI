import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def init_db():
    print("Please run the following SQL in your Supabase SQL Editor:")
    sql = """
    -- Create patients table
    CREATE TABLE IF NOT EXISTS patients (
        cnic TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        contact_number TEXT,
        allergies TEXT[] DEFAULT '{}',
        medical_history TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Create patient_visits table
    CREATE TABLE IF NOT EXISTS patient_visits (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_cnic TEXT REFERENCES patients(cnic),
        weight_kg FLOAT,
        height_cm FLOAT,
        blood_pressure TEXT,
        heart_rate INTEGER,
        temperature_f FLOAT,
        chief_complaint TEXT,
        visit_date TIMESTAMPTZ DEFAULT NOW()
    );

    -- Enable RLS
    ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
    ALTER TABLE patient_visits ENABLE ROW LEVEL SECURITY;

    -- Create policies (for hackathon: allow all for anon)
    DROP POLICY IF EXISTS "Allow all for patients" ON patients;
    CREATE POLICY "Allow all for patients" ON patients FOR ALL USING (true) WITH CHECK (true);
    
    DROP POLICY IF EXISTS "Allow all for patient_visits" ON patient_visits;
    CREATE POLICY "Allow all for patient_visits" ON patient_visits FOR ALL USING (true) WITH CHECK (true);
    """
    print(sql)

if __name__ == "__main__":
    init_db()
