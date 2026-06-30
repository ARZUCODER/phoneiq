import os
from typing import List, Optional

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from agent import recommend
from catalog import all_phones

load_dotenv()

app = FastAPI(title="PhoneIQ API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class Message(BaseModel):
    role: str
    text: str


class ChatRequest(BaseModel):
    message: str
    history: Optional[List[Message]] = None


@app.get("/health")
def health():
    return {"status": "ok", "catalog_size": len(all_phones())}


@app.get("/phones")
def phones():
    return all_phones()


@app.post("/chat")
def chat(req: ChatRequest):
    history = [m.dict() for m in (req.history or [])]
    result = recommend(history, req.message)
    return result


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
