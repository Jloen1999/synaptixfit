#!/usr/bin/env python3
"""
Seed del catálogo académico v2 (8 tablas normalizadas).

Lee grados.json desde la raíz del proyecto e inserta los datos en:
  universidades, centros, carreras, asignaturas_catalogo,
  profesores_asignatura, prerrequisitos_asignatura,
  criterios_evaluacion, bibliografia_asignatura.

Requisitos previos:
  - Tener las migraciones 0053 y 0054 aplicadas en Supabase.
  - Archivo .env con SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY.

Uso:
  python supabase/seed_catalogo_v2.py
"""

import json
import os
import sys

# ---------------------------------------------------------------------------
# Verificación de dependencias
# ---------------------------------------------------------------------------
try:
    from dotenv import load_dotenv  # noqa: F811
    from supabase import Client, create_client
except ImportError:
    print(
        "ERROR: Faltan dependencias. Ejecutá:"
        " pip install python-dotenv supabase"
    )
    sys.exit(1)

# ---------------------------------------------------------------------------
# Configuración desde .env
# ---------------------------------------------------------------------------
# Ruta absoluta a grados.json (raíz del proyecto)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
JSON_PATH = os.path.join(PROJECT_ROOT, "grados.json")

# Cargar .env: primero app/.env (fuente principal), luego raíz
env_paths = [
    os.path.join(PROJECT_ROOT, "app", ".env"),
    os.path.join(PROJECT_ROOT, ".env"),
]
for p in env_paths:
    if os.path.exists(p):
        load_dotenv(p)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print("ERROR: Definí SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en app/.env")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SENTINEL = "No especificado en las fuentes"


def _es_no_especificado(valor):
    """Detecta el valor centinela del dataset scrapeado."""
    return isinstance(valor, str) and valor.strip() == SENTINEL


def _null_si_centinela(valor):
    """Convierte el centinela a None; deja pasar cualquier otro valor."""
    return None if _es_no_especificado(valor) else valor


def _upsert_obtener_id(tabla, datos, on_conflict):
    """
    Inserta o actualiza una fila y devuelve su id.
    Si upsert no devuelve datos (caso borde), hace un SELECT de respaldo.
    """
    resp = (
        supabase.table(tabla).upsert(datos, on_conflict=on_conflict).execute()
    )
    if resp.data and len(resp.data) > 0:
        return resp.data[0]["id"]

    # Fallback: la fila ya existía y upsert no la devolvió
    # Construimos un query con los campos del on_conflict + nombre
    query = supabase.table(tabla).select("id")
    for campo in on_conflict.split(","):
        query = query.eq(campo.strip(), datos[campo.strip()])
    query = query.limit(1)

    fallback = None
    try:
        fallback = query.single().execute()
    except Exception:
        # .single() lanza si no hay resultado; intentamos sin .single()
        try:
            fallback = query.execute()
        except Exception:
            pass

    if fallback and fallback.data:
        if isinstance(fallback.data, list):
            return fallback.data[0]["id"]
        return fallback.data["id"]

    raise RuntimeError(
        f"No se pudo obtener id para {tabla} con {datos} (conflict={on_conflict})"
    )


# ---------------------------------------------------------------------------
# Principal
# ---------------------------------------------------------------------------

