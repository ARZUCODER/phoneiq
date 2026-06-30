import re
from urllib.parse import quote

import httpx
from bs4 import BeautifulSoup

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36",
    "Accept-Language": "uz,ru;q=0.9,en;q=0.8",
}

_STOP = {
    "ishlatilgan", "b/u", "bu", "olx", "dan", "top", "kerak", "narxi", "narx",
    "telefon", "phone", "used", "find", "search", "qidir", "izla", "menga",
    "uchun", "yangi", "sotib", "olaman", " olish",
}


def _tokens(query):
    raw = re.findall(r"[a-zA-Z0-9]+", query.lower())
    return [t for t in raw if t not in _STOP and len(t) >= 2]


def search_olx(query, max_results=4):
    toks = _tokens(query)
    clean = " ".join(toks) if toks else query
    url = f"https://www.olx.uz/list/q-{quote(clean)}/"
    try:
        r = httpx.get(url, headers=_HEADERS, timeout=15, follow_redirects=True)
        if r.status_code != 200:
            return []
        soup = BeautifulSoup(r.text, "html.parser")
    except Exception:
        return []

    key_tokens = [t for t in toks if t.isalpha() and len(t) >= 3]

    cards = soup.select('[data-testid="l-card"]')
    out = []
    seen = set()
    for card in cards:
        link = card.select_one('a[href*="/d/obyavlenie/"]')
        if not link:
            continue
        href = link.get("href", "")
        if href.startswith("/"):
            href = "https://www.olx.uz" + href
        if not href or href in seen:
            continue
        seen.add(href)

        title_el = card.select_one("h6") or card.select_one("h4")
        title_text = title_el.get_text(strip=True) if title_el else ""
        if key_tokens and not any(t in title_text.lower() for t in key_tokens):
            continue
        price_el = card.select_one('[data-testid="ad-price"]')
        loc_el = card.select_one('[data-testid="location-date"]')
        img = card.select_one("img")
        img_src = img.get("src") if img else ""
        if img_src and img_src.startswith("data:"):
            img_src = img.get("data-src", "") or ""

        out.append(
            {
                "title": title_text,
                "price": price_el.get_text(strip=True) if price_el else "",
                "url": href,
                "image": img_src or "",
                "location": loc_el.get_text(strip=True) if loc_el else "",
            }
        )
        if len(out) >= max_results:
            break
    return out
