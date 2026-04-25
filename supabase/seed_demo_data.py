#!/usr/bin/env python3
"""
seed_demo_data.py - Crea un set de datos demo realistas para SynaptixFit.

Puebla usuarios, perfil de bienestar, asignaturas, horarios, sesiones,
retos, hitos, actividades sociales, interacciones y notificaciones.

Uso:
    python seed_demo_data.py

Requiere:
    - SUPABASE_URL
    - SUPABASE_SERVICE_ROLE_KEY
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

try:
    from supabase import Client, create_client
except ImportError:
    print("❌ Falta la librería 'supabase'. Instala con: python -m pip install supabase")
    sys.exit(1)

try:
    from dotenv import load_dotenv
except ImportError:
    pass
else:
    script_dir = Path(__file__).resolve().parent
    workspace_root = script_dir.parent
    candidate_env_files = [
        script_dir / ".env",
        workspace_root / ".env",
        workspace_root / "app" / ".env",
    ]

    for env_file in candidate_env_files:
        if env_file.exists():
            load_dotenv(env_file, override=False)
            break
    else:
        load_dotenv(override=False)

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ Falta SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en las variables de entorno.")
    sys.exit(1)


@dataclass(frozen=True)
class DemoUser:
    email: str
    password: str
    full_name: str
    avatar_url: str
    privacy: str = "publico"
    nivel: int = 1
    xp_total: int = 0
    racha_actual: int = 0


DEMO_USERS = [
    DemoUser(
        email="lucia.navarro.synaptixfit+1@gmail.com",
        password="Password123!",
        full_name="Lucia Navarro",
        avatar_url="https://api.dicebear.com/7.x/avataaars/svg?seed=LuciaNavarro",
        nivel=4,
        xp_total=320,
        racha_actual=9,
    ),
    DemoUser(
        email="bruno.romero.synaptixfit+2@gmail.com",
        password="Password123!",
        full_name="Bruno Romero",
        avatar_url="https://api.dicebear.com/7.x/avataaars/svg?seed=BrunoRomero",
        nivel=3,
        xp_total=180,
        racha_actual=4,
    ),
    DemoUser(
        email="sofia.quezada.synaptixfit+3@gmail.com",
        password="Password123!",
        full_name="Sofia Quezada",
        avatar_url="https://api.dicebear.com/7.x/avataaars/svg?seed=SofiaQuezada",
        nivel=5,
        xp_total=540,
        racha_actual=12,
    ),
    DemoUser(
        email="mateo.rincon.synaptixfit+4@gmail.com",
        password="Password123!",
        full_name="Mateo Rincon",
        avatar_url="https://api.dicebear.com/7.x/avataaars/svg?seed=MateoRincon",
        nivel=2,
        xp_total=90,
        racha_actual=2,
    ),
    DemoUser(
        email="valeria.castro.synaptixfit+5@gmail.com",
        password="Password123!",
        full_name="Valeria Castro",
        avatar_url="https://api.dicebear.com/7.x/avataaars/svg?seed=ValeriaCastro",
        nivel=4,
        xp_total=410,
        racha_actual=7,
    ),
]

ACADEMIC_SUBJECTS = {
    "Lucia Navarro": [
        {"nombre": "Programación Móvil", "codigo": "INF-401", "descripcion": "Proyecto final de Flutter y persistencia local."},
        {"nombre": "Bioestadística", "codigo": "BIO-210", "descripcion": "Análisis de datos para el laboratorio de bienestar."},
        {"nombre": "Inglés Técnico", "codigo": "ING-102", "descripcion": "Lectura de documentación y vocabulario técnico."},
    ],
    "Bruno Romero": [
        {"nombre": "Bases de Datos", "codigo": "INF-305", "descripcion": "Diseño de esquema y optimización de consultas."},
        {"nombre": "Redacción Académica", "codigo": "COM-118", "descripcion": "Ensayo y presentación oral."},
    ],
    "Sofia Quezada": [
        {"nombre": "Nutrición Deportiva", "codigo": "NUT-220", "descripcion": "Planificación de macros y recuperación."},
        {"nombre": "Métodos de Investigación", "codigo": "INV-101", "descripcion": "Hipótesis, muestras y validación."},
    ],
    "Mateo Rincon": [
        {"nombre": "Matemáticas Discretas", "codigo": "MAT-112", "descripcion": "Lógica, grafos y relaciones."},
        {"nombre": "Historia Contemporánea", "codigo": "HIS-134", "descripcion": "Seminario y evaluación parcial."},
    ],
    "Valeria Castro": [
        {"nombre": "Psicología del Deporte", "codigo": "DEP-208", "descripcion": "Hábitos, adherencia y motivación."},
        {"nombre": "Marketing Digital", "codigo": "MKT-156", "descripcion": "Plan de campaña y analítica."},
    ],
}

SESSION_BLOCKS = {
    "Lucia Navarro": [
        {"subject": "Programación Móvil", "start": (8, 0), "end": (9, 30), "location": "Biblioteca Central", "conflict": False},
        {"subject": "Bioestadística", "start": (11, 0), "end": (12, 30), "location": "Laboratorio 2", "conflict": False},
        {"subject": "Inglés Técnico", "start": (16, 0), "end": (17, 0), "location": "Aula Virtual", "conflict": False},
    ],
    "Bruno Romero": [
        {"subject": "Bases de Datos", "start": (7, 30), "end": (9, 0), "location": "Sala 4", "conflict": False},
        {"subject": "Redacción Académica", "start": (15, 30), "end": (17, 0), "location": "Casa", "conflict": False},
    ],
    "Sofia Quezada": [
        {"subject": "Nutrición Deportiva", "start": (9, 0), "end": (10, 30), "location": "Cafetería", "conflict": False},
        {"subject": "Métodos de Investigación", "start": (18, 0), "end": (19, 30), "location": "Biblioteca", "conflict": True},
    ],
    "Mateo Rincon": [
        {"subject": "Matemáticas Discretas", "start": (10, 0), "end": (11, 30), "location": "Aula 5", "conflict": False},
        {"subject": "Historia Contemporánea", "start": (13, 0), "end": (14, 30), "location": "Aula 1", "conflict": False},
    ],
    "Valeria Castro": [
        {"subject": "Psicología del Deporte", "start": (8, 30), "end": (10, 0), "location": "Sala de estudio", "conflict": False},
        {"subject": "Marketing Digital", "start": (14, 0), "end": (15, 30), "location": "Home office", "conflict": False},
    ],
}

RETOS = {
    "Lucia Navarro": [
        {
            "titulo": "Racha de estudio de 7 días",
            "tipo": "academic",
            "meta": "Estudiar 90 minutos diarios durante 7 días consecutivos.",
            "visibilidad": "public",
            "fecha_inicio": 0,
            "fecha_fin": 7,
            "hitos": [
                ("Días 1-3 completados", 30, 100),
                ("Días 4-5 completados", 30, 100),
                ("Días 6-7 completados", 40, 60),
            ],
            "completado": False,
        },
        {
            "titulo": "4 sesiones de movilidad",
            "tipo": "fitness",
            "meta": "Completar 4 sesiones cortas de movilidad y estiramiento en la semana.",
            "visibilidad": "public",
            "fecha_inicio": 0,
            "fecha_fin": 6,
            "hitos": [
                ("Sesión 1", 25, 100),
                ("Sesión 2", 25, 100),
                ("Sesión 3", 25, 50),
                ("Sesión 4", 25, 0),
            ],
            "completado": False,
        },
    ],
    "Bruno Romero": [
        {
            "titulo": "Caminar 30 minutos por 5 días",
            "tipo": "fitness",
            "meta": "Registrar caminatas diarias para mejorar condición aeróbica.",
            "visibilidad": "public",
            "fecha_inicio": 1,
            "fecha_fin": 8,
            "hitos": [
                ("Primeras 3 caminatas", 50, 100),
                ("Meta final", 50, 80),
            ],
            "completado": False,
        }
    ],
    "Sofia Quezada": [
        {
            "titulo": "Semana de alimentación consciente",
            "tipo": "academic",
            "meta": "Registrar hábitos de comida y recuperación durante una semana.",
            "visibilidad": "public",
            "fecha_inicio": 0,
            "fecha_fin": 10,
            "hitos": [
                ("Plan de comidas", 40, 100),
                ("Hidratación", 30, 100),
                ("Sueño reparador", 30, 90),
            ],
            "completado": False,
        }
    ],
    "Mateo Rincon": [
        {
            "titulo": "Resolver 20 ejercicios de lógica",
            "tipo": "academic",
            "meta": "Practicar ejercicios de lógica y grafos antes del examen.",
            "visibilidad": "public",
            "fecha_inicio": 2,
            "fecha_fin": 9,
            "hitos": [
                ("Bloque 1", 50, 100),
                ("Bloque 2", 50, 20),
            ],
            "completado": False,
        }
    ],
    "Valeria Castro": [
        {
            "titulo": "Completar 3 entrenamientos semanales",
            "tipo": "fitness",
            "meta": "Mantener una rutina estable de fuerza y cardio.",
            "visibilidad": "public",
            "fecha_inicio": 0,
            "fecha_fin": 7,
            "hitos": [
                ("Entrenamiento 1", 34, 100),
                ("Entrenamiento 2", 33, 100),
                ("Entrenamiento 3", 33, 100),
            ],
            "completado": True,
        }
    ],
}

SOCIAL_ACTIVITIES = [
    {
        "user": "Lucia Navarro",
        "tipo": "session_completed",
        "descripcion": "Lucia completó una sesión de programación móvil y sumó energía para cerrar el día.",
        "url_imagen": None,
    },
    {
        "user": "Lucia Navarro",
        "tipo": "milestone_reached",
        "descripcion": "Lucia alcanzó un nuevo hito en su racha de estudio y mantiene la constancia.",
        "url_imagen": None,
    },
    {
        "user": "Bruno Romero",
        "tipo": "challenge_completed",
        "descripcion": "Bruno marcó un avance sólido en su reto de caminatas con una semana consistente.",
        "url_imagen": None,
    },
    {
        "user": "Sofia Quezada",
        "tipo": "session_completed",
        "descripcion": "Sofia cerró una sesión enfocada en nutrición deportiva y planificación semanal.",
        "url_imagen": None,
    },
    {
        "user": "Mateo Rincon",
        "tipo": "milestone_reached",
        "descripcion": "Mateo resolvió uno de sus bloques de lógica y sigue avanzando hacia el examen.",
        "url_imagen": None,
    },
    {
        "user": "Valeria Castro",
        "tipo": "challenge_completed",
        "descripcion": "Valeria completó su reto semanal y dejó el feed con un logro destacado.",
        "url_imagen": None,
    },
]

NOTIFICATIONS = [
    {
        "titulo": "Nuevo hito completado",
        "descripcion": "Tu racha de estudio sigue creciendo. Mantén el ritmo para llegar al siguiente nivel.",
        "prioridad": "critical",
        "tipo": "milestone",
        "url_accion": "/retos",
        "etiqueta_accion": "Ver retos",
    },
    {
        "titulo": "Plan académico actualizado",
        "descripcion": "Tienes bloques distribuidos en la semana para sostener tu constancia.",
        "prioridad": "recommended",
        "tipo": "academic",
        "url_accion": "/academico",
        "etiqueta_accion": "Ir al plan",
    },
    {
        "titulo": "Actividad social en tu red",
        "descripcion": "Tus compañeros compartieron nuevos logros en el muro social.",
        "prioridad": "informative",
        "tipo": "social",
        "url_accion": "/social",
        "etiqueta_accion": "Abrir muro",
    },
]


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def dt_at(days_offset: int = 0, hour: int = 9, minute: int = 0) -> datetime:
    base = utc_now() + timedelta(days=days_offset)
    return base.replace(hour=hour, minute=minute, second=0, microsecond=0)


def get_single(client: Client, table: str, filters: dict[str, Any], select: str = "*") -> dict[str, Any] | None:
    query = client.table(table).select(select)
    for key, value in filters.items():
        query = query.eq(key, value)
    response = query.limit(1).execute()
    if response.data:
        return response.data[0]
    return None


def ensure_user(client: Client, user: DemoUser) -> dict[str, Any]:
    existing = get_single(client, "usuarios", {"email": user.email})
    if existing:
        client.table("usuarios").update(
            {
                "nombre_completo": user.full_name,
                "url_avatar": user.avatar_url,
                "nivel_privacidad": user.privacy,
                "nivel": user.nivel,
                "xp_total": user.xp_total,
                "racha_actual": user.racha_actual,
            }
        ).eq("id", existing["id"]).execute()
        return existing

    try:
        response = client.auth.admin.create_user(
            {
                "email": user.email,
                "password": user.password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": user.full_name,
                    "avatar_url": user.avatar_url,
                    "picture": user.avatar_url,
                    "name": user.full_name,
                },
            }
        )
        created_user = response.user
        if created_user is None:
            raise RuntimeError(f"No se pudo crear auth.user para {user.email}")
        user_id = created_user.id
    except Exception:
        existing_auth = get_single(client, "usuarios", {"email": user.email})
        if existing_auth is None:
            raise
        user_id = existing_auth["id"]

    payload = {
        "id": user_id,
        "email": user.email,
        "nombre_completo": user.full_name,
        "url_avatar": user.avatar_url,
        "nivel_privacidad": user.privacy,
        "nivel": user.nivel,
        "xp_total": user.xp_total,
        "racha_actual": user.racha_actual,
    }
    client.table("usuarios").upsert(payload, on_conflict="id").execute()
    return {**payload}


def ensure_perfil_bienestar(client: Client, user_id: str, user_name: str) -> None:
    templates = {
        "Lucia Navarro": {
            "edad": 21,
            "sexo": "mujer",
            "peso_kg": 62,
            "altura_cm": 168,
            "nivel_actividad": "moderado",
            "objetivo_principal": "fitness_general",
            "objetivos": ["fitness_general", "resistencia"],
            "equipamiento_disponible": ["mancuernas", "colchoneta"],
            "dias_disponibles_semana": 5,
            "minutos_por_sesion": 45,
        },
        "Bruno Romero": {
            "edad": 22,
            "sexo": "hombre",
            "peso_kg": 78,
            "altura_cm": 180,
            "nivel_actividad": "ligero",
            "objetivo_principal": "perder_peso",
            "objetivos": ["perder_peso"],
            "equipamiento_disponible": ["bandas_elasticas"],
            "dias_disponibles_semana": 4,
            "minutos_por_sesion": 35,
        },
    }

    profile = templates.get(user_name)
    if profile is None:
        return

    altura_m = profile["altura_cm"] / 100
    imc = round(profile["peso_kg"] / (altura_m * altura_m), 1)
    payload = {
        "usuario_id": user_id,
        "edad": profile["edad"],
        "sexo": profile["sexo"],
        "peso_kg": profile["peso_kg"],
        "altura_cm": profile["altura_cm"],
        "imc": imc,
        "nivel_actividad": profile["nivel_actividad"],
        "objetivo_principal": profile["objetivo_principal"],
        "objetivos": profile["objetivos"],
        "equipamiento_disponible": profile["equipamiento_disponible"],
        "dias_disponibles_semana": profile["dias_disponibles_semana"],
        "minutos_por_sesion": profile["minutos_por_sesion"],
        "onboarding_completado": True,
    }
    client.table("perfil_bienestar_usuario").upsert(payload, on_conflict="usuario_id").execute()
    existing_historial = get_single(
        client,
        "historial_peso",
        {"usuario_id": user_id, "peso_kg": profile["peso_kg"], "altura_cm": profile["altura_cm"]},
    )
    if existing_historial is None:
        client.table("historial_peso").insert(
            {
                "usuario_id": user_id,
                "peso_kg": profile["peso_kg"],
                "altura_cm": profile["altura_cm"],
                "imc": imc,
            }
        ).execute()


def ensure_subjects_and_schedule(client: Client, user_id: str, user_name: str) -> None:
    subjects = ACADEMIC_SUBJECTS.get(user_name, [])
    schedule = SESSION_BLOCKS.get(user_name, [])
    subject_rows: dict[str, dict[str, Any]] = {}

    for subject in subjects:
        existing = get_single(client, "asignaturas", {"usuario_id": user_id, "codigo": subject["codigo"]})
        if existing is None:
            result = client.table("asignaturas").insert(
                {
                    "usuario_id": user_id,
                    "nombre": subject["nombre"],
                    "codigo": subject["codigo"],
                    "descripcion": subject["descripcion"],
                    "dificultad_percibida": 3,
                    "creditos": 3,
                    "prioridad": "alta" if "Programación" in subject["nombre"] else "media",
                    "proxima_evaluacion": (utc_now() + timedelta(days=7)).isoformat(),
                }
            ).execute()
            existing = result.data[0]
        subject_rows[subject["nombre"]] = existing

    for item in schedule:
        subject_row = subject_rows.get(item["subject"])
        if subject_row is None:
            continue
        start = dt_at(days_offset=0, hour=item["start"][0], minute=item["start"][1])
        end = dt_at(days_offset=0, hour=item["end"][0], minute=item["end"][1])
        existing = get_single(
            client,
            "horarios_academicos",
            {
                "usuario_id": user_id,
                "asignatura_id": subject_row["id"],
                "hora_inicio": start.isoformat(),
            },
        )
        if existing is None:
            client.table("horarios_academicos").insert(
                {
                    "usuario_id": user_id,
                    "asignatura_id": subject_row["id"],
                    "hora_inicio": start.isoformat(),
                    "hora_fin": end.isoformat(),
                    "ubicacion": item["location"],
                    "tiene_conflicto": item["conflict"],
                }
            ).execute()

    if user_name == "Lucia Navarro":
        week_start = (utc_now() - timedelta(days=utc_now().weekday())).date().isoformat()
        existing_plan = get_single(
            client,
            "plan_entrenamiento_semanal",
            {"usuario_id": user_id, "semana_inicio": week_start},
        )
        if existing_plan is None:
            client.table("plan_entrenamiento_semanal").insert(
                {
                    "usuario_id": user_id,
                    "semana_inicio": week_start,
                    "sesiones_planificadas": 4,
                    "intensidad": "moderada",
                    "duracion_min_por_sesion": 45,
                    "estado": "activo",
                    "notas": "Plan demo para semana intensa de estudio y entrenamiento.",
                }
            ).execute()


def ensure_sessions(client: Client, user_id: str, user_name: str) -> list[dict[str, Any]]:
    sessions: list[dict[str, Any]] = []
    if user_name == "Lucia Navarro":
        sessions = [
            {"duration": 50, "calories": 280, "rpe": 7, "date": dt_at(-1, 18, 30)},
            {"duration": 42, "calories": 230, "rpe": 6, "date": dt_at(0, 19, 15)},
        ]
    elif user_name == "Bruno Romero":
        sessions = [{"duration": 35, "calories": 170, "rpe": 5, "date": dt_at(-1, 7, 30)}]
    elif user_name == "Sofia Quezada":
        sessions = [{"duration": 48, "calories": 260, "rpe": 6, "date": dt_at(0, 8, 15)}]
    elif user_name == "Mateo Rincon":
        sessions = [{"duration": 30, "calories": 140, "rpe": 4, "date": dt_at(-2, 10, 0)}]
    elif user_name == "Valeria Castro":
        sessions = [{"duration": 60, "calories": 330, "rpe": 8, "date": dt_at(0, 17, 0)}]

    inserted = []
    for session in sessions:
        existing = get_single(
            client,
            "sesiones_registradas",
            {
                "usuario_id": user_id,
                "completada_en": session["date"].isoformat(),
                "duracion_minutos": session["duration"],
            },
        )
        if existing is None:
            result = client.table("sesiones_registradas").insert(
                {
                    "usuario_id": user_id,
                    "duracion_minutos": session["duration"],
                    "calorias_quemadas": session["calories"],
                    "rpe": session["rpe"],
                    "completada_en": session["date"].isoformat(),
                }
            ).execute()
            existing = result.data[0]
        inserted.append(existing)
    return inserted


def ensure_retos(client: Client, user_id: str, user_name: str) -> list[dict[str, Any]]:
    user_retos = RETOS.get(user_name, [])
    created: list[dict[str, Any]] = []
    for reto in user_retos:
        existing = get_single(client, "retos", {"usuario_id": user_id, "titulo": reto["titulo"]})
        if existing is None:
            result = client.table("retos").insert(
                {
                    "usuario_id": user_id,
                    "titulo": reto["titulo"],
                    "tipo": reto["tipo"],
                    "meta": reto["meta"],
                    "visibilidad": reto["visibilidad"],
                    "esta_completado": reto["completado"],
                    "fecha_inicio": dt_at(-reto["fecha_inicio"], 9, 0).isoformat(),
                    "fecha_fin": dt_at(reto["fecha_fin"], 20, 0).isoformat(),
                }
            ).execute()
            existing = result.data[0]

        created.append(existing)

        for index, (titulo, peso, progreso) in enumerate(reto["hitos"], start=1):
            hito_existing = get_single(
                client,
                "hitos_de_reto",
                {"reto_id": existing["id"], "indice_orden": index},
            )
            if hito_existing is None:
                client.table("hitos_de_reto").insert(
                    {
                        "reto_id": existing["id"],
                        "titulo": titulo,
                        "porcentaje_peso": peso,
                        "indice_orden": index,
                        "progreso_actual": progreso,
                        "esta_completado": progreso >= 100,
                    }
                ).execute()
            else:
                client.table("hitos_de_reto").update(
                    {
                        "titulo": titulo,
                        "porcentaje_peso": peso,
                        "progreso_actual": progreso,
                        "esta_completado": progreso >= 100,
                    }
                ).eq("id", hito_existing["id"]).execute()

    return created


def ensure_social_activity(
    client: Client,
    user_id: str,
    tipo: str,
    descripcion: str,
    url_imagen: str | None = None,
) -> dict[str, Any]:
    existing = get_single(
        client,
        "actividades_sociales",
        {"usuario_id": user_id, "descripcion": descripcion},
    )
    if existing is None:
        result = client.table("actividades_sociales").insert(
            {
                "usuario_id": user_id,
                "tipo": tipo,
                "descripcion": descripcion,
                "url_imagen": url_imagen,
            }
        ).execute()
        return result.data[0]
    return existing


def ensure_interaction(
    client: Client,
    actividad_id: str,
    usuario_id: str,
    tipo_interaccion: str,
    texto: str | None = None,
) -> None:
    existing = get_single(
        client,
        "interacciones_sociales",
        {
            "actividad_id": actividad_id,
            "usuario_id": usuario_id,
            "tipo_interaccion": tipo_interaccion,
        },
    )
    if existing is None:
        payload = {
            "actividad_id": actividad_id,
            "usuario_id": usuario_id,
            "tipo_interaccion": tipo_interaccion,
            "texto_comentario": texto,
        }
        client.table("interacciones_sociales").insert(payload).execute()


def ensure_notifications(client: Client, user_id: str) -> None:
    for notification in NOTIFICATIONS:
        existing = get_single(
            client,
            "notificaciones",
            {"usuario_id": user_id, "titulo": notification["titulo"]},
        )
        if existing is None:
            client.table("notificaciones").insert(
                {
                    "usuario_id": user_id,
                    "titulo": notification["titulo"],
                    "descripcion": notification["descripcion"],
                    "prioridad": notification["prioridad"],
                    "tipo": notification["tipo"],
                    "url_accion": notification["url_accion"],
                    "etiqueta_accion": notification["etiqueta_accion"],
                    "esta_leida": False,
                }
            ).execute()


def seed_demo_data(client: Client) -> None:
    print("🧪 Creando datos demo enriquecidos")
    print()

    users_by_name: dict[str, dict[str, Any]] = {}
    for user in DEMO_USERS:
        row = ensure_user(client, user)
        users_by_name[user.full_name] = row
        ensure_perfil_bienestar(client, row["id"], user.full_name)
        ensure_subjects_and_schedule(client, row["id"], user.full_name)
        ensure_sessions(client, row["id"], user.full_name)
        ensure_retos(client, row["id"], user.full_name)
        if user.full_name == "Lucia Navarro":
            ensure_notifications(client, row["id"])

    activities: list[dict[str, Any]] = []
    for activity in SOCIAL_ACTIVITIES:
        user_row = users_by_name[activity["user"]]
        created = ensure_social_activity(
            client,
            user_row["id"],
            activity["tipo"],
            activity["descripcion"],
            activity["url_imagen"],
        )
        activities.append(created)

    if len(activities) >= 2:
        lucia_id = users_by_name["Lucia Navarro"]["id"]
        bruno_id = users_by_name["Bruno Romero"]["id"]
        sofia_id = users_by_name["Sofia Quezada"]["id"]
        mateo_id = users_by_name["Mateo Rincon"]["id"]
        valeria_id = users_by_name["Valeria Castro"]["id"]

        for actividad in activities:
            autor = actividad["usuario_id"]
            otros = [uid for uid in [lucia_id, bruno_id, sofia_id, mateo_id, valeria_id] if uid != autor]
            for uid in otros[:2]:
                ensure_interaction(client, actividad["id"], uid, "like")
            if autor != lucia_id:
                ensure_interaction(
                    client,
                    actividad["id"],
                    lucia_id,
                    "comment",
                    "Buen trabajo, sigue así.",
                )

    print("✅ Datos demo creados o actualizados con éxito")
    print()
    print("Resumen:")
    for user in DEMO_USERS:
        count_activities = client.table("actividades_sociales").select("id", count="exact").eq("usuario_id", users_by_name[user.full_name]["id"]).execute().count
        count_retos = client.table("retos").select("id", count="exact").eq("usuario_id", users_by_name[user.full_name]["id"]).execute().count
        count_sessions = client.table("sesiones_registradas").select("id", count="exact").eq("usuario_id", users_by_name[user.full_name]["id"]).execute().count
        print(f" - {user.full_name}: {count_sessions} sesiones, {count_retos} retos, {count_activities} actividades")


def main() -> None:
    print("=" * 72)
    print("🧪 SynaptixFit - Seed demo de usuarios, academia, retos y social")
    print("=" * 72)
    print(f"📡 Supabase: {SUPABASE_URL}")
    print()

    client = create_client(SUPABASE_URL, SUPABASE_KEY)
    seed_demo_data(client)
    print("=" * 72)


if __name__ == "__main__":
    main()
