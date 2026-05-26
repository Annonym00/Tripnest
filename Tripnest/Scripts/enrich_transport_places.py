#!/usr/bin/env python3
"""Enrichit TransportPlaces.json : alias pays (FR), gares mondiales (CSV Trainline), ports."""

from __future__ import annotations

import csv
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "App" / "Core" / "TransportPlaces.json"
TRAINLINE_CSV = Path("/tmp/stations.csv")

# Pays anglais (catalogue) → mots-clés supplémentaires (dont français)
COUNTRY_ALIASES: dict[str, list[str]] = {
    "Japan": ["japan", "japon", "jp", "nippon"],
    "China": ["china", "chine", "cn", "chinois"],
    "France": ["france", "fr", "francais", "français"],
    "Germany": ["germany", "allemagne", "de", "deutschland"],
    "United Kingdom": ["united kingdom", "royaume uni", "uk", "gb", "angleterre", "grande bretagne"],
    "United States": ["united states", "etats unis", "usa", "us", "amerique", "amérique"],
    "Italy": ["italy", "italie", "it"],
    "Spain": ["spain", "espagne", "es"],
    "Portugal": ["portugal", "pt"],
    "Netherlands": ["netherlands", "pays bas", "hollande", "nl"],
    "Belgium": ["belgium", "belgique", "be"],
    "Switzerland": ["switzerland", "suisse", "ch"],
    "Austria": ["austria", "autriche", "at"],
    "Greece": ["greece", "grece", "grèce", "gr"],
    "Turkey": ["turkey", "turquie", "tr"],
    "Morocco": ["morocco", "maroc", "ma"],
    "Algeria": ["algeria", "algerie", "algérie", "dz"],
    "Tunisia": ["tunisia", "tunisie", "tn"],
    "Egypt": ["egypt", "egypte", "eg"],
    "South Korea": ["south korea", "coree du sud", "corée du sud", "kr", "coree"],
    "India": ["india", "inde", "in"],
    "Thailand": ["thailand", "thailande", "thaïlande", "th"],
    "Vietnam": ["vietnam", "viêt nam", "vn"],
    "Indonesia": ["indonesia", "indonesie", "indonésie", "id"],
    "Australia": ["australia", "australie", "au"],
    "Canada": ["canada", "ca"],
    "Mexico": ["mexico", "mexique", "mx"],
    "Brazil": ["brazil", "bresil", "brésil", "br"],
    "Argentina": ["argentina", "argentine", "ar"],
    "Russia": ["russia", "russie", "ru"],
    "Poland": ["poland", "pologne", "pl"],
    "Sweden": ["sweden", "suede", "suède", "se"],
    "Norway": ["norway", "norvege", "norvège", "no"],
    "Denmark": ["denmark", "danemark", "dk"],
    "Finland": ["finland", "finlande", "fi"],
    "Ireland": ["ireland", "irlande", "ie"],
    "Czech Republic": ["czech republic", "republique tcheque", "tchéquie", "cz"],
    "Hungary": ["hungary", "hongrie", "hu"],
    "Romania": ["romania", "roumanie", "ro"],
    "Ukraine": ["ukraine", "ua"],
    "Israel": ["israel", "il"],
    "United Arab Emirates": ["united arab emirates", "emirats arabes unis", "eaus", "ae", "dubai"],
    "Saudi Arabia": ["saudi arabia", "arabie saoudite", "sa"],
    "Singapore": ["singapore", "singapour", "sg"],
    "Malaysia": ["malaysia", "malaisie", "my"],
    "Philippines": ["philippines", "ph"],
    "New Zealand": ["new zealand", "nouvelle zelande", "nz"],
    "South Africa": ["south africa", "afrique du sud", "za"],
    "Senegal": ["senegal", "sénégal", "sn"],
    "Ivory Coast": ["ivory coast", "cote d ivoire", "côte d'ivoire", "ci"],
    "Nigeria": ["nigeria", "ng"],
    "Kenya": ["kenya", "ke"],
    "Peru": ["peru", "perou", "pérou", "pe"],
    "Chile": ["chile", "chili", "cl"],
    "Colombia": ["colombia", "colombie", "co"],
}

