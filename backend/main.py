from fastapi import FastAPI, HTTPException, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import re
import os
import io
from typing import List, Optional, Any, Dict
import google.genai as genai
from PIL import Image
from supabase import create_client, Client
from dotenv import load_dotenv
from agents import MultiAgentSystem, MultiAgentReport, AgentReasoning

load_dotenv()

app = FastAPI(title="PakDocAI Backend")

# Configure Gemini
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_ID = os.getenv("MODEL_ID", "gemini-2.0-flash")

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, specify your flutter app's URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase Configuration

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- HARDCODED DATABASES ---

MEDICINE_DB = {
    "augmentin": {
        "brand_name": "Augmentin",
        "generic_name": "Co-Amoxiclav",
        "max_adult_dose_per_day": 1750,
        "max_child_dose_per_kg": 45,
        "alternatives": ["Amoxil", "Velosef", "Moxiget"],
        "allergy_group": "Penicillin",
        "ckd_safe": True
    },
    "panadol": {
        "brand_name": "Panadol",
        "generic_name": "Paracetamol",
        "max_adult_dose_per_day": 4000,
        "max_child_dose_per_kg": 60,
        "alternatives": ["Calpol", "Febrol", "Disprol"],
        "allergy_group": "Paracetamol",
        "ckd_safe": True
    },
    "risek": {
        "brand_name": "Risek",
        "generic_name": "Omeprazole",
        "max_adult_dose_per_day": 40,
        "max_child_dose_per_kg": 1,
        "alternatives": ["Losec", "Omega", "Omez"],
        "allergy_group": "PPI",
        "ckd_safe": True
    },
    "flagyl": {
        "brand_name": "Flagyl",
        "generic_name": "Metronidazole",
        "max_adult_dose_per_day": 1500,
        "max_child_dose_per_kg": 30,
        "alternatives": ["Metrozine", "Metodine", "Nidazole"],
        "allergy_group": "Nitroimidazole",
        "ckd_safe": True
    },
    "arinac": {
        "brand_name": "Arinac",
        "generic_name": "Ibuprofen + Pseudoephedrine",
        "max_adult_dose_per_day": 1200,
        "max_child_dose_per_kg": 20,
        "alternatives": ["Advil Cold", "Brufen Cold", "Nurofen"],
        "allergy_group": "NSAID",
        "ckd_safe": False
    },
    "brufen": {
        "brand_name": "Brufen",
        "generic_name": "Ibuprofen",
        "max_adult_dose_per_day": 1200,
        "max_child_dose_per_kg": 30,
        "alternatives": ["Advil", "Nurofen", "Motrin"],
        "allergy_group": "NSAID",
        "ckd_safe": False
    },
    "amoxil": {
        "brand_name": "Amoxil",
        "generic_name": "Amoxicillin",
        "max_adult_dose_per_day": 1500,
        "max_child_dose_per_kg": 50,
        "alternatives": ["Augmentin", "Velosef", "Moxiget"],
        "allergy_group": "Penicillin",
        "ckd_safe": True
    },
    "gravinate": {
        "brand_name": "Gravinate",
        "generic_name": "Dimenhydrinate",
        "max_adult_dose_per_day": 400,
        "max_child_dose_per_kg": 5,
        "alternatives": ["Dramamine", "Gravol", "Vomine"],
        "allergy_group": "Antihistamine",
        "ckd_safe": True
    },
    "zantac": {
        "brand_name": "Zantac",
        "generic_name": "Ranitidine",
        "max_adult_dose_per_day": 300,
        "max_child_dose_per_kg": 4,
        "alternatives": ["Famopsin", "Gaviscon", "Pepcid"],
        "allergy_group": "H2 Blocker",
        "ckd_safe": True
    },
    "ponstan": {
        "brand_name": "Ponstan",
        "generic_name": "Mefenamic Acid",
        "max_adult_dose_per_day": 1500,
        "max_child_dose_per_kg": 20,
        "alternatives": ["Meftal", "Ponstel", "Mefnac"],
        "allergy_group": "NSAID",
        "ckd_safe": False
    },
    "kestine": {
        "brand_name": "Kestine",
        "generic_name": "Ebastine",
        "max_adult_dose_per_day": 20,
        "max_child_dose_per_kg": 0.2,
        "alternatives": ["Evastine", "Ebast", "Kestin"],
        "allergy_group": "Antihistamine",
        "ckd_safe": True
    },
    "solvin": {
        "brand_name": "Solvin",
        "generic_name": "Bromhexine",
        "max_adult_dose_per_day": 48,
        "max_child_dose_per_kg": 0.5,
        "alternatives": ["Bisolvon", "Broman", "Solmux"],
        "allergy_group": "Mucolytic",
        "ckd_safe": True
    },
    "entamizole": {
        "brand_name": "Entamizole",
        "generic_name": "Diloxanide + Metronidazole",
        "max_adult_dose_per_day": 1500,
        "max_child_dose_per_kg": 20,
        "alternatives": ["Flagyl", "Dilo-Met", "Entam"],
        "allergy_group": "Antiprotozoal",
        "ckd_safe": True
    },
    "velosef": {
        "brand_name": "Velosef",
        "generic_name": "Cephradine",
        "max_adult_dose_per_day": 2000,
        "max_child_dose_per_kg": 50,
        "alternatives": ["Amoxil", "Augmentin", "Keflex"],
        "allergy_group": "Penicillin", # Cephalosporins cross-react
        "ckd_safe": True
    },
    "lipiget": {
        "brand_name": "Lipiget",
        "generic_name": "Atorvastatin",
        "max_adult_dose_per_day": 80,
        "max_child_dose_per_kg": 0, # Not for children usually
        "alternatives": ["Lipitor", "Atorva", "Stat-A"],
        "allergy_group": "Statin",
        "ckd_safe": True
    },
}

