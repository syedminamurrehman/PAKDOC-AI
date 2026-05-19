import os
import json
import google.genai as genai
from typing import List, Dict, Any, Optional
from pydantic import BaseModel

from dotenv import load_dotenv

load_dotenv()

# Configure Gemini
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_ID = os.getenv("MODEL_ID", "gemini-2.0-flash")

class AgentReasoning(BaseModel):
    agent_name: str
    thought_process: str
    findings: Any
    risk_level: str  # GREEN, YELLOW, RED
    recommendation: str

class MultiAgentReport(BaseModel):
    original_input: str
    patient_context: Dict[str, Any]
    agent_steps: List[AgentReasoning]
    final_decision: str
    final_risk_level: str
    action_simulated: str
    outcome_visualization_data: Dict[str, Any]

class MultiAgentSystem:
    def __init__(self):
        self.client = client

    async def run_analysis(self, input_text: str, patient_data: Dict[str, Any], image_context: Optional[Any] = None) -> MultiAgentReport:
        report_steps = []
        
        # 1. Prescription Intake Agent
        intake_result = await self.prescription_intake_agent(input_text, image_context)
        report_steps.append(intake_result)
        
        drug_info = intake_result.findings.get("medication", "Unknown")
        
        # 2. Medicine Knowledge Agent
        knowledge_result = await self.medicine_knowledge_agent(drug_info)
        report_steps.append(knowledge_result)
        
        # 3. Drug Interaction Agent
        # Checking against current patient history/meds
        interaction_result = await self.drug_interaction_agent(drug_info, patient_data.get("medical_history", ""))
        report_steps.append(interaction_result)
        
        # 4. Patient Risk Assessment Agent
        risk_result = await self.patient_risk_assessment_agent(drug_info, knowledge_result.findings, patient_data)
        report_steps.append(risk_result)
        
        # 5. Recommendation Agent
        final_rec = await self.recommendation_agent(report_steps, patient_data)
        report_steps.append(final_rec)
        
        # Determine overall risk
        overall_risk = "GREEN"
        for step in report_steps:
            if step.risk_level == "RED":
                overall_risk = "RED"
                break
            if step.risk_level == "YELLOW" and overall_risk != "RED":
                overall_risk = "YELLOW"

        return MultiAgentReport(
            original_input=input_text,
            patient_context=patient_data,
            agent_steps=report_steps,
            final_decision=final_rec.recommendation,
            final_risk_level=overall_risk,
            action_simulated="Simulation complete: Predicted physiological response analyzed.",
            outcome_visualization_data={
                "safety_score": 100 if overall_risk == "GREEN" else (50 if overall_risk == "YELLOW" else 10),
                "risk_factors": [step.findings for step in report_steps if step.risk_level != "GREEN"]
            }
        )

    async def prescription_intake_agent(self, text: str, image: Optional[Any]) -> AgentReasoning:
        prompt = f"""
        AGENT: Prescription Intake Agent
        TASK: Extract medication details from the following input or image.
        INPUT: {text}
        
        Return JSON format:
        {{
            "thought_process": "your reasoning",
            "findings": {{ "medication": "name", "dosage": "value", "frequency": "value" }},
            "risk_level": "GREEN/YELLOW/RED",
            "recommendation": "summary"
        }}
        """
        
        if image:
            response = self.client.models.generate_content(model=MODEL_ID, contents=[prompt, image])
        else:
            response = self.client.models.generate_content(model=MODEL_ID, contents=prompt)
            
        try:
            # Clean JSON if necessary
            json_text = response.text.strip().replace("```json", "").replace("```", "")
            data = json.loads(json_text)
            return AgentReasoning(
                agent_name="Prescription Intake Agent",
                thought_process=data.get("thought_process", ""),
                findings=data.get("findings", {}),
                risk_level=data.get("risk_level", "GREEN"),
                recommendation=data.get("recommendation", "")
            )
        except:
            return AgentReasoning(
                agent_name="Prescription Intake Agent",
                thought_process="Failed to parse intake accurately.",
                findings={{"medication": text}},
                risk_level="YELLOW",
                recommendation="Manual verification required."
            )

    async def medicine_knowledge_agent(self, drug_name: str) -> AgentReasoning:
        prompt = f"""
        AGENT: Medicine Knowledge Agent
        TASK: Research the drug '{drug_name}'. Identify its class, common uses, side effects, and standard dosage.
        
        Return JSON format:
        {{
            "thought_process": "your reasoning",
            "findings": {{ "class": "...", "side_effects": [], "standard_dose": "..." }},
            "risk_level": "GREEN",
            "recommendation": "Drug profile retrieved."
        }}
        """
        response = self.client.models.generate_content(model=MODEL_ID, contents=prompt)
        try:
            json_text = response.text.strip().replace("```json", "").replace("```", "")
            data = json.loads(json_text)
            return AgentReasoning(
                agent_name="Medicine Knowledge Agent",
                thought_process=data.get("thought_process", ""),
                findings=data.get("findings", {}),
                risk_level=data.get("risk_level", "GREEN"),
                recommendation=data.get("recommendation", "")
            )
        except:
            return AgentReasoning(agent_name="Medicine Knowledge Agent", thought_process="Search failed", findings={{}}, risk_level="YELLOW", recommendation="Knowledge base offline")

    async def drug_interaction_agent(self, drug_name: str, medical_history: str) -> AgentReasoning:
        prompt = f"""
        AGENT: Drug Interaction Agent
        TASK: Check if '{drug_name}' has any dangerous interactions with the following medical history/medications: {medical_history}
        
        Return JSON format:
        {{
            "thought_process": "your reasoning",
            "findings": {{ "interactions": [], "severity": "low/medium/high" }},
            "risk_level": "GREEN/YELLOW/RED",
            "recommendation": "..."
        }}
        """
        response = self.client.models.generate_content(model=MODEL_ID, contents=prompt)
        try:
            json_text = response.text.strip().replace("```json", "").replace("```", "")
            data = json.loads(json_text)
            return AgentReasoning(
                agent_name="Drug Interaction Agent",
                thought_process=data.get("thought_process", ""),
                findings=data.get("findings", {}),
                risk_level=data.get("risk_level", "GREEN"),
                recommendation=data.get("recommendation", "")
            )
        except:
            return AgentReasoning(agent_name="Drug Interaction Agent", thought_process="Search failed", findings={{}}, risk_level="YELLOW", recommendation="Verification pending")

    async def patient_risk_assessment_agent(self, drug_name: str, drug_info: Dict, patient_data: Dict) -> AgentReasoning:
        prompt = f"""
        AGENT: Patient Risk Assessment Agent
        TASK: Evaluate the safety of '{drug_name}' for this patient.
        PATIENT DATA: {json.dumps(patient_data)}
        DRUG INFO: {json.dumps(drug_info)}
        
        Consider:
        - Allergies
        - Vitals (BP, Heart Rate, Weight)
        - Pre-existing conditions
        
        Return JSON format:
        {{
            "thought_process": "your reasoning",
            "findings": {{ "risk_factors": [], "vitals_check": "passed/failed" }},
            "risk_level": "GREEN/YELLOW/RED",
            "recommendation": "..."
        }}
        """
        response = self.client.models.generate_content(model=MODEL_ID, contents=prompt)
        try:
            json_text = response.text.strip().replace("```json", "").replace("```", "")
            data = json.loads(json_text)
            return AgentReasoning(
                agent_name="Patient Risk Assessment Agent",
                thought_process=data.get("thought_process", ""),
                findings=data.get("findings", {}),
                risk_level=data.get("risk_level", "GREEN"),
                recommendation=data.get("recommendation", "")
            )
        except:
            return AgentReasoning(agent_name="Patient Risk Assessment Agent", thought_process="Search failed", findings={{}}, risk_level="YELLOW", recommendation="Clinical review needed")

    async def recommendation_agent(self, previous_steps: List[AgentReasoning], patient_data: Dict) -> AgentReasoning:
        steps_summary = "\n".join([f"- {s.agent_name}: {s.recommendation} (Risk: {s.risk_level})" for s in previous_steps])
        prompt = f"""
        AGENT: Recommendation Agent
        TASK: Provide the final clinical recommendation based on all previous agent findings.
        
        PREVIOUS FINDINGS:
        {steps_summary}
        
        PATIENT: {patient_data.get('name')}
        
        Should we PROCEED, ALTER, or STOP this medication? Why? Provide 2-3 safer alternatives if the risk is RED or YELLOW.
        
        Return JSON format:
        {{
            "thought_process": "your final reasoning",
            "findings": {{ "decision": "PROCEED/ALTER/STOP", "reasoning": "...", "alternatives": ["Alt 1", "Alt 2"] }},
            "risk_level": "GREEN/YELLOW/RED",
            "recommendation": "Final summary message for the doctor."
        }}
        """
        response = self.client.models.generate_content(model=MODEL_ID, contents=prompt)
        try:
            json_text = response.text.strip().replace("```json", "").replace("```", "")
            data = json.loads(json_text)
            return AgentReasoning(
                agent_name="Recommendation Agent",
                thought_process=data.get("thought_process", ""),
                findings=data.get("findings", {}),
                risk_level=data.get("risk_level", "GREEN"),
                recommendation=data.get("recommendation", "")
            )
        except:
            return AgentReasoning(agent_name="Recommendation Agent", thought_process="Search failed", findings={{}}, risk_level="YELLOW", recommendation="Consult specialized physician")
