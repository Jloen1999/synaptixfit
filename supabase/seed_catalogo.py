"""Puebla el catálogo académico desde grados.json.

Genera INSERTs deduplicados para poblar:
  catalogo_universidades → catalogo_carreras → catalogo_asignaturas

Uso:
    python supabase/seed_catalogo.py [archivo_salida.sql]

Si no se especifica archivo de salida, se escribe a seed_catalogo.sql
en el directorio raíz del proyecto.
"""

import json
import sys
from pathlib import Path

RUTA_BASE = Path(__file__).resolve().parents[1]


def cargar_grados() -> list[dict]:
    ruta = RUTA_BASE / 'grados.json'
    with open(ruta, encoding='utf-8') as f:
        return json.load(f)


def esc(valor):
    if valor is None:
        return 'NULL'
    return f"'{str(valor).replace(chr(39), chr(39)+chr(39))}'"


def generar_inserts() -> str:
    grados = cargar_grados()
    lineas: list[str] = [
        '-- Catálogo académico generado desde grados.json',
        '-- Ejecutar contra Supabase SQL Editor o vía supabase db push',
        '',
    ]

    universidades_hechas: set[str] = set()
    carreras_hechas: set[tuple[str, str]] = set()
    asignaturas_hechas: set[tuple[str, str, str]] = set()

    for entrada in grados:
        uni = entrada.get('universidad', '')
        car = entrada.get('carrera', '')
        if not uni or not car:
            continue

        # Universidad
        if uni not in universidades_hechas:
            universidades_hechas.add(uni)
            lineas.append(
                f"INSERT INTO public.catalogo_universidades (nombre) "
                f"VALUES ({esc(uni)}) ON CONFLICT (nombre) DO NOTHING;"
            )

        # Carrera (con subquery para FK)
        clave_car = (uni, car)
        if clave_car not in carreras_hechas:
            carreras_hechas.add(clave_car)
            lineas.append(
                f"INSERT INTO public.catalogo_carreras (universidad_id, nombre) "
                f"SELECT u.id, {esc(car)} "
                f"FROM public.catalogo_universidades u WHERE u.nombre = {esc(uni)} "
                f"ON CONFLICT (universidad_id, nombre) DO NOTHING;"
            )

        # Asignaturas
        for a in entrada.get('asignaturas', []):
            nombre = a['nombre']
            clave_asig = (uni, car, nombre)
            if clave_asig in asignaturas_hechas:
                continue
            asignaturas_hechas.add(clave_asig)
            curso = a.get('curso')
            semestre = a.get('semestre')
            caracter = a.get('caracter')
            creditos = a.get('creditos')

            lineas.append(
                f"INSERT INTO public.catalogo_asignaturas "
                f"(carrera_id, nombre, curso, semestre, caracter, creditos) "
                f"SELECT c.id, {esc(nombre)}, {esc(curso)}, {esc(semestre)}, "
                f"{esc(caracter)}, {esc(creditos)} "
                f"FROM public.catalogo_carreras c "
                f"JOIN public.catalogo_universidades u ON u.id = c.universidad_id "
                f"WHERE u.nombre = {esc(uni)} AND c.nombre = {esc(car)} "
                f"ON CONFLICT (carrera_id, nombre) DO NOTHING;"
            )

    return '\n'.join(lineas)


if __name__ == '__main__':
    sql = generar_inserts()
    if len(sys.argv) > 1:
        ruta_salida = Path(sys.argv[1])
    else:
        ruta_salida = RUTA_BASE / 'seed_catalogo.sql'

    ruta_salida.write_text(sql, encoding='utf-8')
    print(f'Archivo generado: {ruta_salida} ({ruta_salida.stat().st_size:,} bytes)')
    print('Ejecuta este SQL en el SQL Editor de Supabase tras hacer db push.')
