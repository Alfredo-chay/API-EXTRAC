from pydantic import BaseModel
from typing import List, Literal

class Entity(BaseModel):
    name: str
    type: Literal["PERSON", "ORG", "DATE", "LOCATION", "OTHER"]

class ExtractResponse(BaseModel):
    summary: str
    entities: List[Entity]
    actions: List[str]
    confidence: float
    needs_clarification: bool
    clarifying_questions: List[str]

class ExtractRequest(BaseModel):
    text: str
    domain: str