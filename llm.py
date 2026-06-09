import os
import json
import re
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

openai_api_key = os.getenv("OPENAI_API_KEY", "").strip()
google_api_key = os.getenv("GOOGLE_API_KEY", "").strip() or os.getenv("GEMINI_API_KEY", "").strip()
provider = os.getenv("LLM_PROVIDER", "auto").strip().lower()

# Accept both legacy and current env names.
default_model = os.getenv("LLM_MODEL", "").strip() or os.getenv("OPENAI_MODEL", "").strip()


def _build_client_and_model() -> tuple[OpenAI, str, str]:
    # Auto-detect provider so existing .env files keep working without changes.
    if provider in ("google", "gemini"):
        key = google_api_key or openai_api_key
        if not key:
            raise RuntimeError("Falta GOOGLE_API_KEY o GEMINI_API_KEY.")
        model = default_model or "gemini-2.0-flash"
        client = OpenAI(api_key=key, base_url="https://generativelanguage.googleapis.com/v1beta/openai/")
        return client, model, "google"

    if provider == "openai":
        if not openai_api_key:
            raise RuntimeError("Falta OPENAI_API_KEY en el entorno.")
        model = default_model or "gpt-4o-mini"
        client = OpenAI(api_key=openai_api_key)
        return client, model, "openai"

    # Auto mode
    if google_api_key or openai_api_key.startswith("AIza"):
        key = google_api_key or openai_api_key
        model = default_model or "gemini-2.0-flash"
        client = OpenAI(api_key=key, base_url="https://generativelanguage.googleapis.com/v1beta/openai/")
        return client, model, "google"

    if openai_api_key:
        model = default_model or "gpt-4o-mini"
        client = OpenAI(api_key=openai_api_key)
        return client, model, "openai"

    raise RuntimeError("No se encontro ninguna API key valida para LLM.")


def _get_client_and_model() -> tuple[OpenAI, str]:
    client, model_name, _ = _build_client_and_model()
    return client, model_name


def _heuristic_extract_json(text: str) -> str:
    entities = []
    actions = []

    # Very light-weight fallback extraction when LLM provider is unavailable.
    for match in re.finditer(r"\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b", text):
        candidate = match.group(1).strip()
        if len(candidate) >= 4 and candidate.lower() not in {"el", "la", "los", "las"}:
            entities.append({"name": candidate, "type": "OTHER"})

    date_match = re.search(r"\b\d{1,2}\s+de\s+[A-Za-z]+\b", text)
    if date_match:
        entities.append({"name": date_match.group(0), "type": "DATE"})

    for verb in ["firmar", "reunio", "reunirse", "acordar", "enviar", "aprobar"]:
        if verb in text.lower():
            actions.append(verb)

    # Remove duplicates preserving order.
    seen = set()
    dedup_entities = []
    for item in entities:
        key = (item["name"], item["type"])
        if key not in seen:
            seen.add(key)
            dedup_entities.append(item)

    result = {
        "summary": (text[:160] + "...") if len(text) > 160 else text,
        "entities": dedup_entities[:8],
        "actions": actions[:5],
        "confidence": 0.35,
        "needs_clarification": False if text.strip() else True,
        "clarifying_questions": [] if text.strip() else ["Puedes compartir mas contexto?", "Que accion esperas extraer?"]
    }
    return json.dumps(result, ensure_ascii=False)

def extract_info(text: str, domain: str):
    prompt = f"""
Eres un sistema de extracción de información.

REGLAS:
- NO inventar información
- Si falta información → needs_clarification = true
- Si needs_clarification = true → mínimo 2 preguntas

Devuelve SOLO JSON con este formato:
{{
  "summary": "...",
  "entities": [{{"name": "...", "type": "PERSON|ORG|DATE|LOCATION|OTHER"}}],
  "actions": ["..."],
  "confidence": 0.0,
  "needs_clarification": true,
  "clarifying_questions": ["..."]
}}

TEXTO:
{text}

DOMINIO:
{domain}
"""

    try:
        client, model_name = _get_client_and_model()
        response = client.chat.completions.create(
            model=model_name,
            messages=[{"role": "user", "content": prompt}],
            temperature=0
        )
        return response.choices[0].message.content
    except Exception:
        return _heuristic_extract_json(text)