ISO_COUNTRY_NAMES: dict[str, str] = {
    "FR": "France",
    "DE": "Germany",
    "ES": "Spain",
    "IT": "Italy",
    "GB": "United Kingdom",
    "CH": "Switzerland",
    "BE": "Belgium",
    "NL": "Netherlands",
    "AT": "Austria",
    "PT": "Portugal",
    "PL": "Poland",
    "CZ": "Czech Republic",
    "HU": "Hungary",
    "RO": "Romania",
    "SE": "Sweden",
    "NO": "Norway",
    "DK": "Denmark",
    "IE": "Ireland",
    "GR": "Greece",
    "TR": "Turkey",
    "UA": "Ukraine",
    "HR": "Croatia",
    "RS": "Serbia",
    "BG": "Bulgaria",
    "SK": "Slovakia",
    "LT": "Lithuania",
    "LU": "Luxembourg",
    "FI": "Finland",
}


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = text.lower().replace("-", " ").replace("'", " ")
    return re.sub(r"\s+", " ", text).strip()


def slugify(text: str) -> str:
    base = normalize(text)
    base = re.sub(r"[^a-z0-9]+", "-", base).strip("-")
    return base[:48] or "place"


def extract_country(subtitle: str) -> str | None:
    parts = [p.strip() for p in subtitle.split("·")]
    if len(parts) >= 2:
        return parts[1]
    return None


def enrich_keywords(place: dict) -> None:
    keywords = set(place.get("keywords") or [])
    keywords.add(normalize(place["name"]))
    for token in re.split(r"[\s·,]+", place.get("subtitle", "")):
        if token:
            keywords.add(normalize(token))
    country = extract_country(place.get("subtitle", ""))
    if country and country in COUNTRY_ALIASES:
        keywords.update(normalize(a) for a in COUNTRY_ALIASES[country])
        keywords.add(normalize(country))
    place["keywords"] = sorted(k for k in keywords if k)


