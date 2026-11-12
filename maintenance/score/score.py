"""Calcula scores relativos de impacto de contexto para mantenimiento del arnés."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_EVENTS = Path(__file__).with_name("events.jsonl")
WEIGHT_FIELDS = ("passive_weight", "invoked_weight", "savings_weight")


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"{path}:{line_number}: JSON inválido: {exc}") from exc
        validate_event(event, path, line_number)
        events.append(event)
    return events


def validate_event(event: dict[str, Any], path: Path, line_number: int) -> None:
    required = {
        "id",
        "date",
        "source",
        "ref",
        "category",
        "surface",
        "passive_weight",
        "invoked_weight",
        "savings_weight",
        "note",
    }
    missing = sorted(required - set(event))
    if missing:
        raise SystemExit(f"{path}:{line_number}: faltan campos: {', '.join(missing)}")
    for field in WEIGHT_FIELDS:
        value = event[field]
        if not isinstance(value, (int, float)) or value < 0:
            raise SystemExit(f"{path}:{line_number}: {field} debe ser número >= 0")


def normalize(events: list[dict[str, Any]]) -> dict[str, Any]:
    totals = {field: sum(float(event[field]) for event in events) for field in WEIGHT_FIELDS}
    normalized_events: list[dict[str, Any]] = []
    for event in events:
        scores = {}
        for field in WEIGHT_FIELDS:
            total = totals[field]
            score_field = field.replace("_weight", "_score")
            scores[score_field] = round((float(event[field]) / total) * 100, 2) if total else 0.0
        normalized_events.append({**event, **scores})
    return {"totals": totals, "events": normalized_events}


def render_text(result: dict[str, Any]) -> str:
    lines = [
        "Score relativo de impacto de contexto",
        "",
        "Totales brutos:",
    ]
    for field in WEIGHT_FIELDS:
        lines.append(f"- {field}: {format_number(result['totals'][field])}")
    lines.extend(["", "Eventos:"])
    for event in result["events"]:
        lines.append(
            " - {id} {ref} {surface}: "
            "pasivo={passive_score:g}, invocado={invoked_score:g}, ahorro={savings_score:g}".format(
                **event
            )
        )
    return "\n".join(lines)


def format_number(value: float) -> str:
    return str(int(value)) if value.is_integer() else str(value)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", type=Path, default=DEFAULT_EVENTS, help="Archivo JSONL de eventos")
    parser.add_argument("--json", action="store_true", help="Emitir resultado JSON")
    args = parser.parse_args()

    events = load_events(args.events)
    result = normalize(events)
    if args.json:
        print(json.dumps(result, ensure_ascii=True, indent=2))
    else:
        print(render_text(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
