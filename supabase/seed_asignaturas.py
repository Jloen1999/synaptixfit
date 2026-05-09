"""Genera INSERTs de asignaturas desde grados.json para un usuario concreto.

Uso:
    python supabase/seed_asignaturas.py <USUARIO_UUID> [carrera_filtro]

Ejemplo:
    python supabase/seed_asignaturas.py "tu-uuid-aqui" "Ingeniería del Software"
"""

import json
import sys
from pathlib import Path


def cargar_grados() -> list[dict]:
    ruta = Path(__file__).resolve().parents[1] / 'grados.json'
    with open(ruta, encoding='utf-8') as f:
        return json.load(f)


def generar_inserts(usuario_id: str, filtro_carrera: str | None = None) -> str:
    grados = cargar_grados()
    lineas: list[str] = []

    for entrada in grados:
        universidad = entrada.get('universidad', '')
        carrera = entrada.get('carrera', '')
        if filtro_carrera and filtro_carrera.lower() not in carrera.lower():
            continue

        lineas.append(f"-- {universidad} — {carrera}")
        for a in entrada.get('asignaturas', []):
            nombre = a['nombre'].replace("'", "''")
            curso = a.get('curso', '')
            semestre = a.get('semestre', '')
            caracter = a.get('caracter', '')
            creditos = a.get('creditos', '')
            descripcion = f'Curso {curso} · Sem {semestre} · {caracter} · {creditos} ECTS'

            lineas.append(
                f"INSERT INTO public.asignaturas (usuario_id, nombre, descripcion, archivado) "
                f"VALUES ('{usuario_id}', '{nombre}', '{descripcion}', false);"
            )
        lineas.append('')

    return '\n'.join(lineas)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Uso: python seed_asignaturas.py <USUARIO_UUID> [filtro_carrera]')
        sys.exit(1)

    uid = sys.argv[1]
    filtro = sys.argv[2] if len(sys.argv) > 2 else None
    sql = generar_inserts(uid, filtro)
    print(sql)
