"""Utilidades comunes de los scripts demo: cliente HTTP de la API, contraseña, zona horaria y ejecución de SQL.

Lo usan seed_demo.py, purge_demo.py y run_sql.py. Solo librería estándar de Python 3.
"""
from __future__ import annotations

import email.utils
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import date, datetime, time as dtime, timedelta, timezone
from zoneinfo import ZoneInfo

DOMAIN = "demo.synaptixfit.test"
MADRID = ZoneInfo("Europe/Madrid")
# Cloudflare bloquea el agente de usuario de Python (error 1010): los scripts se identifican así.
USER_AGENT = "Mozilla/5.0 SynaptixFit-demo"
HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_PASSWORD_FILE = pathlib.Path.home() / ".config" / "synaptixfit" / "demo.env"

LOCAL_CONTAINER = "synaptixfit-db-1"
PROD_SSH_HOST = "infra-ovh"
PROD_DB_CONTAINER = "rnqvtuszzmxtfcb5ptvunlsp"


def demo_email(local_part: str) -> str:
    return f"{local_part}@{DOMAIN}"


def load_password(env_name: str, password_file: pathlib.Path | None = DEFAULT_PASSWORD_FILE) -> str:
    """Lee la contraseña demo de la variable de entorno o, si falta, del fichero demo.env. Nunca se imprime."""
    value = os.environ.get(env_name)
    if not value and password_file and password_file.exists():
        for line in password_file.read_text(encoding="utf-8").splitlines():
            if line.strip().startswith(f"{env_name}="):
                value = line.split("=", 1)[1].strip()
    if not value:
        sys.exit(f"Falta la contraseña demo: define {env_name} o créala en {password_file}.")
    return value


# --------------------------------------------------------------------------------------------- tiempo

def madrid(d: date, hh: int = 0, mm: int = 0) -> datetime:
    return datetime.combine(d, dtime(hh, mm), tzinfo=MADRID)


def iso(dt: datetime) -> str:
    """Instante ISO-8601 en UTC con «Z», como lo espera la API."""
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def monday_of(d: date) -> date:
    return d - timedelta(days=d.weekday())


# ----------------------------------------------------------------------------------------- cliente HTTP

class ApiError(Exception):
    def __init__(self, method: str, path: str, status: int, body):
        self.status = status
        self.body = body
        self.code = body.get("code") if isinstance(body, dict) else None
        super().__init__(f"{method} {path} -> {status} {json.dumps(body, ensure_ascii=False)[:600]}")


class Api:
    """Cliente mínimo de la API REST. Guarda la hora del servidor (cabecera Date) de la última respuesta."""

    def __init__(self, base_url: str, verbose: bool = False):
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose
        self.server_time: datetime | None = None
        self.calls = 0

    def request(self, method: str, path: str, body=None, token: str | None = None, retries: int = 3):
        headers = {"User-Agent": USER_AGENT, "Accept": "application/json"}
        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        if token:
            headers["Authorization"] = f"Bearer {token}"
        url = self.base_url + path
        for attempt in range(retries + 1):
            req = urllib.request.Request(url, data=data, method=method, headers=headers)
            try:
                with urllib.request.urlopen(req, timeout=180) as resp:
                    self.calls += 1
                    self._remember_date(resp.headers.get("Date"))
                    raw = resp.read().decode("utf-8")
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as e:
                self.calls += 1
                self._remember_date(e.headers.get("Date") if e.headers else None)
                raw = e.read().decode("utf-8", "replace")
                try:
                    payload = json.loads(raw)
                except ValueError:
                    payload = raw[:500]
                if e.code in (429, 502, 503, 504) and attempt < retries:
                    time.sleep(2 * (attempt + 1))
                    continue
                raise ApiError(method, path, e.code, payload) from None
            except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
                if attempt < retries:
                    time.sleep(2 * (attempt + 1))
                    continue
                raise ApiError(method, path, 0, str(e)) from None
        raise AssertionError("inalcanzable")

    def _remember_date(self, value: str | None):
        if value:
            try:
                self.server_time = email.utils.parsedate_to_datetime(value)
            except (TypeError, ValueError):
                pass


