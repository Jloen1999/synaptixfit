"""
fix_nombres_dataset.py — Fase 1: Corrige 132 nombres placeholder en dataset_final.json.

Reglas de nomenclatura:
  1. Idioma espanol, conservando terminos fitness estandar (Curl, Press, Step-up, etc.)
  2. Estandarizacion absoluta: jerga de archivo -> nombre tecnico
  3. Precision anatomica en musculos, articulaciones, equipamiento
  4. Diferenciacion con (Musculo) solo cuando hay variante que desplaza estimulo
  5. (Female) -> (Mujer), (Male) -> (Hombre)

Output: dataset_final.json con 909 nombres correctos.
"""

import json
import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
JSON_PATH = SCRIPT_DIR / "dataset_final.json"
BACKUP_PATH = SCRIPT_DIR / "dataset_final_backup.json"


CORRECCIONES: dict[int, str] = {
    # Aperturas / Flyes (5)
    293: "Aperturas con mancuerna",
    315: "Aperturas con mancuerna (Mujer)",
    404: "Aperturas inclinadas de deltoides posterior con peso corporal",
    502: "Aperturas tumbado en el suelo",
    528: "Aperturas de pie con peso corporal (Hombre)",

    # Crab (1)
    262: "Crab",

    # Dominadas / Pull-ups (4)
    313: "Dominada en L (Dorsal ancho)",
    446: "Dominada commando",
    543: "Dominada commando (Mujer)",
    644: "Dominada en plancha anti gravedad alterna",

    # Estiramientos y ejercicios varios (58)
    48: "Estiramiento de cuello frontal y trasero",
    63: "Estiramiento de cuadriceps en decubito lateral",
    69: "Estiramiento lateral de cuello",
    70: "Estiramiento lateral de cuello con presion",
    76: "Hiperextension con peso sobre fitball",
    87: "Estiramiento de cuadriceps de pie",
    88: "Estiramiento abdominal en prono (Hombre)",
    99: "Estiramiento de pecho y deltoides anterior",
    112: "Estiramiento de gemelos con manos en pared",
    116: "Estiramiento de gemelos con empuje en pared",
    153: "Estiramiento asistido de gastrocnemio tumbado",
    161: "Estiramiento asistido de pecho de pie",
    162: "Estiramiento asistido de pecho sentado",
    163: "Estiramiento de pecho con brazo flexionado",
    164: "Estiramiento de pecho en esquina",
    165: "Estiramiento asistido de pecho con traccion",
    166: "Estiramiento asistido de pecho tumbado con brazos rectos",
    167: "Estiramiento con extension vertical de brazos",
    168: "Estiramiento de flexores de los dedos",
    169: "Estiramiento de cuello con rotacion",
    170: "Estiramiento de cuello en flexion frontal",
    171: "Estiramiento rotacional de extensores del cuello",
    172: "Estiramiento rotacional de flexores del cuello",
    173: "Estiramiento de cuello en extension e inclinacion",
    180: "Estiramiento de gemelos en cuclillas con talon atras",
    181: "Estiramiento de tibiales con pie elevado",
    183: "Estiramiento de hombros de pie",
    184: "Estiramiento inverso de hombros de pie",
    185: "Estiramiento de hombro cruzando el pecho",
    186: "Estiramiento de rotadores con brazo elevado",
    187: "Estiramiento de antebrazo con dedos hacia abajo",
    188: "Estiramiento de gemelos sentado con traccion de dedos",
    189: "Cow stretch",
    190: "Estiramiento tumbado con rodilla cruzada",
    191: "Estiramiento lateral de pie",
    194: "Estiramiento asistido de oblicuos",
    227: "Elevacion de pierna y cadera tumbado (Mujer)",
    237: "Elevacion de pierna y cadera colgado (Mujer)",
    275: "Estiramiento de tobillo sentado",
    318: "Elevacion de pierna y cadera en declinado",
    327: "Estiramiento de cuadriceps en equilibrio de pie",
    331: "Estiramiento de hombros con banda detras de la espalda",
    334: "Estiramiento de hombros en extension de columna",
    427: "Elevacion de gluteo e isquiotibiales (Version 2)",
    463: "Elevacion de cadera tumbado plano (Mujer)",
    466: "Estiramiento de gemelos tumbado (Mujer)",
    467: "Estiramiento de gemelos a una pierna (Mujer)",
    494: "Extension cervical en prono",
    526: "Estiramiento de cuello sentado",
    535: "Extensiones inversas old school",
    539: "Extensiones inversas old school (Mujer)",
    558: "Estiramiento de hombros con baston (Mujer)",
    560: "Estiramiento pasando el baston alrededor (Mujer)",
    561: "Estiramiento con baston en flexion lateral (Mujer)",
    562: "Estiramiento con baston lateral a frontal (Mujer)",
    636: "Estiramiento de cuello asistido con mano (Mujer)",
    637: "Estiramiento de peroneos de pie (Mujer)",
    671: "Estiramiento de pecho en el marco de la puerta (Hombre)",

    # Fondos / Dips (5)
    159: "Fondos de triceps con peso",
    217: "Fondos con agarre ancho en barras paralelas altas",
    319: "Fondos en el suelo con silla",
    512: "Fondos de triceps en el suelo (Mujer)",
    668: "Fondos en plancha sobre barras paralelas (Hombre)",

    # Handstand (1)
    301: "Handstand",

    # Isometricos / Holds (4)
    91: "Hollow hold",
    254: "Strongman front hold",
    469: "Hold de pecho con manos atras (Mujer)",
    495: "Hold isometrico de extension cervical en prono",

    # Planchas / Planks (19)
    195: "Plancha frontal con peso",
    211: "Plancha frontal - Cadera (Correcto/Incorrecto)",
    213: "Plancha lateral - Cadera (Correcto/Incorrecto)",
    216: "Plancha - Cadera (Correcto/Incorrecto)",
    266: "Plancha frontal con elevacion de brazo y pierna (Mujer)",
    326: "Plancha frontal con elevacion de pierna (Hombre)",
    332: "Puente de isquiotibiales deslizante a una pierna con toalla",
    349: "Plancha inversa con elevacion de pierna",
    386: "Plancha frontal a un brazo",
    423: "Plancha serrucho",
    454: "Plancha lateral (Version 2) (Mujer)",
    481: "Plancha de rodillas (Mujer)",
    490: "Plancha inversa sobre codos",
    522: "Plank jack deslizante con toalla",
    523: "Plancha sobre manos",
    599: "Plancha lateral con jalon (Hombre)",
    617: "Plancha lateral con jalon (Mujer)",
    661: "Plank jack con banda de resistencia (Mujer)",
    666: "Plancha en pared (Hombre)",

    # Rollouts / Remos (5)
    396: "Rueda abdominal con apoyo en pared (Hombre)",
    406: "Rueda abdominal de rodillas con barra EZ",
    452: "Rueda abdominal en suspension (Version 2) (Mujer)",
    611: "Remo vertical con botella (Mujer)",
    612: "Remo axilar con botella (Mujer)",

    # Sentadillas / Sit-ups (26)
    50: "Sentadilla con salto II",
    65: "Sentadilla pliometrica en pared",
    121: "Sissy squat con peso corporal",
    125: "Sentadilla en pared con peso corporal",
    152: "Sentadilla sobre bosu",
    175: "Estiramiento en sentadilla sobre puntillas",
    176: "Estiramiento de Aquiles en sentadilla",
    182: "Estiramiento de dedos en sentadilla",
    273: "Complejo de movilidad de sentadilla",
    286: "Potty squat (Mujer)",
    287: "Potty squat",
    325: "Movilidad de sentadilla profunda",
    350: "Sit-up declinado con peso",
    358: "Sentadilla lateral dividida con rodillo",
    371: "Jack knife sit-up (Mujer)",
    398: "Hack squat con postura ancha en prensa (Hombre)",
    402: "Sentadilla con contrapeso (Hombre)",
    408: "Sentadilla frontal con barra de seguridad",
    482: "Sit-up con piernas rectas (Mujer)",
    520: "Step-up lateral",
    521: "Step-up lateral con impulso de rodilla",
    592: "Media sentadilla con alcance lateral (Mujer)",
    593: "Sit-up vertical (Hombre)",
    597: "Media sentadilla con alcance lateral (Hombre)",
    618: "Movilidad de sentadilla con giro (Hombre)",
    670: "Sit-up con brazos extendidos y piernas en banco (Hombre)",

    # Zancadas / Lunges (4)
    150: "Zancada con giro",
    344: "Zancada con salto",
    348: "Zancada con peso y balanceo",
    384: "Zancada estatica con patada",
}


