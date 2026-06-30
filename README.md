# PhoneIQ — AI Phone Advisor

PhoneIQ is an AI agent that recommends the right smartphone from a product
database based on a customer's budget and needs. The user chats in natural
language (Uzbek, Russian or English) and the agent grounds every answer in the
catalog, returning structured recommendations rendered as phone cards.

**Live demo:** https://phoneiq.arzucoder.uz

## Architecture

```
Flutter Web (liquid-glass chat UI)
        │  POST /chat  { message, history }
        ▼
FastAPI backend (Python)
        ├── catalog layer  → Postgres (DB_DSN) or JSON seed fallback
        ├── agent          → grounded recommendation, JSON schema output
        └── Vertex AI      → Gemini 2.5 Flash (service-account auth)
```

The agent is built on Gemini function calling with three tools:

- **recommend_phones** — selects new phones from the store catalog by budget,
  use case and brand.
- **search_used_phones** — live search of used listings on OLX (olx.uz).
- **search_web** — current information (prices, new models, comparisons) via
  Vertex AI Google Search grounding.

The model decides which tools to call, the backend executes them and feeds the
results back, then the model produces the final answer. Catalog results render
as spec cards and OLX results render as listing cards linking back to olx.uz.

## Tech stack

| Layer     | Technology                                  |
|-----------|---------------------------------------------|
| Backend   | Python, FastAPI, Uvicorn                    |
| LLM       | Google Vertex AI — Gemini 2.5 Flash         |
| Data      | PostgreSQL (SQLAlchemy) with JSON fallback  |
| Container | Docker, docker-compose                      |
| Frontend  | Flutter Web                                 |

## Run the backend

```bash
cd backend
cp .env.example .env
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

Authentication uses a Google Cloud service account. Set
`GOOGLE_APPLICATION_CREDENTIALS` to its JSON path (or place `service-account.json`
in `backend/`) and `GOOGLE_CLOUD_PROJECT` to the project id.

### Docker

```bash
docker compose up --build
```

## Run the frontend

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8080
```

Build for the web and point it at a public backend:

```bash
flutter build web --dart-define=API_BASE=https://api.example.com
```

## API

`POST /chat`

```json
{ "message": "3 mln so'mgacha kamera uchun telefon", "history": [] }
```

```json
{ "reply": "...", "phones": [ { "brand": "Xiaomi", "model": "Redmi Note 13 Pro", "...": "..." } ] }
```

`GET /phones` — full catalog · `GET /health` — status and catalog size
