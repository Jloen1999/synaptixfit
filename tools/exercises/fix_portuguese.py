"""Segunda pasada: portugués de Portugal y términos de vocabulario que faltaban.

- «halter» → «haltere» (en Portugal el singular es haltere; «halteres» vale en los dos).
- Los nombres con «rosca» (término de Brasil) se reescriben con la IA usando «curl», que es lo que se
  dice en los ginásios portugueses, concordando el género («curl concentrado»).
- Pide uno a uno los términos de vocabulario que la IA se saltó en lotes.

Uso (desde la raíz):  py -I tools/exercises/fix_portuguese.py
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from translate_names import DATA, OUT, OUT_VOCAB, VOCAB_PROMPT, api_key, call, clean  # noqa: E402

PT_PROMPT = """Rewrite these exercise names from Brazilian Portuguese into European Portuguese (Portugal) as used in Portuguese gyms. In Portugal the biceps/hammer/concentration movements are called "curl" (masculine): "Rosca direta com barra" -> "Curl de bíceps com barra", "Rosca martelo" -> "Curl martelo", "Rosca concentrada" -> "Curl concentrado", "Rosca inversa" -> "Curl inverso", "Rosca Scott" -> "Curl Scott". Keep everything else (equipment, grip, position) and adjust gender agreement. Use "haltere" (singular) / "halteres" (plural). Sentence case.
Return ONLY JSON: {"ejercicios": [{"id": "...", "pt": "..."}]}"""


def main():
    key = api_key()
    names = json.loads(OUT.read_text(encoding="utf-8"))
    for v in names.values():
        v["pt"] = re.sub(r"\bhalter\b", "haltere", v["pt"])
    pending = [{"id": k, "pt": v["pt"], "es_reference": None} for k, v in names.items()
               if re.search(r"\broscas?\b", v["pt"], re.I)]
    print(f"nombres con «rosca»: {len(pending)}", flush=True)
    for i in range(0, len(pending), 50):
        for x in call(key, PT_PROMPT, pending[i:i + 50], "ejercicios"):
            if x.get("id") in names and x.get("pt"):
                names[x["id"]]["pt"] = clean(x["pt"])
    left = sum(1 for v in names.values() if re.search(r"\broscas?\b", v["pt"], re.I))
    print(f"quedan con «rosca»: {left}", flush=True)
    OUT.write_text(json.dumps(names, ensure_ascii=False, indent=1), encoding="utf-8")

    vocab = json.loads((DATA / "vocabulario_bd.json").read_text(encoding="utf-8"))
    terms = sorted({t for group in vocab.values() for t in group})
    result = json.loads(OUT_VOCAB.read_text(encoding="utf-8"))
    for term in [t for t in terms if t not in result]:
        got = call(key, VOCAB_PROMPT, [term], "terminos")
        if got and all(got[0].get(k) for k in ("en", "fr", "pt")):
            # Un solo término: se acepta aunque la IA normalice el «es» devuelto.
            result[term] = {k: clean(got[0][k]) for k in ("en", "fr", "pt")}
    for v in result.values():
        v["pt"] = re.sub(r"\bhalter\b", "haltere", v["pt"])
    print(f"vocabulario: {len(result)} de {len(terms)}", flush=True)
    OUT_VOCAB.write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
