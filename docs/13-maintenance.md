# 13 - Mantenimiento

**Proyecto:** SynaptixFit  
**Versión:** 1.3
**Fecha:** 28-05-2026
**Referencia:** [03-architecture.md](03-architecture.md) (sección 8.3), [04-data-model.md](04-data-model.md) (sección 6)

---

## 1. Gobierno del Catálogo de Ejercicios

### 1.1 Estado actual — Dataset final unificado

1. **Fuente única:** Dataset Lyfta como base (~682 ejercicios con video) + ExerciseDB (~200+) complementario, unificados en un JSON final.
2. **Alcance:** ~909 ejercicios únicos, 93 músculos, 13 partes del cuerpo, ~23 equipamientos.
3. **Almacenamiento:** Datos en Supabase (`ejercicios`, tablas M:N), multimedia en Cloudflare R2 servida vía Worker proxy.
4. **Sin dependencia runtime de proveedores externos:** todo el contenido se sirve desde infraestructura propia.

### 1.2 Dataset Fusionado

Tras evaluar múltiples fuentes (Lyfta, ExerciseDB/Kaggle, Demic, wger), se optó por un **dataset final fusionado**:

1. Se tomó como base el scraping de Lyfta (~682 ejercicios con video real).
2. Se complementó con ejercicios de ExerciseDB que no existían en Lyfta (~200+).
3. Se eliminaron duplicados por nombre (case-insensitive).
4. Se generó un JSON unificado que alimenta `seed_ejercicios.py`.

### 1.3 Pipeline de Seeding

```bash
# Desde la raíz del proyecto
python supabase/seed_ejercicios.py       # Carga catálogo completo (909 ejercicios)
python supabase/seed_catalogo.py         # Universidades, carreras, asignaturas
python supabase/seed_usuarios.py         # Usuarios mock
python supabase/seed_asignaturas.py      # Asignaturas de usuario desde grados.json
python supabase/seed_demo_data.py        # Datos demo completos
```

El script `seed_ejercicios.py`:
1. UPSERT catálogos (`musculos`, `partes_cuerpo`, `equipamientos`)
2. INSERT ejercicios con deduplicación por nombre
3. UPSERT relaciones M:N (`ejercicio_musculos_secundarios`, `ejercicio_equipamiento`)
4. Asigna `finalidad` automáticamente (`cardio`, `isometrico`, `fuerza`, `hipertrofia`, `resistencia`, `movilidad`)

### 1.4 Catálogo actual (08-06-2026)

| Recurso | Cantidad |
|---------|----------|
| Ejercicios únicos | ~909 |
| Partes del cuerpo | 13 |
| Músculos | 93 (incluye `cardiovascular` para cardio, 9 redundantes históricos) |
| Equipamientos | ~23 |
| Relaciones M:N (ejercicio↔músculo sec.) | ~3360 (cardinalidad media 1:3.7) |
| Migraciones aplicadas | 49 (0001→0050) |
| Fuentes de datos | Lyfta (682) + ExerciseDB (200+) fusionados |

### 1.5 Historial técnico (fuentes descartadas)

| Fuente | Estado | Motivo |
|--------|--------|--------|
| wger | Descartado | Docker pesado, multimedia insuficiente |
| ExerciseDB (Kaggle) | Absorbido | GIFs rotos por restricciones de caché, se integraron metadatos |
| Demic | Absorbido | ~55 ejercicios con video, integrados en fusión |

**Decisión de almacenamiento propio:** Debido a que los GIFs de ExerciseDB expiran y tienen restricciones de caché, toda la multimedia se sirve desde Cloudflare R2 vía Worker proxy, garantizando disponibilidad permanente.

### 1.6 Clasificación automática de finalidad

El seed script clasifica automáticamente cada ejercicio:

| Finalidad | Criterios |
|-----------|-----------|
| `cardio` | Músculo `cardiovascular` o nombre contiene palabras clave bilingües |
| `isometrico` | Nombre contiene: plancha, plank, isométrico, wall sit, etc. |
| `fuerza` | Default para ejercicios de fuerza/compuestos |
| `hipertrofia` | Asignable manualmente; soporte de schema desde migración 0019 |
| `resistencia` | Asignable manualmente |
| `movilidad` | Asignable manualmente |

### 1.7 Deprecación de `exercise_db_id`

Migración 0020:
- `exercise_db_id` es nullable, sin UNIQUE.
- Índice `idx_ejercicios_exercise_db_id` eliminado.
- Vista `v_ejercicios_completos` ya no expone el campo.
- Código Flutter sin dependencia de `exerciseDbId`.

### 1.8 Validaciones de mantenimiento

| Criterio | Mínimo requerido |
|---|---|
| Integridad relacional | Coincidencia entre ejercicios, músculos, equipos y partes del cuerpo |
| Calidad multimedia | URLs de R2 accesibles vía Worker proxy |
| Reproducibilidad | `seed_ejercicios.py` debe ser idempotente |
| Trazabilidad | Versión del JSON unificado registrada

---

## 2. Backups

### 2.1 Base de datos (Supabase)

| Tipo | Frecuencia | Retención |
|------|-----------|-----------|
| Automático (Supabase) | Diario | 7 días (plan Free) / 30 días (plan Pro) |
| Manual (pg_dump) | Semanal | Almacenado en R2 (`synaptixfit-backups/`) |

### 2.2 Multimedia (Cloudflare R2)

| Tipo | Frecuencia | Retención |
|------|-----------|-----------|
| R2 inherente | Continuo | Ilimitado (dentro del límite de almacenamiento) |
| Cross-region | Mensual (futuro) | Replicación a segundo bucket |

---

## 3. Migraciones de Base de Datos

### 3.1 Crear nueva migración

```bash
supabase migration new nombre_descriptivo
# Editar: supabase/migrations/YYYYMMDDHHMMSS_nombre_descriptivo.sql
```

### 3.2 Aplicar migraciones

```bash
# Desarrollo local
supabase db push

# Si el CLI no está vinculado:
# Ejecutar migraciones_pendientes.sql en el SQL Editor de Supabase
```

### 3.3 Revertir migración

Cada migración debe tener su script de rollback:

```
supabase/migrations/
  20260419100000_crear_tabla_retos.sql       ← UP
  20260419100000_crear_tabla_retos_down.sql  ← DOWN (rollback)
```

---

## 4. Actualización de Dependencias

### 4.1 Flutter y Dart

```bash
# Verificar dependencias desactualizadas
flutter pub outdated

# Actualizar a últimas compatibles
flutter pub upgrade

# Actualizar restricciones de versión
flutter pub upgrade --major-versions
```

### 4.2 Supabase CLI

```bash
# Actualizar Supabase CLI (requiere npm si se instaló globalmente)
npm update -g supabase
# Alternativa: descargar binario desde github.com/supabase/cli/releases
```

---

## 5. Monitoreo Operativo

### 5.1 Alertas críticas

| Evento | Umbral | Acción |
|--------|--------|--------|
| Queries lentas | > 500ms | Revisar índices y query plan |
| Errores Supabase | > 1% | Revisar logs en Dashboard |
| Espacio R2 | > 80% del límite | Evaluar upgrade o limpieza |
| Conexiones Realtime | > 80% del límite | Evaluar upgrade de plan |

### 5.2 Logs

| Fuente | Ubicación |
|--------|----------|
| Base de datos | Supabase Dashboard → Database → Query Performance |
| Aplicación Flutter | Consola de debug / Crashlytics (producción) |

---

**Documento compilado:** 08-06-2026  
**Última revisión:** v1.2
