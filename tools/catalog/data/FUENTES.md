# Fuentes del catálogo académico

Datos con los que `tools/catalog/build_catalog_migration.py` genera
`backend/src/main/resources/db/migration/postgresql/V800__catalog_spain_universities_degrees.sql`.
Descargados el 23 de octubre de 2026.

| Archivo | Contenido | Fuente | Licencia |
|---|---|---|---|
| `universidades.csv` | 96 universidades españolas (50 públicas, 46 privadas) con código RUCT, tipo, comunidad y web | Registro de Universidades, Centros y Títulos (RUCT), Ministerio de Ciencia, Innovación y Universidades — <https://www.educacion.gob.es/ruct/home> | Información del sector público reutilizable (Ley 37/2007) |
| `grados.csv` | 3.479 grados «Publicado en BOE – titulación alta» con código RUCT y rama | RUCT, búsqueda de títulos por universidad | Ley 37/2007 |
| `asignaturas_uex.csv` | 3.861 asignaturas de grado de la Universidad de Extremadura, curso 2025-2026 | Datos abiertos de la UEx — <https://opendata.unex.es/> | CC-BY 4.0: «Fuente: Universidad de Extremadura» |
| `asignaturas_uc.csv` | 1.196 asignaturas de grado de la Universidad de Cantabria, curso 2026-2027 | Datos abiertos de la Universidad de Cantabria (datos.gob.es) | Dominio público (CC0) |

## Decisiones al limpiar

- Universidades: fuera los centros de Defensa, de enseñanzas artísticas, extranjeros y las que aún no tienen grados en alta.
- Grados: si conviven un plan antiguo (RD 1393/2007) y uno nuevo (RD 822/2021) con el mismo nombre, se queda el nuevo. El RUCT no publica el centro ni los créditos sin abrir cada ficha, así que los grados sin datos de asignaturas van al centro «Varios centros».
- UEx y Cantabria: los grados salen de sus asignaturas, con su centro real; los nombres en mayúsculas se pasan a formato frase y a los centros de Cantabria se les devuelven las tildes.

## Volver a generar

```bash
py -I tools/catalog/build_catalog_migration.py
```

Una migración aplicada no se edita: si los datos cambian, se genera una migración nueva.
