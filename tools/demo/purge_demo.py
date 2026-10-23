#!/usr/bin/env python3
"""Borra los usuarios demo de SynaptixFit (todas sus filas) para poder volver a sembrarlos desde cero.

Cada cuenta se borra a sí misma con el endpoint RGPD (DELETE /api/v1/me con contraseña y confirmación), que
elimina sus datos de todos los módulos en una transacción. Si la cuenta admin demo fuera el último
administrador, primero se le quita el rol con set_role.sql (necesita --db).

Uso:
    python tools/demo/purge_demo.py --base-url http://localhost:8080 --db local
    python tools/demo/purge_demo.py --base-url https://synaptixfit.jloenit.dev --db prod --yes
"""
from __future__ import annotations

import argparse
import sys

from demo_lib import DOMAIN, Api, ApiError, SqlRunner, UserSession, demo_email, load_password
from personas import PERSONAS


def main():
    p = argparse.ArgumentParser(description="Borra los usuarios demo de SynaptixFit.")
    p.add_argument("--base-url", default="http://localhost:8080")
    p.add_argument("--password-env", default="DEMO_PASSWORD")
    p.add_argument("--only", action="append", default=[], help="Email o clave de persona (repetible)")
    p.add_argument("--db", choices=["local", "prod", "none"], default="none",
                   help="Solo hace falta para quitar el rol de administrador a la cuenta admin demo")
    p.add_argument("--yes", action="store_true", help="No pedir confirmación")
    args = p.parse_args()

    specs = PERSONAS
    if args.only:
        wanted = {o.split("@")[0].casefold() for o in args.only}
        specs = [x for x in PERSONAS if x["key"] in wanted or x["email"].casefold() in wanted]
    emails = [demo_email(x["email"]) for x in specs]
    if not args.yes:
        answer = input(f"Se borrarán {len(emails)} cuentas @{DOMAIN} en {args.base_url}. ¿Seguir? [s/N] ")
        if answer.strip().lower() not in ("s", "si", "sí", "y", "yes"):
            sys.exit("Cancelado.")

    password = load_password(args.password_env)
    api = Api(args.base_url)
    sql = SqlRunner(args.db)
    deleted = 0
    for spec, email_addr in zip(specs, emails):
        session = UserSession(api, email_addr, password)
        try:
            session.login()
        except ApiError as e:
            print(f"= {email_addr}: no existe o no se puede entrar ({e.code or e.status})")
            continue
        body = {"password": password, "confirm": True}
        try:
            session.delete("/api/v1/me", body)
        except ApiError as e:
            if e.code != "GDPR_LAST_ADMIN" or not sql.enabled:
                print(f"! {email_addr}: {e}")
                continue
            sql.run_file("set_role.sql", {"email": email_addr, "role": "usuario"})
            session.login()
            session.delete("/api/v1/me", body)
        deleted += 1
        print(f"- {email_addr} borrada")
    print(f"{deleted} cuentas borradas.")


if __name__ == "__main__":
    main()
