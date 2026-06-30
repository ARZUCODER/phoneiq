import os
from pathlib import Path

import httpx
import vertexai
from google.auth.transport.requests import Request
from google.oauth2 import service_account
from vertexai.generative_models import (
    GenerativeModel,
    GenerationConfig,
    Content,
    Part,
)

_PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT", "ilm-ai-app")
_LOCATION = os.getenv("VERTEX_LOCATION", "us-central1")
_MODEL = os.getenv("VERTEX_MODEL", "gemini-2.5-flash")
_SA_PATH = os.getenv(
    "GOOGLE_APPLICATION_CREDENTIALS",
    str(Path(__file__).parent / "service-account.json"),
)

_SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]

_model = None
_credentials = None


def _init():
    global _model, _credentials
    if _model is not None:
        return _model
    if Path(_SA_PATH).exists():
        _credentials = service_account.Credentials.from_service_account_file(
            _SA_PATH, scopes=_SCOPES
        )
    vertexai.init(project=_PROJECT, location=_LOCATION, credentials=_credentials)
    _model = GenerativeModel(_MODEL)
    return _model


def _token():
    if _credentials is None:
        return None
    if not _credentials.valid:
        _credentials.refresh(Request())
    return _credentials.token


def _to_contents(history):
    contents = []
    for item in history:
        role = "model" if item.get("role") == "assistant" else "user"
        contents.append(Content(role=role, parts=[Part.from_text(item.get("text", ""))]))
    return contents


def generate_json(system_instruction: str, history, user_text: str, schema: dict) -> str:
    _init()
    sysmodel = GenerativeModel(_MODEL, system_instruction=[system_instruction])
    contents = _to_contents(history)
    contents.append(Content(role="user", parts=[Part.from_text(user_text)]))
    config = GenerationConfig(
        temperature=0.4,
        response_mime_type="application/json",
        response_schema=schema,
    )
    response = sysmodel.generate_content(contents, generation_config=config)
    return response.text


def grounded_search(query: str) -> str:
    _init()
    token = _token()
    url = (
        f"https://{_LOCATION}-aiplatform.googleapis.com/v1/projects/{_PROJECT}"
        f"/locations/{_LOCATION}/publishers/google/models/{_MODEL}:generateContent"
    )
    payload = {
        "contents": [{"role": "user", "parts": [{"text": query}]}],
        "tools": [{"google_search": {}}],
        "generationConfig": {"temperature": 0.3},
    }
    try:
        r = httpx.post(
            url,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=30,
        )
        if r.status_code != 200:
            return ""
        data = r.json()
        parts = data["candidates"][0]["content"]["parts"]
        return " ".join(p.get("text", "") for p in parts if p.get("text"))
    except Exception:
        return ""


def chat_model(system_instruction: str, tools):
    _init()
    return GenerativeModel(_MODEL, system_instruction=[system_instruction], tools=tools)


def history_contents(history):
    return _to_contents(history)