# PATIENT_DB is now handled by Supabase

# --- MODELS ---

class PatientRequest(BaseModel):
    cnic: str
    full_name: str
    date_of_birth: str # Format: YYYY-MM-DD
    gender: str
    contact_number: Optional[str] = None
    allergies: List[str] = []
    medical_history: Optional[str] = None

class VisitRequest(BaseModel):
    patient_cnic: str
    weight_kg: float
    height_cm: Optional[float] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[int] = None
    temperature_f: Optional[float] = None
    chief_complaint: Optional[str] = None

class AnalysisRequest(BaseModel):
    patient_id: str # This is the CNIC
    input_text: str
    visit_id: Optional[str] = None

class AgentStep(BaseModel):
    agent_name: str
    thought_process: str
    findings: Any
    risk_level: str
    recommendation: str

class AnalysisResponse(BaseModel):
    drug: str
    generic: str
    safety_color: str
    reason: str
    alternatives: List[str]
    agent_steps: List[AgentStep] = []
    action_simulated: str = ""
    outcome_visualization: Dict[str, Any] = {}

class PatientResponse(BaseModel):
    full_name: str
    age: int
    weight: float
    allergies: List[str]
    condition: Optional[str]
    cnic: str

# --- DB ROUTES ---

@app.post("/patients")
async def register_patient(patient: PatientRequest):
    try:
        # We use cnic as the primary key, so upsert handles create/update
        data = supabase.table("patients").upsert({
            "cnic": patient.cnic,
            "full_name": patient.full_name,
            "date_of_birth": patient.date_of_birth,
            "gender": patient.gender,
            "contact_number": patient.contact_number,
            "allergies": patient.allergies,
            "medical_history": patient.medical_history
        }).execute()
        return {"status": "success", "data": data.data[0] if data.data else {}}
    except Exception as e:
        print(f"DEBUG: Error registering patient: {e}")
        # Check if it's a column mismatch
        if "column" in str(e) and "does not exist" in str(e):
            raise HTTPException(status_code=500, detail="Database schema mismatch. Please run the ALTER TABLE SQL provided.")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/patients/{cnic}")
