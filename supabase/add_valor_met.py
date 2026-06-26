#!/usr/bin/env python3
"""
Asigna el coeficiente MET (Metabolic Equivalent of Task) del Compendio de
Adultos 2024 a cada ejercicio de dataset_final.json.

Mapeo basado en el estándar científico por categoría y modalidad de
entrenamiento:
  - Circuitos / Acondicionamiento Metabólico: 8.0
  - Aeróbico (Carrera en cinta ~8 km/h):        8.3
  - Aeróbico (Bicicleta estática, general):     7.0
  - Calistenia / Peso Corporal (Vigoroso):      8.0
  - Fuerza / Hipertrofia (Vigoroso):            6.0
  - Fuerza / Hipertrofia (Moderado):            3.0
  - Flexibilidad / Estiramientos:               2.3
  - Descanso Activo / Recuperación:             1.5
"""

import json
import os
import sys

JSON_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dataset_final.json")

# Equipamiento clasificado por categoría para asignar MET
EQUIPO_PESADO = {
    "barra", "barra EZ", "barra larga", "barra recta",
    "barra recta de polea", "mancuerna", "mancuernas",
    "kettlebell", "discos de pesas", "disco", "landmine",
    "máquina Smith", "máquina de palanca", "máquina de poleas",
    "máquina de prensa de piernas", "máquina de prensa de piernas a 45°",
    "rack de sentadillas", "cinturón de lastre", "lastre",
    "soporte de banca", "banco predicador",
}

EQUIPO_LIGERO = {
    "banda de resistencia", "banda de resistencia tubular",
    "banda elástica", "rodillo de espuma", "rodillo de muñeca",
    "toalla", "foam roller", "asistencia", "almohadilla protectora",
    "fitball", "balón medicinal",
}

EQUIPO_CARDIO = {
    "cinta rodante", "bicicleta estática", "ergómetro de remo",
    "máquina elíptica", "máquina escaladora", "comba",
    "battle ropes", "escalera de agilidad",
}

EQUIPO_CUERPO = {
    "peso corporal", "sin equipamiento", "suelo", "pared",
    "colchoneta", "anillas", "suspensión", "barra fija",
    "barra de dominadas", "barras paralelas", "barras paralelas bajas",
    "banco", "banco inclinado", "banco declinado", "banco plano",
    "banco regulable", "banco o silla", "silla", "sillas",
    "cajón", "cajón pliométrico", "déficit o escalón",
    "escalón", "escalera", "superficie elevada", "soporte",
}


def _tiene_equipo(ejercicio, categorias):
    eqs = set(ejercicio.get("equipamientos", []))
    return bool(eqs & categorias)


def _tiene_finalidad(ejercicio, textos):
    fins = set(ejercicio.get("finalidad", []))
    for t in textos:
        if t in fins:
            return True
    return False


def asignar_met(ejercicio):
    modalidad = ejercicio.get("modalidad_entrenamiento", "fuerza")
    es_circuito = ejercicio.get("es_circuito", False)

    # Circuitos y metabólico — esfuerzo máximo con mínimo descanso
    if es_circuito or modalidad == "metabolica":
        return 8.0

    # Aeróbico — distinguir entre carrera (~8.3) y bicicleta (~7.0)
    if modalidad == "aerobica":
        nombre = ejercicio.get("nombre_ejercicio", "").lower()
        eqs_lower = {e.lower() for e in ejercicio.get("equipamientos", [])}
        if any(k in eqs_lower for k in ("bicicleta", "ergómetro")):
            return 7.0
        if any(k in eqs_lower for k in ("elíptica", "escaladora")):
            return 7.0
        if any(k in nombre for k in ("bici", "cicl")):
            return 7.0
        # Cinta, carrera, comba, remo → 8.3
        return 8.3

    # Flexibilidad / Estiramientos
    if modalidad == "movilidad":
        return 2.3

    # ── Fuerza / Hipertrofia ──────────────────────────────────────────
    # Calistenia / Peso Corporal (sin carga externa) → 8.0
    if _tiene_equipo(ejercicio, EQUIPO_CUERPO) and not _tiene_equipo(ejercicio, EQUIPO_PESADO):
        return 8.0

    # Esfuerzo vigoroso con cargas libres o máquinas → 6.0
    if _tiene_equipo(ejercicio, EQUIPO_PESADO):
        return 6.0

    # Estabilidad / Control Motor → esfuerzo moderado 3.0
    if _tiene_finalidad(ejercicio, {"Estabilidad y Control Motor"}):
        return 3.0

    # Accesorios con equipo ligero → esfuerzo moderado 3.0
    if _tiene_equipo(ejercicio, EQUIPO_LIGERO):
        return 3.0

    # Fuerza Resistencia → esfuerzo moderado-alto 4.5
    if _tiene_finalidad(ejercicio, {"Fuerza Resistencia"}):
        return 4.5

    # Hipertrofia Muscular sin equipo pesado (accesorios) → 3.0
    if _tiene_finalidad(ejercicio, {"Hipertrofia Muscular"}):
        return 3.0

    # Caso por defecto para ejercicios de fuerza → 6.0
    return 6.0


def main():
    if not os.path.exists(JSON_PATH):
        print(f"ERROR: No se encuentra {JSON_PATH}")
        sys.exit(1)

    with open(JSON_PATH, "r", encoding="utf-8") as f:
        datos = json.load(f)

    print(f"Procesando {len(datos)} ejercicios...")

    conteo = {}
    for ej in datos:
        met = asignar_met(ej)
        ej["valor_met"] = met
        conteo[met] = conteo.get(met, 0) + 1

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)

    print("Asignación completada. Distribución de MET:")
    for met_val in sorted(conteo.keys()):
        print(f"  MET {met_val:4.1f} → {conteo[met_val]:5d} ejercicios")
    print(f"  TOTAL        → {len(datos):5d} ejercicios")


if __name__ == "__main__":
    main()
