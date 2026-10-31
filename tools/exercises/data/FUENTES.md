# Fuentes del catálogo de ejercicios

Datos con los que `tools/exercises/build_exercises_migration.py` genera
`backend/src/main/resources/db/migration/postgresql/V850__training_exercise_catalog_expansion.sql`.
Descargados el 23 de octubre de 2026.

| Archivo | Contenido | Fuente | Licencia |
|---|---|---|---|
| `opengym_catalogo.json` | 5.632 ejercicios: nombre en inglés, parte del cuerpo, material, músculo principal y secundarios, categoría | openGym — <https://github.com/DuarteSantos8/openGym> (`frontend/src/lib/exercises-data.js`) | AGPL-3.0 (`LICENSE-openGym-AGPL-3.0.txt`). Incluye los 1.324 de <https://github.com/hasaneyldrm/exercises-dataset> (MIT) |
| `opengym_es.json` | Nombres en español de todos y las instrucciones en español de 1.324 | openGym, `catalogue/i18n/es.json` | AGPL-3.0 (traducción) / MIT (textos de hasaneyldrm) |
| `opengym_fr.json`, `opengym_pt-BR.json` | Nombres en francés y portugués de Brasil, usados solo como pista para la IA | openGym, `catalogue/i18n/` | AGPL-3.0 (traducción) |
| `ejercicios_bd.json`, `vocabulario_bd.json` | Exportación de la BD: 5.445 ejercicios (id, nombre, material, músculos) y los 197 términos de vocabulario | Propia | Propio |
| `nombres_i18n.json`, `vocabulario_i18n.json` | Nombres de ejercicios y vocabulario en inglés, francés y portugués de Portugal | Generado con DeepSeek (`translate_names.py`, `fix_portuguese.py`) | Propio (con pistas AGPL) |
| `textos_ia.json` | Nombre natural, descripción e instrucciones redactadas para los ejercicios que no las traían en español y para los 909 del catálogo original | Generado con DeepSeek (`generate_texts.py`) a partir de nombre, material y músculos; revisado por muestreo | Propio |

**No se usa ningún vídeo ni imagen de estos repositorios**: son de Gym visual con licencia solo para esos proyectos. Los ejercicios nuevos no tienen vídeo y la app muestra el icono de su categoría.

**Obligaciones de la AGPL-3.0**: los datos derivados de openGym (catálogo y traducciones) se distribuyen con su licencia y su atribución («Fuente: openGym, Duarte Santos, AGPL-3.0»). Si la app se ofrece como servicio, el código que use esos datos debe poder obtenerse con la misma licencia; el propietario del proyecto decidió usarlos sabiendo esta condición.

## Decisiones al limpiar

- Se quitan las variantes izquierda/derecha y «v. 2», y los que ya estaban en el catálogo (mismo código de 4 cifras o mismo nombre en español).
- Músculos, material y partes del cuerpo se traducen a nuestro vocabulario (`MUSCULOS`, `EQUIPAMIENTO`… en el script). Se crea el material que faltaba: cuerda, trineo, saco de arena, bosu, barra hexagonal, rueda abdominal, maza, neumático, ergómetro de brazos, SkiErg y mazo.
- Categoría → modalidad, objetivos, forma de medir y MET (ver `docs/01-architecture/formulas.md`, fórmula 5). Dificultad por reglas: halterofilia y movimientos avanzados (pistol, muscle up, planche…) → avanzado; estiramientos, movilidad, máquinas y poleas → principiante; el resto intermedio.

## Nombres en otros idiomas (`V930`)

`translate_names.py` pide a la IA, por lotes, el nombre técnico de cada ejercicio como se dice en
un gimnasio de cada idioma (inglés, francés y portugués de Portugal), dando como pista el nombre de
openGym cuando existe. `fix_portuguese.py` corrige lo que en Portugal se dice distinto que en
Brasil («rosca» → «curl», «halter» → «haltere») y pide uno a uno los términos que faltaban.
`build_names_migration.py` escribe `V930__training_exercise_names_i18n.sql`. El español de la
BD sigue siendo el canónico. Descripciones e instrucciones no se traducen.

```bash
py -I tools/exercises/translate_names.py      # necesita DEEPSEEK_API_KEY en backend/.env; reanuda lo que falte
py -I tools/exercises/fix_portuguese.py
py -I tools/exercises/build_names_migration.py
```

## Volver a generar

```bash
py -I tools/exercises/generate_texts.py        # solo pide a la IA lo que falte
py -I tools/exercises/build_exercises_migration.py
```

Una migración aplicada no se edita: si los datos cambian, se genera una migración nueva.
