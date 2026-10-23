#!/usr/bin/env python3
"""Crea los usuarios demo de SynaptixFit con varias semanas de historia realista.

Todo se crea por la API pública, para que corran las reglas y los eventos del backend (XP, insignias, retos,
estado cognitivo, avisos, publicaciones automáticas). Como la API fecha casi todo con «ahora», el histórico
se construye por rondas: cada día simulado se hace por la API y luego shift_history.sql lleva al pasado lo
que se acaba de crear (solo fechas). Al final, las lecturas del backend recalculan lo derivado (racha, ACWR,
carga semanal, insignias). Detalles y pasos en README.md.

Uso:
    python tools/demo/seed_demo.py --base-url http://localhost:8080 --db local
    python tools/demo/seed_demo.py --base-url https://synaptixfit.jloenit.dev --db prod
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import threading
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone

from demo_lib import (DOMAIN, HERE, MADRID, Api, ApiError, SqlRunner, UserSession, demo_email, iso, load_password,
                      madrid, monday_of)
from personas import COMMENTS, FRIENDSHIPS, PERSONAS

PLACEHOLDER_WEEKS = 12  # los bloques históricos se crean 12 semanas después de su fecha y move_blocks.sql los devuelve
ROUND_HOUR = (19, 0)    # hora del día simulado a la que se llevan las acciones de cada ronda
FUTURE_DAYS = 14
# Durante el seed no hay horas de silencio: las rondas corren a la hora real y las silenciarían. Las
# preferencias de cada persona se aplican al final (tidy).
SEED_NOTIFICATION_PREFS = {"activeCategories": ["CONFLICT", "FATIGUE_ALERT", "MILESTONE", "SOCIAL", "ACADEMIC"],
                           "dailyLimit": 50, "mode": "NORMAL"}

_print_lock = threading.Lock()


def log(msg: str):
    with _print_lock:
        print(msg, flush=True)


def hm(text: str) -> tuple[int, int]:
    h, m = text.split(":")
    return int(h), int(m)


def rng_for(*parts) -> random.Random:
    return random.Random("|".join(str(p) for p in parts))


class PersonaState:
    """Lo que el seed va sabiendo de una persona: ids creados y su planificación."""

    def __init__(self, spec: dict, session: UserSession):
        self.spec = spec
        self.key = spec["key"]
        self.s = session
        self.subjects: dict[str, str] = {}          # clave → id de asignatura
        self.routine: dict | None = None
        self.routine_days: list[tuple[dict, dict, int]] = []  # (semana, día, índice de semana)
        self.session_plan: dict[int, int] = {}      # d → índice en routine_days
        self.future_sport: list[tuple[int, int]] = []  # (d, índice) para bloques futuros
        self.next_routine_idx = 0
        self.deadlines: dict[str, str] = {}
        self.notes: dict[str, str] = {}             # título → id
        self.materials: list[dict] = []             # {id, title, due (d), reviews}
        self.quiz_materials: list[str] = []
        self.challenges: list[dict] = []
        self.blocks: dict[int, list[dict]] = {}     # d → bloques históricos ya en su fecha
        self.future_blocks: list[dict] = []
        self.training_plans: dict[date, dict] = {}


class Seeder:
    def __init__(self, args, api: Api, sql: SqlRunner, password: str, specs: list[dict]):
        self.args = args
        self.api = api
        self.sql = sql
        self.password = password
        self.specs = specs
        self.H = args.days
        self.ai_budget = 0 if args.no_ai else args.ai_budget
        self.ai_lock = threading.Lock()
        self.errors: list[str] = []
        self.states: dict[str, PersonaState] = {}
        self.others: dict[str, UserSession] = {}  # personas que ya existían: solo para rehacer amistades
        self.exercise_cache: dict[str, dict] = {}
        self.exercise_lock = threading.Lock()
        self.run_log: dict = {"baseUrl": api.base_url, "db": sql.target, "rounds": [], "personas": {}}
        now = self.server_now()
        self.today = now.astimezone(MADRID).date()
        self.week0 = monday_of(self.today)

    # ------------------------------------------------------------------------------------- utilidades

    def server_now(self) -> datetime:
        try:
            self.api.request("GET", "/api/v1/me", retries=1)
        except ApiError:
            pass
        return self.api.server_time or datetime.now(timezone.utc)

    def day(self, d: int) -> date:
        return self.today + timedelta(days=d)

    def err(self, who: str, d, what: str, e: Exception):
        msg = f"[{who}] día {d}: {what}: {e}"
        self.errors.append(msg)
        log("  ! " + msg)

    def try_call(self, st: PersonaState, d, what: str, fn, *a):
        try:
            return fn(*a)
        except ApiError as e:
            self.err(st.key, d, what, e)
            return None

    def take_ai(self) -> bool:
        with self.ai_lock:
            if self.ai_budget <= 0:
                return False
            self.ai_budget -= 1
            return True

    def emails(self) -> str:
        return ",".join(st.s.email for st in self.states.values())

    def parallel(self, fn, states=None):
        states = list(states if states is not None else self.states.values())
        with ThreadPoolExecutor(max_workers=max(1, len(states))) as pool:
            list(pool.map(fn, states))

    def exercise(self, st: PersonaState, name: str) -> dict:
        with self.exercise_lock:
            if name in self.exercise_cache:
                return self.exercise_cache[name]
        res = st.s.get("/api/v1/exercises?size=50&q=" + urllib.parse.quote(name))
        items = res["items"]
        match = next((x for x in items if x["name"].casefold() == name.casefold()), None) or (items[0] if items else None)
        if not match:
            raise ApiError("GET", "/exercises", 404, f"ejercicio no encontrado: {name}")
        with self.exercise_lock:
            self.exercise_cache[name] = match
        return match

    # ------------------------------------------------------------------------------------ preparación

    def prepare(self) -> list[dict]:
        """Decide qué personas se crean: las que ya existen se saltan, salvo con --reset (se borran antes)."""
        todo = []
        for spec in self.specs:
            session = UserSession(self.api, demo_email(spec["email"]), self.password)
            try:
                session.login()
                exists = True
            except ApiError as e:
                if e.status not in (401, 403, 404):
                    raise
                exists = False
            if exists and not self.args.reset:
                log(f"= {session.email} ya existe: se salta (usa --reset para recrearla)")
                self.others[spec["key"]] = session
                continue
            if exists:
                if spec.get("admin"):
                    self.set_role(session.email, "usuario")
                session.delete("/api/v1/me", {"password": self.password, "confirm": True})
                log(f"- {session.email} borrada (--reset)")
            todo.append(spec)
        for spec in PERSONAS:
            if spec not in self.specs and not spec.get("admin"):
                session = UserSession(self.api, demo_email(spec["email"]), self.password)
                try:
                    session.login()
                    self.others[spec["key"]] = session
                except ApiError:
                    pass
        return todo

    def set_role(self, email_addr: str, role: str):
        if self.sql.enabled:
            self.sql.run_file("set_role.sql", {"email": email_addr, "role": role})

    # ---------------------------------------------------------------------------------------- ronda

    def run_round(self, d: int, actions, label: str, next_d: int = 0):
        """Ejecuta las acciones de un día simulado y lleva al pasado lo creado (shift_history.sql).

        La actividad (sesiones, check-ins, Pomodoros) retrocede hasta el siguiente día simulado (next_d), para
        que en la próxima ronda quede justo antes de «hoy»; el resto va directamente a su fecha.
        """
        start = self.server_now()
        if start.astimezone(MADRID).date() != self.today:
            sys.exit("El reloj del servidor ha cambiado de día durante el seed: vuelve a ejecutarlo con --reset.")
        calls_before = self.api.calls
        actions()
        target_day = self.day(d)
        target = madrid(target_day, *ROUND_HOUR)
        shift = int((target - start).total_seconds())
        align = int((madrid(self.today, *ROUND_HOUR) - start).total_seconds())
        t0 = start - timedelta(seconds=120)
        if d != 0 and not self.args.no_history:
            self.sql.run_file("shift_history.sql", {
                "t0": t0.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M:%S+00"),
                "shift": f"{shift} seconds", "days": -d, "align": f"{align} seconds", "roll": next_d - d,
                "users": self.emails(),
                "today": self.today.isoformat(), "target_day": target_day.isoformat()})
        self.run_log["rounds"].append({"day": d, "date": target_day.isoformat(), "t0": iso(t0), "shiftSeconds": shift,
                                       "apiCalls": self.api.calls - calls_before, "label": label})
        log(f"· {label} ({target_day.isoformat()}): {self.api.calls - calls_before} llamadas")

    # ------------------------------------------------------------------------------ ronda 0: alta

    def round0(self):
        reg_day = -(self.H + 3)
        self.run_round(reg_day, lambda: self.parallel(self.setup_persona, self.pending_states), "Alta y perfil",
                       next_d=-self.H)

    def setup_persona(self, st: PersonaState):
        spec = st.spec
        s = st.s
        s.register(spec["name"])
        self.run_log["personas"][st.key] = {"email": s.email, "userId": s.user_id}
        s.patch("/api/v1/me", {"privacy": spec["privacy"]})
        s.put("/api/v1/profile/wellness", spec["wellness"])
        academic = {k: v for k, v in spec["academic"].items()}
        start = monday_of(self.day(-self.H))
        academic.update({"classesStartDate": start.isoformat(), "classesEndDate": (start + timedelta(days=130)).isoformat()})
        catalog = spec.get("catalog")
        catalog_subjects = []
        if catalog:
            unis = s.get("/api/v1/catalog/universities?q=" + urllib.parse.quote(catalog["university"]))
            uni = next(u for u in unis if u["name"] == catalog["university"])
            degrees = s.get(f"/api/v1/catalog/universities/{uni['id']}/degrees")
            degree = next(x for x in degrees if x["name"] == catalog["degree"])
            s.put(f"/api/v1/profile/degrees/{degree['id']}")
            academic.update({"university": uni["name"], "degree": degree["name"], "degreeId": degree["id"]})
            page = s.get(f"/api/v1/catalog/degrees/{degree['id']}/subjects?size=100&course={catalog['course']}"
                         f"&semester={catalog['semester']}")
            wanted = {v["name"].casefold(): k for k, v in spec["subjects"].items()}
            catalog_subjects = [x for x in page["items"] if x["name"].casefold() in wanted]
        s.put("/api/v1/profile/academic", academic)
        if catalog_subjects:
            created = s.post("/api/v1/subjects/from-catalog", {"catalogSubjectIds": [x["id"] for x in catalog_subjects]})
            wanted = {v["name"].casefold(): k for k, v in spec["subjects"].items()}
            for subj in created:
                key = wanted[subj["name"].casefold()]
                st.subjects[key] = subj["id"]
                tweak = {k: v for k, v in spec["subjects"][key].items() if k != "name"}
                if tweak:
                    s.patch(f"/api/v1/subjects/{subj['id']}", tweak)
        for m in spec.get("manual_subjects", []):
            body = {k: v for k, v in m.items() if k != "key"}
            st.subjects[m["key"]] = s.post("/api/v1/subjects", body)["id"]
        s.post("/api/v1/profile/onboarding/complete")
        if spec.get("notif"):
            s.put("/api/v1/notifications/preferences", SEED_NOTIFICATION_PREFS)
        if spec.get("admin"):
            return
        self.create_routine(st)
        for dl in spec.get("deadlines", []):
            dd, t = dl["due"]
            body = {"title": dl["title"], "type": dl["type"], "dueAt": iso(madrid(self.day(dd), *hm(t))),
                    "difficulty": dl["difficulty"], "subjectId": st.subjects[dl["subject"]]}
            if dl.get("description"):
                body["description"] = dl["description"]
            st.deadlines[dl["key"]] = s.post("/api/v1/planner/deadlines", body)["id"]
        for ch in spec.get("challenges", []):
            st.challenges.append(self.create_challenge(st, ch, final=False))

    def create_routine(self, st: PersonaState):
        spec = st.spec
        r = spec["routine"]
        start = monday_of(self.day(-self.H if st.key != "marta" else -27))
        routine = None
        if spec.get("routine_ai") and self.take_ai():
            try:
                proposal = st.s.post("/api/v1/routines/generate", {**spec["routine_ai"], "useAi": True})
                days = sum(len(w.get("days", [])) for w in proposal.get("weeks", []))
                if proposal.get("aiRefined") and days >= 30:
                    weeks = [{"name": w.get("name"), "type": w.get("type"),
                              "days": [{"dayNumber": dd["dayNumber"], "name": dd.get("name"),
                                        "exercises": [{k: v for k, v in ex.items() if k != "exerciseName" and v is not None}
                                                      for ex in dd.get("exercises", [])]}
                                       for dd in w.get("days", [])]} for w in proposal["weeks"]]
                    routine = st.s.post("/api/v1/routines", {
                        "name": proposal["name"][:120], "description": (proposal.get("description") or "")[:2000],
                        "visibility": r["visibility"], "goal": proposal.get("goal") or r["goal"],
                        "startDate": start.isoformat(), "weeks": weeks})
                    log(f"  {st.key}: rutina generada con IA ({days} días)")
                else:
                    log(f"  {st.key}: la propuesta de IA no sirve (aiRefined={proposal.get('aiRefined')}, días={days}); rutina manual")
            except ApiError as e:
                log(f"  {st.key}: IA no disponible ({e.code}); rutina manual")
        if routine is None:
            weeks = []
            for w in range(r["weeks"]):
                wtype = r["week_types"][w]
                factor = (1 + 0.025 * w) * (0.85 if wtype == "DELOAD" else 1.0)
                days = []
                for day_number, name, exercises in r["days"]:
                    exs = []
                    for ex in exercises:
                        ex_name, sets, reps, rest, weight = ex[:5]
                        extra = ex[5] if len(ex) > 5 else {}
                        item = {"exerciseId": self.exercise(st, ex_name)["id"],
                                "sets": max(2, sets - 1) if wtype == "DELOAD" and sets > 2 else sets,
                                "reps": reps, "restSeconds": rest, **extra}
                        if weight:
                            step = 2.5 if weight >= 20 else 0.5
                            item["weightKg"] = round(weight * factor / step) * step
                        exs.append(item)
                    days.append({"dayNumber": day_number, "name": name, "exercises": exs})
                weeks.append({"name": f"Semana {w + 1}", "type": wtype, "days": days})
            routine = st.s.post("/api/v1/routines", {"name": r["name"], "description": r["description"],
                                                     "visibility": r["visibility"], "goal": r["goal"],
                                                     "startDate": start.isoformat(), "weeks": weeks})
        st.routine = routine
        st.routine_days = [(w, dd, wi) for wi, w in enumerate(routine["weeks"]) for dd in w["days"]]

    def create_challenge(self, st: PersonaState, ch: dict, final: bool) -> dict:
        body = {"title": ch["title"], "type": ch["type"], "goal": ch["goal"], "visibility": ch["visibility"],
                "difficulty": ch["difficulty"], "startAt": iso(madrid(self.day(ch["start"]), 0, 0)),
                "endAt": iso(madrid(self.day(ch["end"]), 23, 0))}
        if ch.get("subject"):
            body["subjectId"] = st.subjects[ch["subject"]]
        if ch.get("sessionTarget"):
            body["sessionTarget"] = ch["sessionTarget"]
        milestones = []
        for m in ch.get("milestones", []):
            item = {"title": m["title"], "weight": m["weight"], "difficulty": m["difficulty"]}
            if ch.get("subject"):
                item["subjectId"] = st.subjects[ch["subject"]]
            if m.get("deadline"):
                dl = next(x for x in st.spec["deadlines"] if x["key"] == m["deadline"])
                item["linkedEntityType"] = "EXAM" if dl["type"] == "EXAM" else "DELIVERY"
                item["linkedEntityId"] = st.deadlines[m["deadline"]]
            if m.get("block") and final:
                subject_key, nth = m["block"]
                blocks = [b for b in st.future_blocks if b["kind"] == "STUDY" and b["subject"] == subject_key]
                if len(blocks) >= nth:
                    item["linkedEntityType"] = "BLOCK"
                    item["linkedEntityId"] = blocks[nth - 1]["id"]
            if m.get("note") and m["note"] in st.notes:
                item["noteId"] = st.notes[m["note"]]
            milestones.append(item)
        if milestones:
            body["milestones"] = milestones
        created = st.s.post("/api/v1/challenges", body)
        created["_spec"] = ch
        return created

    # --------------------------------------------------------------------- planificación de sesiones

    def plan_sessions(self, st: PersonaState):
        idx = 0
        for d in range(-self.H, 1):
            wd = self.day(d).weekday()
            if st.spec["training"](d, wd):
                if idx < len(st.routine_days):
                    st.session_plan[d] = idx
                idx += 1
        st.next_routine_idx = idx
        available = set(st.spec["wellness"]["availableDays"])
        for d in range(1, FUTURE_DAYS + 1):
            if self.day(d).weekday() + 1 in available and idx < len(st.routine_days):
                st.future_sport.append((d, idx))
                idx += 1

    # ------------------------------------------------------------------- fase A: bloques históricos

    def block_specs(self, st: PersonaState, d: int) -> list[dict]:
        spec = st.spec
        wd = self.day(d).weekday()
        out = []
        for (cwd, a, b, subj, kind, loc) in spec.get("classes", []):
            if cwd == wd:
                out.append({"kind": "CLASS", "start": a, "end": b, "subject": subj, "classKind": kind, "location": loc,
                            "p": spec["class_p"]})
        last_week = d >= -7
        for (swd, a, b, subj, topics, prio) in spec.get("study", []):
            if swd == wd:
                out.append({"kind": "STUDY", "start": a, "end": b, "subject": subj, "topics": topics, "priority": prio,
                            "p": spec.get("study_p_last_week", spec["study_p"]) if last_week else spec["study_p"]})
        if last_week:
            for (_, a, b, subj, topics, prio) in spec.get("study_extra_last_week", []):
                if not any(x["start"] == a for x in out):
                    out.append({"kind": "STUDY", "start": a, "end": b, "subject": subj, "topics": topics,
                                "priority": prio, "p": spec.get("study_p_last_week", spec["study_p"])})
        sport_idx = st.session_plan.get(d) if d <= 0 else dict(st.future_sport).get(d)
        if sport_idx is not None and spec.get("sport_time"):
            a, minutes = spec["sport_time"]
            h, m = hm(a)
            end = (datetime(2000, 1, 1, h, m) + timedelta(minutes=minutes)).strftime("%H:%M")
            week, day_, _ = st.routine_days[sport_idx]
            out.append({"kind": "SPORT", "start": a, "end": end, "routineIdx": sport_idx, "topics": day_["name"],
                        "p": 1.0})
        return out

    def block_body(self, st: PersonaState, b: dict, start: datetime, end: datetime) -> dict:
        body = {"start": iso(start), "end": iso(end), "type": b["kind"]}
        if b["kind"] == "CLASS":
            body.update({"fixed": True, "subjectId": st.subjects[b["subject"]], "classKind": b["classKind"],
                         "location": b["location"], "priority": "MEDIUM"})
        elif b["kind"] == "STUDY":
            body.update({"subjectId": st.subjects[b["subject"]], "topics": b["topics"], "priority": b["priority"]})
        elif b["kind"] == "SPORT":
            week, day_, _ = st.routine_days[b["routineIdx"]]
            body.update({"routineId": st.routine["id"], "routineWeekId": week["id"], "routineDayId": day_["id"],
                         "topics": b["topics"], "location": "Gimnasio"})
        return body

    def phase_a(self):
        now = self.server_now() + timedelta(minutes=5)
        created: list[str] = []
        lock = threading.Lock()

        def run(st: PersonaState):
            if st.spec.get("admin"):
                return
            for d in range(-self.H, 1):
                for b in self.block_specs(st, d):
                    start = madrid(self.day(d), *hm(b["start"]))
                    end = madrid(self.day(d), *hm(b["end"]))
                    if start >= now:
                        continue
                    shift = timedelta(weeks=PLACEHOLDER_WEEKS)
                    ph_start = madrid(self.day(d) + shift, *hm(b["start"]))
                    ph_end = madrid(self.day(d) + shift, *hm(b["end"]))
                    try:
                        res = st.s.post("/api/v1/planner/blocks", self.block_body(st, b, ph_start, ph_end))
                    except ApiError as e:
                        self.err(st.key, d, f"bloque {b['kind']} {b['start']}", e)
                        continue
                    b = dict(b, id=res["block"]["id"], targetStart=start)
                    st.blocks.setdefault(d, []).append(b)
                    with lock:
                        created.append(b["id"])

        self.parallel(run)
        if created:
            self.sql.run_file("move_blocks.sql", {
                "ids": ",".join(created), "back": f"{PLACEHOLDER_WEEKS * 7} days", "users": self.emails(),
                "created": madrid(self.day(-self.H - 2), 20, 0).astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M:%S+00")})
        self.run_log["phaseABlocks"] = len(created)
        log(f"· Calendario histórico: {len(created)} bloques colocados en su fecha")

    # --------------------------------------------------------------------------- acciones de un día

    def do_day(self, st: PersonaState, d: int):
        spec = st.spec
        s = st.s
        if spec.get("admin"):
            return
        day = self.day(d)
        wd = day.weekday()
        week_start = monday_of(day)
        rng = rng_for(st.key, d)

        if wd == 0 or d == -self.H:
            self.weekly_plans(st, d, week_start)
        for n in spec.get("notes", []):
            if n["day"] == d:
                self.create_note(st, d, n)
        for q in spec.get("quizzes", []):
            if q["day"] == d:
                res = self.try_call(st, d, "test manual", s.post, "/api/v1/study/generations/quizzes",
                                    {"subjectId": st.subjects[q["subject"]], "title": q["title"], "questions": q["questions"]})
                if res:
                    st.quiz_materials.append(res["materialId"])
                    st.materials.append({"id": res["materialId"], "title": q["title"], "due": d + 1})
        if spec.get("exam_mode_from") == d:
            self.try_call(st, d, "modo exámenes", s.put, "/api/v1/notifications/preferences",
                          {**SEED_NOTIFICATION_PREFS, "mode": "EXAMS"})
        if spec.get("goal_change") and spec["goal_change"][0] == d:
            self.try_call(st, d, "objetivo", s.patch, "/api/v1/profile/wellness", {"primaryGoal": spec["goal_change"][1]})
        for wd_day, kg in spec.get("weights", []):
            if wd_day == d:
                self.try_call(st, d, "peso", s.patch, "/api/v1/profile/wellness", {"weightKg": kg})

        checkin = spec["checkin"](d, wd)
        if checkin:
            self.try_call(st, d, "check-in", s.put, "/api/v1/training/check-ins/today", checkin)

        if d < 0:  # los repasos que tocan hoy se dejan pendientes para probarlos en la demo
            self.reviews(st, d, rng)
        for test_day, quiz_idx in spec.get("tests", []):
            if test_day == d and quiz_idx < len(st.quiz_materials):
                self.test_session(st, d, st.quiz_materials[quiz_idx], rng)

        for b in st.blocks.get(d, []):
            if b["kind"] in ("CLASS", "STUDY") and rng_for(st.key, d, b["start"]).random() < b["p"]:
                self.try_call(st, d, "completar bloque", s.put, f"/api/v1/planner/blocks/{b['id']}/completion",
                              {"completed": True})

        for minutes, subj in spec["focus"](d, wd):
            self.try_call(st, d, "pomodoro", s.post, "/api/v1/planner/focus-sessions",
                          {"phase": "FOCUS", "durationMinutes": minutes, "cycles": 1, "completed": True,
                           "subjectId": st.subjects[subj]})

        training = spec["training"](d, wd)
        if training and d in st.session_plan:
            self.training_session(st, d, training, rng)

        for dl in spec.get("deadlines", []):
            if dl.get("complete") == d:
                self.try_call(st, d, "entrega", s.put, f"/api/v1/planner/deadlines/{st.deadlines[dl['key']]}/completion",
                              {"completed": True})
        for ch in st.challenges:
            for i, m in enumerate(ch["_spec"].get("milestones", [])):
                if m.get("complete") == d:
                    mid = ch["milestones"][i]["id"]
                    self.try_call(st, d, "hito", s.post, f"/api/v1/challenges/{ch['id']}/milestones/{mid}/complete")

        ai = spec.get("ai", {})
        if ai.get("flashcards_notes") and d == -10 and self.take_ai():
            sources = [{"type": "NOTE", "id": st.notes[t]} for t in ai["flashcards_notes"] if t in st.notes]
            if self.try_call(st, d, "flashcards IA", s.post, "/api/v1/study/generations",
                             {"kind": "FLASHCARDS", "sources": sources}) is not None:
                log(f"  {st.key}: flashcards generadas con IA")
        if ai.get("summary_note") and d == -8 and ai["summary_note"] in st.notes and self.take_ai():
            if self.try_call(st, d, "resumen IA", s.post,
                             f"/api/v1/study/sources/NOTE/{st.notes[ai['summary_note']]}/documents/SUMMARY") is not None:
                log(f"  {st.key}: resumen generado con IA")

        for pd, ptype, text in spec.get("posts", []):
            if pd == d:
                self.try_call(st, d, "publicación", s.post, "/api/v1/social/posts",
                              {"type": ptype, "description": text, "metadata": {}})

        if wd == 6 and spec.get("wellbeing"):
            self.try_call(st, d, "carga semanal", s.post, f"/api/v1/planner/weekly-loads/{week_start}/sync")
            wb = spec["wellbeing"]
            stress = max(1, min(10, wb["stress"] + (1 if d >= -7 and st.key == "pablo" else 0) + rng.choice((-1, 0, 0, 1))))
            self.try_call(st, d, "bienestar semanal", s.patch, f"/api/v1/planner/weekly-loads/{week_start}",
                          {"stressLevel": stress, "sleepHours": wb["sleep"] + rng.choice((-0.5, 0, 0.5))})

    def weekly_plans(self, st: PersonaState, d: int, week_start: date):
        spec = st.spec
        s = st.s
        if spec.get("training_plan"):
            prev = week_start - timedelta(days=7)
            if prev in st.training_plans:
                self.try_call(st, d, "plan semanal anterior", s.put, f"/api/v1/training/weekly-plans/{prev}",
                              {**st.training_plans[prev], "status": "COMPLETED"})
            plan = spec.get("training_plan_last") if -7 <= d < 0 and spec.get("training_plan_last") else spec["training_plan"]
            self.try_call(st, d, "plan semanal", s.put, f"/api/v1/training/weekly-plans/{week_start}",
                          {**plan, "status": "ACTIVE"})
            st.training_plans[week_start] = plan
        offset = (week_start - self.week0).days // 7
        for w, name in spec.get("study_plans", []):
            if w == offset:
                self.try_call(st, d, "plan de estudio", s.put, f"/api/v1/planner/plans/{week_start}",
                              {"name": name, "visibility": "FRIENDS"})

    def create_note(self, st: PersonaState, d: int, n: dict):
        body = {"subjectId": st.subjects[n["subject"]], "title": n["title"], "content": n["content"],
                "visibility": n["visibility"], "quickNote": bool(n.get("quick"))}
        res = self.try_call(st, d, "apunte", st.s.post, "/api/v1/notes", body)
        if not res:
            return
        st.notes[n["title"]] = res["id"]
        if n.get("material"):
            mat = self.try_call(st, d, "material", st.s.post, "/api/v1/study-materials",
                                {"originType": "NOTE", "originId": res["id"]})
            if mat:
                st.materials.append({"id": mat["id"], "title": n["title"], "due": d + 1})

    def reviews(self, st: PersonaState, d: int, rng: random.Random):
        cfg = st.spec.get("review")
        if not cfg or d in cfg.get("skip_days", ()):
            return
        for i, m in enumerate(st.materials):
            if m["due"] > d or rng.random() > cfg["diligence"]:
                continue
            q = cfg["qualities"][(d + i) % len(cfg["qualities"])]
            if st.spec.get("flashcards") and (d + i) % 2 == 0:
                body = {"mastered": 6 + q, "doubtful": 7 - q, "failed": max(0, 4 - q)}
                res = self.try_call(st, d, "flashcards", st.s.post, f"/api/v1/study-materials/{m['id']}/flashcard-reviews", body)
            else:
                res = self.try_call(st, d, "repaso SM-2", st.s.post, f"/api/v1/study-materials/{m['id']}/reviews",
                                    {"quality": q})
            if res:
                m["due"] = d + max(1, int(res["material"]["intervalDays"]))

    def test_session(self, st: PersonaState, d: int, material_id: str, rng: random.Random):
        res = self.try_call(st, d, "test", st.s.post, "/api/v1/test-sessions", {"materialIds": [material_id], "questionCount": 5})
        if not res:
            return
        # La sesión no revela la solución hasta responder: se toma de los tests de la propia persona.
        solutions = {q["statement"]: q["correctAnswer"] for quiz in st.spec.get("quizzes", []) for q in quiz["questions"]}
        questions = res.get("questions") or []
        for i, q in enumerate(questions):
            correct = solutions.get(q.get("statement"))
            options = [o for o in (q.get("options") or []) if o != correct]
            answer = correct if (correct and rng.random() < 0.8) else (options[0] if options else "no lo sé")
            self.try_call(st, d, "respuesta", st.s.post, f"/api/v1/test-sessions/{res['id']}/answers",
                          {"questionId": q["id"], "answer": answer, "nextIndex": i + 1})
        self.try_call(st, d, "fin del test", st.s.post, f"/api/v1/test-sessions/{res['id']}/complete")

    def training_session(self, st: PersonaState, d: int, training: dict, rng: random.Random):
        week, day_, wi = st.routine_days[st.session_plan[d]]
        session = self.try_call(st, d, "inicio de sesión", st.s.post, "/api/v1/training/sessions",
                                {"routineId": st.routine["id"], "dayId": day_["id"]})
        if not session:
            return
        sets, real = [], {}
        for pe in day_["exercises"]:
            mt = pe.get("measurementTypes") or []
            if pe.get("targetDurationSeconds"):
                real[pe["id"]] = max(60, int(pe["targetDurationSeconds"] * rng.uniform(0.92, 1.08)))
            for n in range(1, pe["sets"] + 1):
                reps = pe["reps"]
                failed = 1 if training["rpe"] >= 9 and n == pe["sets"] and reps > 3 else 0
                item = {"plannedExerciseId": pe["id"], "setNumber": n, "repsDone": reps - failed, "completed": True,
                        "failedReps": failed}
                if pe.get("weightKg") is not None and "WEIGHT" in mt:
                    item["weightKg"] = pe["weightKg"]
                sets.append(item)
        body = {"durationSeconds": training["minutes"] * 60 + rng.randint(-90, 90), "rpe": training["rpe"], "sets": sets}
        if real:
            body["realDurations"] = real
        if self.try_call(st, d, "fin de sesión", st.s.post, f"/api/v1/training/sessions/{session['id']}/finish", body):
            for b in st.blocks.get(d, []):
                if b["kind"] == "SPORT":
                    self.try_call(st, d, "bloque de deporte", st.s.put, f"/api/v1/planner/blocks/{b['id']}/completion",
                                  {"completed": True})

    # --------------------------------------------------------------------------------------- social

    def social(self, d: int):
        by_key = self.states
        # Las amistades con personas que ya existían (ejecución con --only) también se rehacen.
        sessions = {**self.others, **{k: v.s for k, v in by_key.items()}}
        for fd, a, b, accept in FRIENDSHIPS:
            if a in sessions and b in sessions and (a in by_key or b in by_key):
                sa, sb = sessions[a], sessions[b]
                who = by_key.get(a) or by_key.get(b)
                if fd == d:
                    self.try_call(who, d, "solicitud de amistad", sa.post, "/api/v1/social/friends/requests",
                                  {"userId": sb.user_id})
                if accept == d:
                    received = self.try_call(who, d, "solicitudes", sb.get,
                                             "/api/v1/social/friends?kind=RECEIVED&size=50") or {"items": []}
                    for fr in received["items"]:
                        if fr["user"]["id"] == sa.user_id:
                            self.try_call(who, d, "aceptar amistad", sb.post, f"/api/v1/social/friends/{fr['id']}/accept")
        for st in by_key.values():
            if st.spec.get("admin"):
                continue
            feed = self.try_call(st, d, "muro", st.s.get, "/api/v1/social/posts?period=TODAY&size=50") or {"items": []}
            for post in feed["items"]:
                if post.get("mine") or post.get("likedByMe"):
                    continue
                r = rng_for(st.key, post["id"])
                if r.random() < st.spec.get("likes_p", 0):
                    self.try_call(st, d, "me gusta", st.s.put, f"/api/v1/social/posts/{post['id']}/like")
                if r.random() < st.spec.get("comment_p", 0):
                    text = r.choice(COMMENTS[st.key])
                    self.try_call(st, d, "comentario", st.s.post, f"/api/v1/social/posts/{post['id']}/comments", {"text": text})

    # ------------------------------------------------------------------------------- fase final: hoy

    def phase_b(self, st: PersonaState):
        """Bloques de hoy (los que aún no han empezado) y de las dos próximas semanas, más los exámenes."""
        if st.spec.get("admin"):
            return
        now = self.server_now() + timedelta(minutes=5)
        for d in range(0, FUTURE_DAYS + 1):
            for b in self.block_specs(st, d):
                start = madrid(self.day(d), *hm(b["start"]))
                if start < now:
                    continue
                end = madrid(self.day(d), *hm(b["end"]))
                res = self.try_call(st, d, f"bloque futuro {b['kind']}", st.s.post, "/api/v1/planner/blocks",
                                    self.block_body(st, b, start, end))
                if res:
                    st.future_blocks.append(dict(b, id=res["block"]["id"], targetStart=start, d=d))
                    if d == 0 and b["kind"] == "SPORT":
                        st.blocks.setdefault(0, []).append(dict(b, id=res["block"]["id"], targetStart=start, future=True))
        for dl in st.spec.get("deadlines", []):
            dd, t = dl["due"]
            if dd <= 0 or dl["type"] != "EXAM":
                continue
            start = madrid(self.day(dd), *hm(t))
            self.try_call(st, dd, "bloque de examen", st.s.post, "/api/v1/planner/blocks", {
                "start": iso(start), "end": iso(start + timedelta(hours=2)), "type": "EXAM",
                "subjectId": st.subjects[dl["subject"]], "deadlineId": st.deadlines[dl["key"]],
                "topics": dl["title"], "priority": "HIGH", "fixed": True})

    def final_extras(self, st: PersonaState):
        spec = st.spec
        s = st.s
        if spec.get("admin"):
            return
        for ch in spec.get("final_challenges", []):
            created = self.try_call(st, 0, "reto final", self.create_challenge, st, ch, True)
            if not created:
                continue
            st.challenges.append(created)
            done_deadlines = {x["key"] for x in spec.get("deadlines", []) if x.get("complete") is not None}
            for i, m in enumerate(ch.get("milestones", [])):
                # Un hito vinculado a una entrega ya completada no se marca solo al crear el reto.
                if m.get("complete_now") or m.get("deadline") in done_deadlines:
                    self.try_call(st, 0, "hito", s.post,
                                  f"/api/v1/challenges/{created['id']}/milestones/{created['milestones'][i]['id']}/complete")

    def recompute(self, st: PersonaState):
        """Lecturas que recalculan lo derivado con el histórico ya en su sitio."""
        s = st.s
        for w in range(-(self.H // 7) - 1, 3):
            ws = self.week0 + timedelta(weeks=w)
            self.try_call(st, 0, "sync carga semanal", s.post, f"/api/v1/planner/weekly-loads/{ws}/sync")
        for path in ("/api/v1/insights/cross-regulation?tz=Europe/Madrid", "/api/v1/streak?zone=Europe/Madrid",
                     "/api/v1/insights/cognitive-state?tz=Europe/Madrid"):
            self.try_call(st, 0, path, s.get, path)
        self.try_call(st, 0, "evaluar insignias", s.post, "/api/v1/badges/evaluate?zone=Europe/Madrid")
        self.try_call(st, 0, "racha", s.get, "/api/v1/streak?zone=Europe/Madrid")

    def tidy(self, st: PersonaState):
        """Preferencias de avisos reales, avisos antiguos leídos, insignias ya vistas y una insignia oculta."""
        s = st.s
        if st.spec.get("notif"):
            self.try_call(st, 0, "preferencias de avisos", s.put, "/api/v1/notifications/preferences", st.spec["notif"])
        page = self.try_call(st, 0, "avisos", s.get, "/api/v1/notifications?size=100") or {"items": []}
        yesterday = madrid(self.day(-1), 0, 0)
        for n in page["items"]:
            created = datetime.fromisoformat(n["createdAt"].replace("Z", "+00:00"))
            if not n["read"] and created < yesterday:
                self.try_call(st, 0, "leer aviso", s.post, f"/api/v1/notifications/{n['id']}/read")
        badges = self.try_call(st, 0, "insignias", s.get, "/api/v1/badges/mine?includeHidden=true") or []
        earned = [b for b in badges if b.get("earned")]
        ids = [b["id"] for b in earned if not b.get("notified")]
        if ids:
            self.try_call(st, 0, "insignias vistas", s.post, "/api/v1/badges/notified", {"badgeIds": ids})
        hide = st.spec.get("hide_badge")
        for b in earned:
            if hide and b["name"] == hide:
                self.try_call(st, 0, "ocultar insignia", s.patch, f"/api/v1/badges/{b['id']}", {"visible": False})
        # El enfoque de uso se fija al final: con un solo ámbito el servidor ya no deja crear retos
        # del otro, y el historial sembrado de ambos ámbitos sigue ahí aunque no se muestre.
        if st.spec.get("usage_focus"):
            self.try_call(st, 0, "enfoque de uso", s.patch, "/api/v1/me", {"usageFocus": st.spec["usage_focus"]})

    def final_day(self):
        self.parallel(self.phase_b)
        self.run_round(0, lambda: self.parallel(lambda st: self.do_day(st, 0)), "Hoy")
        self.parallel(self.final_extras)
        self.social(0)
        self.parallel(self.recompute)
        self.parallel(self.tidy)

    # ------------------------------------------------------------------------------------- admin

    def admin(self):
        st = next((x for x in self.states.values() if x.spec.get("admin")), None)
        if not st:
            return
        if not self.sql.enabled:
            log("! Sin --db no se puede dar el rol de administrador (se asigna por SQL, ver README).")
            return
        self.set_role(st.s.email, "admin")
        st.s.login()
        lucia = self.states.get("lucia")
        for path in ["/api/v1/admin/metrics", "/api/v1/admin/metrics/trend?days=30", "/api/v1/admin/users?size=20"]:
            self.try_call(st, 0, path, st.s.get, path)
        if lucia:
            self.try_call(st, 0, "exportar usuario", st.s.get, f"/api/v1/admin/users/{lucia.s.user_id}/export")
        log(f"· {st.s.email}: rol de administrador asignado")

    # ------------------------------------------------------------------------------------- resumen

    def summary(self) -> list[str]:
        lines = []
        for st in self.states.values():
            s = st.s
            try:
                me = s.get("/api/v1/me")
                if st.spec.get("admin"):
                    lines.append(f"{s.email}: rol {me['role']}")
                    continue
                dash = s.get("/api/v1/dashboard?tz=Europe/Madrid")
                streak = s.get("/api/v1/streak?zone=Europe/Madrid")
                badges = [b for b in s.get("/api/v1/badges/mine?includeHidden=true") if b.get("earned")]
                due = s.get("/api/v1/study-materials/due?limit=50")
                sessions = s.get("/api/v1/training/sessions?completed=true&size=1")["totalItems"]
                cr = dash["crossRegulation"]
                acwr = f"{cr['acwr']:.2f}" if cr.get("acwr") is not None else "—"
                lines.append(
                    f"{s.email}: nivel {me['level']} ({me['levelXp']}/{me['levelThreshold']} XP), racha {streak['currentDays']} d, "
                    f"{sessions} sesiones, ACWR {acwr} {cr['zone']}, carga cognitiva {dash['cognitive']['cognitiveLoad']:.2f}, "
                    f"{len(badges)} insignias, {len(due) if isinstance(due, list) else due} repasos pendientes, "
                    f"{len(dash['activeChallenges'])} retos activos")
            except ApiError as e:
                lines.append(f"{s.email}: no se pudo leer el resumen ({e})")
        return lines

    # ------------------------------------------------------------------------------------- orquestación

    def run(self):
        todo = self.prepare()
        if not todo:
            log("No hay nada que crear.")
            return
        if not self.sql.enabled and not self.args.no_history:
            sys.exit("Para construir el histórico hace falta --db local o --db prod (o --no-history).")
        for spec in todo:
            self.states[spec["key"]] = PersonaState(spec, UserSession(self.api, demo_email(spec["email"]), self.password))
        self.pending_states = list(self.states.values())
        started = time.time()
        log(f"Seed de {len(todo)} personas en {self.api.base_url} · hoy {self.today} · histórico de {self.H} días")
        if self.args.no_history:
            self.H = 0
        self.round0()
        for st in self.states.values():
            if not st.spec.get("admin"):
                self.plan_sessions(st)
        if self.H:
            self.phase_a()
        for d in range(-self.H, 0):
            def actions(d=d):
                self.parallel(lambda st: self.do_day(st, d))
                self.social(d)
            self.run_round(d, actions, f"Día {d}", next_d=d + 1)
        self.final_day()
        self.admin()
        lines = self.summary()
        log("\nResumen:")
        for line in lines:
            log("  " + line)
        self.run_log["summary"] = lines
        self.run_log["errors"] = self.errors
        self.run_log["apiCalls"] = self.api.calls
        self.run_log["seconds"] = int(time.time() - started)
        out_dir = HERE / "runs"
        out_dir.mkdir(exist_ok=True)
        host = urllib.parse.urlparse(self.api.base_url).hostname or "api"
        out = out_dir / f"{host}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        out.write_text(json.dumps(self.run_log, ensure_ascii=False, indent=2), encoding="utf-8")
        log(f"\n{self.api.calls} llamadas en {int(time.time() - started)} s · {len(self.errors)} errores · registro: {out}")


def main():
    p = argparse.ArgumentParser(description="Crea los usuarios demo de SynaptixFit con histórico realista.")
    p.add_argument("--base-url", default="http://localhost:8080")
    p.add_argument("--password-env", default="DEMO_PASSWORD",
                   help="Variable de entorno con la contraseña común (si falta, se lee de ~/.config/synaptixfit/demo.env)")
    p.add_argument("--only", action="append", default=[],
                   help="Email o clave de persona a crear (repetible). Por defecto, todas.")
    p.add_argument("--reset", action="store_true", help="Borra y recrea las personas que ya existan")
    p.add_argument("--db", choices=["local", "prod", "none"], default="local",
                   help="Dónde ejecutar el SQL de fechas: contenedor local, producción por ssh o ninguno")
    p.add_argument("--days", type=int, default=35, help="Días de histórico (máx. 35, el que cubren las personas)")
    p.add_argument("--no-history", action="store_true", help="Sin histórico: todo con fecha de hoy (no necesita --db)")
    p.add_argument("--ai-budget", type=int, default=3, help="Máximo de llamadas a la IA (DeepSeek cuesta dinero)")
    p.add_argument("--no-ai", action="store_true", help="No llamar a la IA")
    args = p.parse_args()
    args.days = max(7, min(35, args.days))
    specs = PERSONAS
    if args.only:
        wanted = {o.split("@")[0].casefold() for o in args.only}
        specs = [x for x in PERSONAS if x["key"] in wanted or x["email"].casefold() in wanted]
        if not specs:
            sys.exit("--only no coincide con ninguna persona: " + ", ".join(f"{x['email']}@{DOMAIN}" for x in PERSONAS))
    password = load_password(args.password_env)
    api = Api(args.base_url)
    sql = SqlRunner(args.db)
    Seeder(args, api, sql, password, specs).run()


if __name__ == "__main__":
    main()
