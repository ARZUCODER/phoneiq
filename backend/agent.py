import json
import time

from vertexai.generative_models import Tool, FunctionDeclaration, Part

import catalog
from olx import search_olx
from vertex_client import (
    chat_model,
    history_contents,
    grounded_search,
    generate_json,
)

_SYSTEM = """Sen "PhoneIQ" — O'zbekiston bozori uchun aqlli telefon tanlash maslahatchisisan.

Sening vositalaring:
- recommend_phones: do'kon katalogimizdagi YANGI telefonlardan byudjet, maqsad va brend bo'yicha tanlash uchun.
- search_used_phones: foydalanuvchi ISHLATILGAN (b/u, arzon, OLX) telefon yoki aniq modelni ikkilamchi bozordan izlasa.
- search_web: katalogda yo'q telefon, eng so'nggi modellar, narx-yangiliklar, taqqoslash yoki texnik ma'lumot kerak bo'lsa internetdan qidirish uchun.

Qoidalar:
- Avval ehtiyojni tushun (byudjet so'mda, maqsad: o'yin/kamera/batareya/oddiy). Kerak bo'lsa bitta qisqa savol ber.
- MUHIM: "qidiraman", "qidiryapman", "hozir topaman" deb va'da BERMA. Agar qidirish kerak bo'lsa — darhol mos vositani CHAQIR va faqat natijani ko'rgandan keyin javob ber.
- Foydalanuvchi narx aytsa (masalan "1000$"), so'mga aylantir (1$ ≈ 12600 so'm).
- Foydalanuvchi qaysi tilda yozsa, o'sha tilda javob ber. Qisqa, samimiy va aniq bo'l.
- Tavsiya sababini tushuntir. Narxni o'zing o'ylab topma, faqat vosita natijalaridan foydalan.
- Agar vosita natija qaytarmasa, buni ochiq ayt va boshqa variant taklif qil.
"""

_FALLBACK_SCHEMA = {
    "type": "object",
    "properties": {
        "reply": {"type": "string"},
        "recommended_ids": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["reply", "recommended_ids"],
}

_TOOL = Tool(
    function_declarations=[
        FunctionDeclaration(
            name="recommend_phones",
            description="Do'kon katalogidagi yangi telefonlardan tavsiya tanlaydi.",
            parameters={
                "type": "object",
                "properties": {
                    "budget_max_uzs": {"type": "integer"},
                    "usage": {"type": "string"},
                    "brand": {"type": "string"},
                },
            },
        ),
        FunctionDeclaration(
            name="search_used_phones",
            description="OLX'dan ishlatilgan telefonlarni qidiradi.",
            parameters={
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
        ),
        FunctionDeclaration(
            name="search_web",
            description="Internetdan telefon haqida joriy ma'lumot qidiradi.",
            parameters={
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
        ),
    ]
)


def _args(fc):
    try:
        return {k: v for k, v in fc.args.items()}
    except Exception:
        return {}


def _safe_text(resp):
    try:
        return resp.text
    except Exception:
        chunks = []
        try:
            for part in resp.candidates[0].content.parts:
                if getattr(part, "text", ""):
                    chunks.append(part.text)
        except Exception:
            pass
        return " ".join(chunks)


def _fallback(history, user_text):
    system = _SYSTEM + "\n\nKATALOG:\n" + catalog.catalog_for_prompt()
    raw = generate_json(system, history, user_text, _FALLBACK_SCHEMA)
    try:
        parsed = json.loads(raw)
    except Exception:
        return {"reply": raw, "phones": [], "used": []}
    return {
        "reply": parsed.get("reply", ""),
        "phones": catalog.by_ids(parsed.get("recommended_ids", []) or []),
        "used": [],
    }


def _run_agent(history, user_text):
    try:
        model = chat_model(_SYSTEM, [_TOOL])
        chat = model.start_chat(history=history_contents(history))
        resp = chat.send_message(user_text)
        phones, used = [], []

        for _ in range(4):
            parts = resp.candidates[0].content.parts
            calls = [
                p.function_call
                for p in parts
                if getattr(p, "function_call", None) and p.function_call.name
            ]
            if not calls:
                break
            responses = []
            for fc in calls:
                name = fc.name
                args = _args(fc)
                if name == "recommend_phones":
                    res = catalog.recommend(
                        int(args.get("budget_max_uzs") or 0),
                        str(args.get("usage") or ""),
                        str(args.get("brand") or ""),
                    )
                    phones = res
                    payload = {"phones": res}
                elif name == "search_used_phones":
                    res = search_olx(str(args.get("query") or ""), 4)
                    used = res
                    payload = {"listings": res}
                elif name == "search_web":
                    payload = {"text": grounded_search(str(args.get("query") or ""))}
                else:
                    payload = {}
                responses.append(
                    Part.from_function_response(name=name, response=payload)
                )
            resp = chat.send_message(responses)

        return {"reply": _safe_text(resp), "phones": phones, "used": used}
    except Exception:
        raise


def _is_quota(e):
    s = str(e)
    return "429" in s or "Resource exhausted" in s or "RESOURCE_EXHAUSTED" in s


def recommend(history, user_text):
    for attempt in range(3):
        try:
            return _run_agent(history, user_text)
        except Exception as e:
            if _is_quota(e) and attempt < 2:
                time.sleep(2 * (attempt + 1))
                continue
            break
    try:
        return _fallback(history, user_text)
    except Exception:
        return {
            "reply": "Hozir AI tizimi band (so'rovlar limiti). Iltimos, "
            "bir-ikki daqiqadan so'ng qayta urinib ko'ring.",
            "phones": [],
            "used": [],
        }
