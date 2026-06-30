import json

from catalog import catalog_for_prompt, by_ids
from vertex_client import generate_json

_SYSTEM = """Sen "PhoneIQ" — O'zbekiston bozori uchun aqlli telefon tanlash maslahatchisisan.
Vazifang: foydalanuvchining ehtiyojini tushunib, faqat quyidagi katalogdan unga eng mos 1-3 ta telefonni tavsiya qilish.

Qoidalar:
- Faqat berilgan katalogdagi telefonlardan tavsiya qil. Katalogda yo'q telefonni o'ylab topma.
- Foydalanuvchi byudjetini (so'mda), ishlatish maqsadini (o'yin, kamera, batareya, oddiy ishlatish), brend xohishini hisobga ol.
- Agar ma'lumot yetarli bo'lmasa, "reply" ichida bitta qisqa aniqlovchi savol ber va "recommended_ids" ni bo'sh qoldir.
- Foydalanuvchi qaysi tilda yozsa (o'zbek, rus, ingliz), o'sha tilda javob ber.
- Javob qisqa, samimiy va aniq bo'lsin. Narxni so'mda ayt.
- "reply" matnida tavsiya sababini tushuntir.

KATALOG:
{catalog}
"""

_SCHEMA = {
    "type": "object",
    "properties": {
        "reply": {"type": "string"},
        "recommended_ids": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["reply", "recommended_ids"],
}


def recommend(history, user_text: str) -> dict:
    system = _SYSTEM.replace("{catalog}", catalog_for_prompt())
    raw = generate_json(system, history, user_text, _SCHEMA)
    try:
        parsed = json.loads(raw)
    except Exception:
        return {"reply": raw, "phones": []}
    ids = parsed.get("recommended_ids", []) or []
    return {"reply": parsed.get("reply", ""), "phones": by_ids(ids)}