def load_trainline_stations() -> list[dict]:
    if not TRAINLINE_CSV.exists():
        print("Skip trains: stations.csv not found at", TRAINLINE_CSV)
        return []
    seen: set[str] = set()
    out: list[dict] = []
    with TRAINLINE_CSV.open(encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            if row.get("is_airport") == "t":
                continue
            if row.get("is_suggestable") != "t":
                continue
            name = (row.get("info:fr") or row.get("info:en") or row.get("name") or "").strip()
            if not name or len(name) > 80:
                continue
            cc = row.get("country", "").strip()
            country = ISO_COUNTRY_NAMES.get(cc, cc)
            city = name
            subtitle = f"{city} · {country}" if country else city
            key = normalize(f"{name}|{country}")
            if key in seen:
                continue
            seen.add(key)
            pid = f"tr-{slugify(name)}-{cc.lower()}"
            keywords = {normalize(name), normalize(country), normalize(city)}
            if country in COUNTRY_ALIASES:
                keywords.update(normalize(a) for a in COUNTRY_ALIASES[country])
            out.append(
                {
                    "id": pid,
                    "name": name,
                    "subtitle": subtitle,
                    "mode": "train",
                    "keywords": sorted(keywords),
                }
            )
    print(f"Train stations: {len(out)}")
    return out


def major_ports() -> list[dict]:
    """Ports majeurs mondiaux (complète le catalogue + recherche par pays)."""
    raw = [
        ("Port de Tokyo", "Tokyo", "Japan"),
        ("Port de Yokohama", "Yokohama", "Japan"),
        ("Port d'Osaka", "Osaka", "Japan"),
        ("Port de Nagoya", "Nagoya", "Japan"),
        ("Port de Kobe", "Kobe", "Japan"),
        ("Port de Shanghai", "Shanghai", "China"),
        ("Port de Shenzhen", "Shenzhen", "China"),
        ("Port de Hong Kong", "Hong Kong", "China"),
        ("Port de Singapour", "Singapour", "Singapore"),
        ("Port de Busan", "Busan", "South Korea"),
        ("Port de Mumbai", "Mumbai", "India"),
        ("Port de Colombo", "Colombo", "Sri Lanka"),
        ("Port de Sydney", "Sydney", "Australia"),
        ("Port de Melbourne", "Melbourne", "Australia"),
        ("Port de Auckland", "Auckland", "New Zealand"),
        ("Port de Los Angeles", "Los Angeles", "United States"),
        ("Port de New York", "New York", "United States"),
        ("Port de Miami", "Miami", "United States"),
        ("Port de Santos", "Santos", "Brazil"),
        ("Port de Buenos Aires", "Buenos Aires", "Argentina"),
        ("Port de Valparaiso", "Valparaiso", "Chile"),
        ("Port de Vancouver", "Vancouver", "Canada"),
        ("Port de Halifax", "Halifax", "Canada"),
        ("Port de Rotterdam", "Rotterdam", "Netherlands"),
        ("Port d'Anvers", "Anvers", "Belgium"),
        ("Port de Hambourg", "Hambourg", "Germany"),
        ("Port de Bremerhaven", "Bremerhaven", "Germany"),
        ("Port de Marseille", "Marseille", "France"),
        ("Port du Havre", "Le Havre", "France"),
        ("Port de Barcelone", "Barcelone", "Spain"),
        ("Port de Valence", "Valence", "Spain"),
        ("Port de Gênes", "Genes", "Italy"),
        ("Port de Naples", "Naples", "Italy"),
        ("Port de Pirée", "Piree", "Greece"),
        ("Port d'Istanbul", "Istanbul", "Turkey"),
        ("Port d'Alexandrie", "Alexandrie", "Egypt"),
        ("Port de Casablanca", "Casablanca", "Morocco"),
        ("Port de Tanger Med", "Tanger", "Morocco"),
        ("Port de Dakar", "Dakar", "Senegal"),
        ("Port de Durban", "Durban", "South Africa"),
        ("Port de Jeddah", "Jeddah", "Saudi Arabia"),
        ("Port de Dubaï", "Dubai", "United Arab Emirates"),
        ("Port de Doha", "Doha", "Qatar"),
    ]
    out = []
    for name, city, country in raw:
        subtitle = f"{city} · {country}"
        keywords = {normalize(name), normalize(city), normalize(country), "port"}
        if country in COUNTRY_ALIASES:
            keywords.update(normalize(a) for a in COUNTRY_ALIASES[country])
        out.append(
            {
                "id": f"prt-{slugify(city)}-{slugify(country)}",
                "name": name,
                "subtitle": subtitle,
                "mode": "boat",
                "keywords": sorted(keywords),
            }
        )
    return out


def main() -> None:
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    places: list[dict] = data.get("places", [])

    planes = [p for p in places if p.get("mode") == "plane"]
    existing_boat = {p["id"] for p in places if p.get("mode") == "boat"}
    existing_train_ids = {p["id"] for p in places if p.get("mode") == "train"}

    for p in planes:
        enrich_keywords(p)

    boats = [p for p in places if p.get("mode") == "boat"]
    for b in major_ports():
        if b["id"] not in existing_boat:
            enrich_keywords(b)
            boats.append(b)

    for b in boats:
        enrich_keywords(b)

    trains = [p for p in places if p.get("mode") == "train"]
    for t in load_trainline_stations():
        if t["id"] not in existing_train_ids:
            enrich_keywords(t)
            trains.append(t)
            existing_train_ids.add(t["id"])

    merged = planes + boats + trains
    JSON_PATH.write_text(
        json.dumps({"places": merged}, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {len(merged)} places → {JSON_PATH}")
    print(f"  plane: {len(planes)}, boat: {len(boats)}, train: {len(trains)}")


if __name__ == "__main__":
    main()