def main():
    print("=" * 60)
    print("Fase 1: Corrigiendo nombres placeholder en dataset_final.json")
    print("=" * 60)

    # Backup
    shutil.copy2(JSON_PATH, BACKUP_PATH)
    print(f"Backup creado: {BACKUP_PATH.name}")

    # Load
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    print(f"Cargados {len(ejercicios)} ejercicios")

    # Verify indices
    max_idx = max(CORRECCIONES.keys())
    if max_idx >= len(ejercicios):
        print(f"[ERROR] Indice maximo ({max_idx}) excede tamano del JSON ({len(ejercicios)})")
        return

    # Apply corrections
    print(f"\nAplicando {len(CORRECCIONES)} correcciones...")
    corregidos = 0
    for idx, nuevo_nombre in sorted(CORRECCIONES.items()):
        anterior = ejercicios[idx]["nombre_ejercicio"]
        ejercicios[idx]["nombre_ejercicio"] = nuevo_nombre
        print(f"  [{idx}] '{anterior}' -> '{nuevo_nombre}'")
        corregidos += 1

    # Save
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(ejercicios, f, ensure_ascii=False, indent=2)
    print(f"\n[OK] {corregidos} nombres corregidos en {JSON_PATH.name}")

    # Quick verification
    print("\nVerificando que no quedan placeholders...")
    placeholders_restantes = [
        (i, e["nombre_ejercicio"])
        for i, e in enumerate(ejercicios)
        if len(e["nombre_ejercicio"]) <= 3
    ]
    if placeholders_restantes:
        print(f"[WARNING] {len(placeholders_restantes)} placeholders restantes:")
        for i, n in placeholders_restantes[:10]:
            print(f"  [{i}] '{n}'")
    else:
        print("[OK] 0 placeholders restantes")

    print("\n" + "=" * 60)
    print("Fase 1 completada")
    print("=" * 60)


if __name__ == "__main__":
    main()
