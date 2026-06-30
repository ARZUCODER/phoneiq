import os
from pathlib import Path

import vertexai
from google.oauth2 import service_account
from vertexai.generative_models import GenerativeModel, GenerationConfig, Content, Part

_PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT", "ilm-ai-app")
_LOCATION = os.getenv("VERTEX_LOCATION", "us-central1")
_MODEL = os.getenv("VERTEX_MODEL", "gemini-2.5-flash")
_SA_PATH = os.getenv(
    "GOOGLE_APPLICATION_CREDENTIALS",
    str(Path(__file__).parent / "service-account.json"),
)

_SCOPES = ["https://www.googleapis.com/auth/cloud-platform"]

_model = None


def _init():
    global _model
    if _model is not None:
        return _model
    credentials = None
    if Path(_SA_PATH).exists():
        credentials = service_account.Credentials.from_service_account_file(
            _SA_PATH, scopes=_SCOPES
        )
    vertexai.init(project=_PROJECT, location=_LOCATION, credentials=credentials)
    _model = GenerativeModel(_MODEL)
    return _model


def _to_contents(history):
    contents = []
    for item in history:
        role = "model" if item.get("role") == "assistant" else "user"
        contents.append(Content(role=role, parts=[Part.from_text(item.get("text", ""))]))
    return contents


def generate_json(system_instruction: str, history, user_text: str, schema: dict) -> str:
    model = _init()
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
