import json
import os
from pathlib import Path
from typing import List, Dict, Any

try:
    from sqlalchemy import create_engine, text
except Exception:
    create_engine = None
    text = None

DATA_PATH = Path(__file__).parent / "data" / "phones.json"


def _load_from_file() -> List[Dict[str, Any]]:
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def _load_from_db() -> List[Dict[str, Any]]:
    dsn = os.getenv("DB_DSN", "").strip()
    if not dsn or create_engine is None:
        return []
    try:
        engine = create_engine(dsn, pool_pre_ping=True)
        with engine.connect() as conn:
            rows = conn.execute(text("SELECT data FROM phones")).fetchall()
            return [r[0] for r in rows]
    except Exception:
        return []


_cache: List[Dict[str, Any]] = []


def all_phones() -> List[Dict[str, Any]]:
    global _cache
    if _cache:
        return _cache
    db_rows = _load_from_db()
    _cache = db_rows if db_rows else _load_from_file()
    return _cache


def by_ids(ids: List[str]) -> List[Dict[str, Any]]:
    index = {p["id"]: p for p in all_phones()}
    result = []
    for i in ids:
        if i in index:
            result.append(index[i])
    return result


_USAGE_TAGS = {
    "gaming": ["gaming", "performance"],
    "oyin": ["gaming", "performance"],
    "camera": ["camera", "zoom", "leica"],
    "kamera": ["camera", "zoom", "leica"],
    "battery": ["battery", "charging"],
    "batareya": ["battery", "charging"],
    "budget": ["budget", "value", "cheap"],
    "arzon": ["budget", "value", "cheap"],
    "premium": ["flagship", "premium"],
    "flagship": ["flagship", "premium"],
}


def recommend(budget_max_uzs=0, usage="", brand="", limit=3):
    items = all_phones()
    if brand:
        b = brand.lower()
        filtered = [p for p in items if b in p["brand"].lower()]
        if filtered:
            items = filtered

    wanted = []
    for key, tags in _USAGE_TAGS.items():
        if usage and key in usage.lower():
            wanted = tags
            break

    def score(p):
        s = 0.0
        if budget_max_uzs and budget_max_uzs > 0:
            if p["price_uzs"] <= budget_max_uzs:
                s += 100 + (p["price_uzs"] / budget_max_uzs) * 20
            else:
                s -= (p["price_uzs"] - budget_max_uzs) / 1000000.0
        if wanted:
            s += 25 * len(set(wanted) & set(p["tags"]))
        return s

    ranked = sorted(items, key=score, reverse=True)
    return ranked[:limit]


def catalog_for_prompt() -> str:
    lines = []
    for p in all_phones():
        price = f"{p['price_uzs']:,}".replace(",", " ")
        lines.append(
            f"{p['id']} | {p['brand']} {p['model']} | {price} so'm | "
            f"{p['ram_gb']}GB RAM | {p['storage_gb']}GB | {p['battery_mah']}mAh | "
            f"{p['display']} | {p['main_camera_mp']}MP | {p['chipset']} | "
            f"{'5G' if p['five_g'] else '4G'} | {', '.join(p['tags'])}"
        )
    return "\n".join(lines)
