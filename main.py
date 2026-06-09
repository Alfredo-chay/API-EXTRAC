from fastapi import FastAPI
from models import ExtractRequest, ExtractResponse
from llm import extract_info
import json
import logging
from pydantic import ValidationError


logger = logging.getLogger(__name__)


def _fallback_response() -> dict:
    return {
        "summary": "Error procesando",
        "entities": [],
        "actions": [],
        "confidence": 0.0,
        "needs_clarification": True,
        "clarifying_questions": [
            "Puedes dar mas detalles?",
            "Puedes reformular el texto?"
        ]
    }


def _parse_model_json(raw: str) -> dict:
    cleaned = raw.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.startswith("json"):
            cleaned = cleaned[4:].strip()
    return json.loads(cleaned)

app = FastAPI()

@app.post("/extract", response_model=ExtractResponse)
def extract(data: ExtractRequest):
    try:
        raw = extract_info(data.text, data.domain)
        parsed = _parse_model_json(raw)
        # Validate shape before returning to avoid response-model runtime failures.
        ExtractResponse(**parsed)
        return parsed
    except (json.JSONDecodeError, ValidationError, RuntimeError) as exc:
        logger.exception("Error de procesamiento controlado en /extract: %s", exc)
        return _fallback_response()
    except Exception as exc:
        logger.exception("Error inesperado en /extract: %s", exc)
        return _fallback_response()