def main():
    if not os.path.exists(JSON_PATH):
        print(f"ERROR: No se encuentra {JSON_PATH}")
        sys.exit(1)

    with open(JSON_PATH, "r", encoding="utf-8") as f:
        grados = json.load(f)

    total_carreras = 0
    total_asignaturas = 0
    total_profesores = 0
    total_prerrequisitos = 0
    total_bibliografia = 0

    print(f"Catalogo: {len(grados)} carreras por procesar\n")

    for idx, grado in enumerate(grados, 1):
        nombre_uni = grado["universidad"]
        nombre_centro = grado["centro_facultad"]
        nombre_carrera = grado["carrera"]
        total_creditos = grado.get("total_creditos")
        total_horas = grado.get("total_horas")
        asignaturas = grado.get("asignaturas", [])

        print(f"[{idx:3d}/{len(grados)}] {nombre_uni} — {nombre_carrera}")

        # 1. Universidad — ON CONFLICT (nombre) DO NOTHING
        universidad_id = _upsert_obtener_id(
            "universidades",
            {"nombre": nombre_uni},
            "nombre",
        )

        # 2. Centro — ON CONFLICT (universidad_id, nombre) DO NOTHING
        centro_id = _upsert_obtener_id(
            "centros",
            {"universidad_id": universidad_id, "nombre": nombre_centro},
            "universidad_id, nombre",
        )

        # 3. Carrera — ON CONFLICT (centro_id, nombre) DO NOTHING
        carrera_id = _upsert_obtener_id(
            "carreras",
            {
                "centro_id": centro_id,
                "nombre": nombre_carrera,
                "total_creditos": total_creditos,
                "total_horas": total_horas,
            },
            "centro_id, nombre",
        )
        total_carreras += 1

        # 4–8. Asignaturas y tablas hijas
        for asig in asignaturas:
            nombre_asig = asig["nombre"]

            # 4. Asignatura catálogo
            # Convierte horas a int si es float (columna es integer)
            _horas_raw = asig.get("horas")
            _horas = int(round(_horas_raw)) if isinstance(_horas_raw, float) else _horas_raw

            campos_asig = {
                "carrera_id": carrera_id,
                "nombre": nombre_asig,
                "curso": asig.get("curso"),
                "semestre": asig.get("semestre"),
                "caracter": _null_si_centinela(asig.get("caracter")),
                "creditos": asig.get("creditos"),
                "horas": _horas,
                "departamento": _null_si_centinela(asig.get("departamento")),
                "idioma_imparticion": _null_si_centinela(
                    asig.get("idioma_imparticion")
                ),
                "url_guia_docente": _null_si_centinela(
                    asig.get("url_guia_docente")
                ),
            }
            asignatura_id = _upsert_obtener_id(
                "asignaturas_catalogo",
                campos_asig,
                "carrera_id, nombre",
            )

            # 5. Profesores — upsert por (asignatura_id, nombre_completo)
            for nombre_prof in asig.get("profesores_coordinadores", []):
                try:
                    _upsert_obtener_id(
                        "profesores_asignatura",
                        {
                            "asignatura_id": asignatura_id,
                            "nombre_completo": nombre_prof,
                        },
                        "asignatura_id, nombre_completo",
                    )
                    total_profesores += 1
                except Exception as e:
                    print(f"    ⚠  Profesor «{nombre_prof}»: {e}")

            # 6. Prerrequisitos — insert simple (sin conflict, admite duplicados)
            for nombre_pre in asig.get("prerrequisitos", []):
                try:
                    supabase.table("prerrequisitos_asignatura").insert({
                        "asignatura_id": asignatura_id,
                        "nombre_asignatura": nombre_pre,
                    }).execute()
                    total_prerrequisitos += 1
                except Exception as e:
                    print(f"    ⚠  Prerrequisito «{nombre_pre}»: {e}")

            # 7. Criterios evaluación — ON CONFLICT (asignatura_id) DO NOTHING
            criterios = asig.get("criterios_evaluacion", {})
            if criterios:
                try:
                    _upsert_obtener_id(
                        "criterios_evaluacion",
                        {
                            "asignatura_id": asignatura_id,
                            "examen_final_porcentaje": criterios.get(
                                "examen_final_porcentaje", 0
                            ),
                            "evaluacion_continua_porcentaje": criterios.get(
                                "evaluacion_continua_porcentaje", 0
                            ),
                            "practicas_laboratorio_porcentaje": criterios.get(
                                "practicas_laboratorio_porcentaje", 0
                            ),
                        },
                        "asignatura_id",
                    )
                except Exception as e:
                    print(f"    ⚠  Criterios evaluación: {e}")

            # 8. Bibliografía — insert simple
            for ref in asig.get("bibliografia_basica", []):
                try:
                    supabase.table("bibliografia_asignatura").insert({
                        "asignatura_id": asignatura_id,
                        "referencia": ref,
                    }).execute()
                    total_bibliografia += 1
                except Exception as e:
                    ref_truncado = ref[:60] + ("…" if len(ref) > 60 else "")
                    print(f"    ⚠  Bibliografía «{ref_truncado}»: {e}")

            total_asignaturas += 1

        print(
            f"       OK {len(asignaturas)} asignaturas | "
            f"uni={universidad_id[:8]}… centro={centro_id[:8]}…"
        )

    # -------------------------------------------------------------------
    # Resumen
    # -------------------------------------------------------------------
    sep = "=" * 55
    print(f"\n{sep}")
    print("  Seed del catálogo v2 completado")
    print(sep)
    print(f"  Carreras procesadas:      {total_carreras:>5}")
    print(f"  Asignaturas insertadas:   {total_asignaturas:>5}")
    print(f"  Profesores:               {total_profesores:>5}")
    print(f"  Prerrequisitos:           {total_prerrequisitos:>5}")
    print(f"  Referencias bibliografía: {total_bibliografia:>5}")
    print(sep)


if __name__ == "__main__":
    main()