async def get_patient(cnic: str):
    try:
        response = supabase.table("patients").select("*").eq("cnic", cnic).execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Patient not found")
        
        # Also get latest vitals from patient_visits table
        visit_response = supabase.table("patient_visits").select("*").eq("patient_cnic", cnic).order("visit_date", desc=True).limit(1).execute()
        
        patient_data = response.data[0]
        vitals = visit_response.data[0] if visit_response.data else {}
        
        # Calculate age from date_of_birth
        age = 0
        if patient_data.get("date_of_birth"):
            from datetime import datetime
            dob = datetime.strptime(patient_data["date_of_birth"], "%Y-%m-%d")
            age = (datetime.now() - dob).days // 365

        return {
            "name": patient_data["full_name"],
            "age": age,
            "weight": float(vitals.get("weight_kg", 70)), # default weight
            "allergies": patient_data["allergies"],
            "condition": patient_data["medical_history"],
            "cnic": patient_data["cnic"]
        }
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        print(f"DEBUG: Error fetching patient: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.post("/visits")
async def add_visit(visit: VisitRequest):
    try:
        data = supabase.table("patient_visits").insert({
            "patient_cnic": visit.patient_cnic,
            "weight_kg": visit.weight_kg,
            "height_cm": visit.height_cm,
            "blood_pressure": visit.blood_pressure,
            "heart_rate": visit.heart_rate,
            "temperature_f": visit.temperature_f,
            "chief_complaint": visit.chief_complaint
        }).execute()
        return {"status": "success", "visit_id": data.data[0]["id"] if data.data else None}
    except Exception as e:
        print(f"Error adding visit: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- UTILS ---

# --- AI-AUGMENTED KNOWLEDGE BASE (Extended for Pakistan) ---
AI_KNOWLEDGE_BASE = {
    "cefixime": {
        "brands": ["Cefspan", "Caricef", "Cefim"],
        "allergy_group": "Penicillin", # Cross-reactivity risk
        "ckd_safe": True,
        "asthma_safe": True
    },
    "propranolol": {
        "brands": ["Inderal", "Cardinol"],
        "allergy_group": "Beta-Blocker",
        "ckd_safe": True,
        "asthma_safe": False # Dangerous for Asthma
    },
    "ciprofloxacin": {
        "brands": ["Novidat", "Ciproxin", "Qupro"],
        "allergy_group": "Quinolone",
        "ckd_safe": False, # Dose adjustment needed
        "asthma_safe": True
    },
    "xylometazoline": {
        "brands": ["Xylomet", "Otrin", "Nasic"],
        "allergy_group": "Decongestant",
        "ckd_safe": True,
        "asthma_safe": True
    }
}

# --- UTILS ---

def parse_input(text: str):
    text = text.lower()
    found_drug = None
    found_generic = None
    
    # 1. Search for Brand Name match in DB
    for drug_key, data in MEDICINE_DB.items():
        if drug_key in text:
            found_drug = drug_key
            break
            
    # 2. Search for Generic Name match in DB
    if not found_drug:
        for drug_key, data in MEDICINE_DB.items():
            if data["generic_name"].lower() in text:
                found_drug = drug_key
                break
                
    # 3. AI-Search: Check for Generic Name in AI Knowledge Base
    if not found_drug:
        for generic, data in AI_KNOWLEDGE_BASE.items():
            if generic in text:
                found_generic = generic
                break
            for brand in data["brands"]:
                if brand.lower() in text:
                    found_generic = generic
                    break
    
    # Extract dose (mg)
    dose_match = re.search(r'(\d+)\s*mg', text)
    dose = int(dose_match.group(1)) if dose_match else 0
    
    # Extract frequency
    freq = 1
    if "twice" in text or "bid" in text: freq = 2
    elif "thrice" in text or "tid" in text: freq = 3
        
    return found_drug, found_generic, (dose * freq)

# --- DYNAMIC AI INFERENCE ENGINE ---

def ai_fallback_analysis(text: str, patient: dict):
    """
    Simulates a 'Deep AI Search' for drugs not in our hardcoded DB.
    It identifies drug classes based on common suffixes and checks safety.
    """
    text = text.lower()
    
    # Class Inference Logic
    inferred_class = None
    drug_name = text.split()[0].capitalize()
    
    # Common medical suffix patterns used by AI
    if text.endswith("olol") or "inderal" in text:
        inferred_class = "Beta-Blocker"
    elif text.endswith("pril") or "ace" in text:
        inferred_class = "ACE Inhibitor"
    elif text.endswith("statin") or "lipitor" in text:
        inferred_class = "Statin"
    elif text.endswith("sartan") or "valsartan" in text:
        inferred_class = "ARB"
    elif "metformin" in text or "glid" in text:
        inferred_class = "Anti-Diabetic"

    if not inferred_class:
        return AnalysisResponse(
            drug=drug_name,
            generic="Unknown Class",
            safety_color="YELLOW",
            reason="AI Research: Drug identified but safety profile is inconclusive for this specific patient condition. Clinical supervision advised.",
            alternatives=["Consult Physician"]
        )

    # Safety Reasoning based on Inferred Class
    if inferred_class == "Beta-Blocker" and patient["condition"] == "Severe Asthma":
        return AnalysisResponse(
            drug=drug_name,
            generic=inferred_class,
            safety_color="RED",
            reason=f"AI Safety Alert: {drug_name} belongs to the {inferred_class} class. This is strictly contraindicated for patients with Asthma as it can cause severe Bronchospasm.",
            alternatives=["Calcium Channel Blockers", "Amlodipine"]
        )
    
    if inferred_class == "Statin" and patient["condition"] == "Chronic Kidney Disease":
        return AnalysisResponse(
            drug=drug_name,
            generic=inferred_class,
            safety_color="YELLOW",
            reason=f"AI Dosage Warning: Statins like {drug_name} require careful monitoring in CKD patients due to risk of Myopathy.",
            alternatives=["Dose Adjustment Advised"]
        )

    return AnalysisResponse(
        drug=drug_name,
        generic=inferred_class,
        safety_color="GREEN",
        reason=f"AI Analysis: {drug_name} ({inferred_class}) is generally compatible with the patient's profile. No immediate contraindications found.",
        alternatives=["Continue as prescribed"]
    )

# --- ENDPOINTS ---

# REDUNDANT ROUTE REMOVED (Handled by /patients/{cnic})

@app.post("/analyze-image", response_model=AnalysisResponse)
async def analyze_image(patient_id: str = Form(...), file: UploadFile = File(...)):
    # Fetch patient from Supabase
    response = supabase.table("patients").select("*").eq("cnic", patient_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Patient not found in database")
    
    patient_record = response.data[0]
    
    # Fetch latest vitals
    visit_response = supabase.table("patient_visits").select("*").eq("patient_cnic", patient_id).order("visit_date", desc=True).limit(1).execute()
    latest_vitals = visit_response.data[0] if visit_response.data else {"weight_kg": 70}

    # Calculate age from date_of_birth
    age = 0
    if patient_record.get("date_of_birth"):
        from datetime import datetime
        try:
            dob = datetime.strptime(patient_record["date_of_birth"], "%Y-%m-%d")
            age = (datetime.now() - dob).days // 365
        except:
            pass

    patient_context = {
        "name": patient_record["full_name"],
        "age": age,
        "weight": latest_vitals.get("weight_kg", 70),
        "allergies": patient_record["allergies"],
        "condition": patient_record["medical_history"],
        "vitals": latest_vitals
    }

    try:
        # Read image
        image_data = await file.read()
        img = Image.open(io.BytesIO(image_data))
        
        # Run Multi-Agent Analysis
        agent_system = MultiAgentSystem()
        report: MultiAgentReport = await agent_system.run_analysis("", patient_context, image_context=img)
        
        # Map report to response
        intake_step = next((s for s in report.agent_steps if s.agent_name == "Prescription Intake Agent"), None)
        knowledge_step = next((s for s in report.agent_steps if s.agent_name == "Medicine Knowledge Agent"), None)
        
        drug_name = intake_step.findings.get("medication", "Unknown") if intake_step else "Unknown"
        generic_name = knowledge_step.findings.get("class", "Unknown") if knowledge_step else "Unknown"
        
        recommendation_step = next((s for s in report.agent_steps if s.agent_name == "Recommendation Agent"), None)
        alternatives = recommendation_step.findings.get("alternatives", []) if recommendation_step else []
        
        return AnalysisResponse(
            drug=drug_name,
            generic=generic_name,
            safety_color=report.final_risk_level,
            reason=report.final_decision,
            alternatives=alternatives,
            agent_steps=[AgentStep(**s.dict()) for s in report.agent_steps],
            action_simulated=report.action_simulated,
            outcome_visualization=report.outcome_visualization_data
        )

    except Exception as e:
        print(f"OCR Error: {e}")
        raise HTTPException(status_code=500, detail=f"AI Vision Analysis failed: {str(e)}")

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_prescription(request: AnalysisRequest):
    patient_id = request.patient_id # CNIC
    
    # Fetch patient from Supabase
    response = supabase.table("patients").select("*").eq("cnic", patient_id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="Patient not found in database")
    
    patient_record = response.data[0]
    
    # Fetch latest vitals
    visit_response = supabase.table("patient_visits").select("*").eq("patient_cnic", patient_id).order("visit_date", desc=True).limit(1).execute()
    latest_vitals = visit_response.data[0] if visit_response.data else {"weight_kg": 70}

    # Calculate age from date_of_birth
    age = 0
    if patient_record.get("date_of_birth"):
        from datetime import datetime
        try:
            dob = datetime.strptime(patient_record["date_of_birth"], "%Y-%m-%d")
            age = (datetime.now() - dob).days // 365
        except:
            pass

    patient_context = {
        "name": patient_record["full_name"],
        "age": age,
        "weight": latest_vitals.get("weight_kg", 70),
        "allergies": patient_record["allergies"],
        "condition": patient_record["medical_history"],
        "vitals": latest_vitals
    }

    try:
        agent_system = MultiAgentSystem()
        report: MultiAgentReport = await agent_system.run_analysis(request.input_text, patient_context)
        
        intake_step = next((s for s in report.agent_steps if s.agent_name == "Prescription Intake Agent"), None)
        knowledge_step = next((s for s in report.agent_steps if s.agent_name == "Medicine Knowledge Agent"), None)
        
        drug_name = intake_step.findings.get("medication", "Unknown") if intake_step else "Unknown"
        generic_name = knowledge_step.findings.get("class", "Unknown") if knowledge_step else "Unknown"

        recommendation_step = next((s for s in report.agent_steps if s.agent_name == "Recommendation Agent"), None)
        alternatives = recommendation_step.findings.get("alternatives", []) if recommendation_step else []

        return AnalysisResponse(
            drug=drug_name,
            generic=generic_name,
            safety_color=report.final_risk_level,
            reason=report.final_decision,
            alternatives=alternatives,
            agent_steps=[AgentStep(**s.dict()) for s in report.agent_steps],
            action_simulated=report.action_simulated,
            outcome_visualization=report.outcome_visualization_data
        )
    except Exception as e:
        print(f"Analysis Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