class UserSession:
    """Sesión de un usuario demo: inicia sesión con email y contraseña y la renueva si caduca (401)."""

    def __init__(self, api: Api, email_addr: str, password: str):
        self.api = api
        self.email = email_addr
        self.password = password
        self.token: str | None = None
        self.user: dict | None = None

    def login(self) -> dict:
        res = self.api.request("POST", "/api/v1/auth/login", {"email": self.email, "password": self.password})
        self.token = res["accessToken"]
        self.user = res["user"]
        return res

    def register(self, full_name: str) -> dict:
        res = self.api.request("POST", "/api/v1/auth/register",
                               {"email": self.email, "password": self.password, "fullName": full_name})
        self.token = res["accessToken"]
        self.user = res["user"]
        return res

    @property
    def user_id(self) -> str:
        return self.user["id"]

    def call(self, method: str, path: str, body=None):
        try:
            return self.api.request(method, path, body, self.token)
        except ApiError as e:
            if e.status != 401:
                raise
            self.login()
            return self.api.request(method, path, body, self.token)

    def get(self, path):
        return self.call("GET", path)

    def post(self, path, body=None):
        return self.call("POST", path, body)

    def put(self, path, body=None):
        return self.call("PUT", path, body)

    def patch(self, path, body=None):
        return self.call("PATCH", path, body)

    def delete(self, path, body=None):
        return self.call("DELETE", path, body)


# ----------------------------------------------------------------------------------------------- SQL

_SAFE_VALUE = re.compile(r"^[\w@.,:+\- ]*$")


def _ssh_binary() -> str:
    """En Windows se usa el OpenSSH del sistema (el de Git Bash no tiene la clave del propietario)."""
    if os.name == "nt":
        candidate = pathlib.Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32" / "OpenSSH" / "ssh.exe"
        if candidate.exists():
            return str(candidate)
    return shutil.which("ssh") or "ssh"


class SqlRunner:
    """Ejecuta un script SQL con psql en la BD local (docker exec) o en la de producción (ssh + docker exec).

    Las variables se pasan como líneas «\\set» al principio del script, así la orden remota es fija y no hay
    que escapar nada. En producción las credenciales se leen en el servidor (/root/synaptixfit/db-app.env)
    y nunca salen de él.
    """

    def __init__(self, target: str, local_container: str = LOCAL_CONTAINER, ssh_host: str = PROD_SSH_HOST,
                 prod_container: str = PROD_DB_CONTAINER):
        if target not in ("local", "prod", "none"):
            raise ValueError("target debe ser local, prod o none")
        self.target = target
        self.local_container = local_container
        self.ssh_host = ssh_host
        self.prod_container = prod_container

    @property
    def enabled(self) -> bool:
        return self.target != "none"

    def _command(self) -> list[str]:
        if self.target == "local":
            return ["docker", "exec", "-i", self.local_container, "psql", "-X", "-q", "-v", "ON_ERROR_STOP=1",
                    "-U", "synaptixfit", "-d", "synaptixfit", "-At", "-f", "-"]
        remote = ("sudo bash -c 'set -a; . /root/synaptixfit/db-app.env; set +a; export PGPASSWORD=\"$DB_PASSWORD\"; "
                  f"exec docker exec -i -e PGPASSWORD {self.prod_container} psql -X -q -v ON_ERROR_STOP=1 "
                  "-h 127.0.0.1 -U \"$DB_USERNAME\" -d \"$DB_DATABASE\" -At -f -'")
        return [_ssh_binary(), "-o", "BatchMode=yes", self.ssh_host, remote]

    def run(self, sql: str, variables: dict | None = None) -> str:
        if not self.enabled:
            raise RuntimeError("Sin acceso a la base de datos (--db none)")
        header = []
        for name, value in (variables or {}).items():
            text = str(value)
            if not _SAFE_VALUE.match(text):
                raise ValueError(f"Valor no permitido para la variable {name}")
            header.append(f"\\set {name} '{text}'")
        script = "\n".join(header) + "\n" + sql
        result = subprocess.run(self._command(), input=script.encode("utf-8"), capture_output=True, timeout=600)
        if result.returncode != 0:
            raise RuntimeError(f"psql falló ({self.target}): {result.stderr.decode('utf-8', 'replace')[:2000]}")
        return result.stdout.decode("utf-8", "replace")

    def run_file(self, name: str, variables: dict | None = None) -> str:
        return self.run((HERE / name).read_text(encoding="utf-8"), variables)
