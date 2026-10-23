"""Aplica la regla CORS del bucket R2 `synaptixfit` (r2-cors.json) con la API de Cloudflare.

El cliente web sube y descarga los archivos directamente de R2 con URLs prefirmadas; sin esta regla
el navegador bloquea la petición (preflight 403). El token se lee de
%USERPROFILE%/.config/synaptixfit/cloudflare.env (CLOUDFLARE_API_TOKEN, con permiso
«Workers R2 Storage: Edit») y nunca se imprime.

    python infra/cloudflare/aplicar-r2-cors.py
"""
import json
import os
import pathlib
import urllib.error
import urllib.request

ENV = pathlib.Path(os.environ["USERPROFILE"]) / ".config" / "synaptixfit" / "cloudflare.env"
TOKEN = next(l.split("=", 1)[1].strip() for l in ENV.read_text(encoding="utf-8").splitlines()
             if l.startswith("CLOUDFLARE_API_TOKEN="))
RULES = json.loads((pathlib.Path(__file__).parent / "r2-cors.json").read_text(encoding="utf-8"))
API = "https://api.cloudflare.com/client/v4"


def cf(method, path, body=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.load(e)


account = cf("GET", "/zones?name=jloenit.dev")["result"][0]["account"]["id"]
res = cf("PUT", f"/accounts/{account}/r2/buckets/synaptixfit/cors", RULES)
print("CORS aplicada:", res.get("success"), res.get("errors") or "")
print("CORS actual:", json.dumps(cf("GET", f"/accounts/{account}/r2/buckets/synaptixfit/cors").get("result"), ensure_ascii=False))
