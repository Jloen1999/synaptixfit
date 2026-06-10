# 07 - Backend (Servicios y Lógica del Servidor)

**Proyecto:** SynaptixFit
**Versión:** 3.0
**Fecha:** 07-06-2026
**Referencia:** [03-architecture.md](03-architecture.md), [04-data-model.md](04-data-model.md)

---

## 1. Arquitectura Backend

SynaptixFit utiliza Supabase como backend gestionado (PostgreSQL + Auth + Realtime + Edge Functions), con Cloudflare R2 para almacenamiento multimedia y Google Gemini Flash como motor de IA generativa.

| Capa | Tecnología | Responsabilidad |
|------|-----------|----------------|
| Base de datos | Supabase PostgreSQL 15 | Almacén relacional con 29+ tablas, RLS, vistas (49 migraciones aplicadas, hasta 0050) |
| Autenticación | Supabase Auth (GoTrue) | JWT, Google OAuth, Email OTP/Magic Link |
| Tiempo real | Supabase Realtime (WebSocket) | Streaming de cambios en 8 tablas del catálogo de ejercicios |
| Orquestación | Supabase Edge Functions (Deno) | Lógica de negocio sensible (clonación, validación, notificaciones) |
| Jobs programados | pg_cron (PostgreSQL) | Job nocturno de recomendaciones diarias (2 AM) |
| Almacenamiento multimedia | Cloudflare R2 | GIFs de ejercicios (~1300 archivos, resolución 360x360) |
| Proxy multimedia | Cloudflare Worker `synaptixfit-r2-proxy` | CORS + acceso público a bucket R2 |
| **IA generativa** | **Gemini Flash API (Google)** | **Refinamiento de rutinas (motor de reglas determinista como base)** |
| **IA — HTTP client** | **Dio (Flutter)** | **Peticiones directas a `generativelanguage.googleapis.com`** |
| **Motor de reglas** | **Dart (cliente)** | **Pipeline determinista: sanitización → reglas → contexto → transición → progresión** |
| **Motor de feedback** | **Dart (cliente)** | **Procesamiento post-sesión: degradación dinámica, inactividad, fatiga** |

### 1.1 ¿Por qué la IA se ejecuta en cliente y no en Edge Function?

| Decisión | Razón |
|----------|-------|
| IA en cliente (adoptado) | Menor latencia (sin doble salto), sin coste de Edge Function, response directa al UI |
| IA en Edge Function | API key nunca sale del backend, pero añade latencia de red extra |

Para MVP/TFG, la simplicidad y latencia del enfoque cliente-side son preferibles. La API key de Gemini tiene scope limitado (solo generación de texto) y viaja sobre HTTPS. Para producción futura, se recomienda mover a Edge Function con rate limiting.

## 2. Migraciones — Historial Completo

Todas las migraciones en `supabase/migrations/` se aplican en orden numérico con `supabase db push`. Actualmente hay **49 archivos de migración** cubriendo desde la creación inicial (0001) hasta la constraint de objetivos estándar (0050).

| # | Archivo | Fecha | Descripción |
|---|---------|-------|-------------|
| 0001 | `20260419_0001_init_schema.sql` | 19-04-2026 | Esquema inicial: tablas core, índices, funciones y RLS |
| 0002 | `20260421_0002_add_rls_bienestar.sql` | 21-04-2026 | RLS para tablas de bienestar |
| 0003 | `20260421_0003_restore_table_grants*.sql` | 21-04-2026 | Restauración de permisos PostgREST tras reset de schema |
| 0004 | `20260421_0004_backfill_usuarios*.sql` | 21-04-2026 | Trigger `auth.users → public.usuarios` + backfill |
| 0005 | `20260421_0005_add_academic_profile*.sql` | 21-04-2026 | `perfil_academico_usuario` y `carga_academica_semanal` |
| 0006 | `20260422_0006_ejercicios_v2_normalizado.sql` | 22-04-2026 | Modelo 3NF de ejercicios (8 tablas: catálogos + N:M + vista) |
| 0007 | `20260422_0007_seed_estudiantes.sql` | 22-04-2026 | Seed de usuarios de prueba |
| 0008 | `20260501_0008_enable_realtime_ejercicios.sql` | 01-05-2026 | Realtime en las 8 tablas del catálogo de ejercicios |
| 0009 | `20260504_0009_add_docente_archivado_asignaturas.sql` | 04-05-2026 | Campos `docente` y `archivado` en `asignaturas` |
| 0010 | `20260504_0010_catalogo_academico.sql` | 04-05-2026 | Tablas catálogo académico + RLS pública |
| 0011 | `20260504_0011_planes_estudio.sql` | 04-05-2026 | Tabla `planes_estudio`, columnas en `horarios_academicos` |
| 0012 | `20260505_0012_apuntes.sql` | 05-05-2026 | Tabla `apuntes` (Markdown, visibilidad) + RLS |
| 0013 | `20260506_0013_usuario_carreras.sql` | 06-05-2026 | Tabla `usuario_carreras` (M:N usuario ↔ carrera) |
| 0014 | `20260509_0014_performance_indexes.sql` | 09-05-2026 | Vista materializada `mv_ejercicios_completos`, índices GIN, triggers |
| 0015 | `20260510_0015_rutinas_periodizacion.sql` | 10-05-2026 | Tablas `semanas_rutina`, `dias_rutina`, `series_sesion`. Periodización completa |
| 0016_a | `20260510_0016_plan_semanal_v2.sql` | 10-05-2026 | Versión 2 del plan semanal |
| 0016_b | `20260511_0016_estado_diario.sql` | 11-05-2026 | Tabla `estado_diario_usuario` (check-in fatiga). RLS |
| 0017 | `20260511_0017_periodizacion_tipo_semana.sql` | 11-05-2026 | Columna `tipo_semana` en `semanas_rutina` |
| 0018_a | `20260511_0018_fix_objetivo_constraint.sql` | 11-05-2026 | Fix de constraint de objetivo |
| 0018_b | `20260519_0018_finalidad_ejercicios.sql` | 19-05-2026 | Columna `finalidad` en `ejercicios` |
| 0019_a | `20260513_0019_fix_objetivo_check_constraint.sql` | 13-05-2026 | Fix de check constraint de objetivo |
| 0019_b | `20260527_0019_ampliar_finalidad.sql` | 27-05-2026 | Amplía CHECK de `finalidad` |
| 0020_a | `20260514_0020_trigger_cascada_semana.sql` | 14-05-2026 | Trigger cascada días→semanas |
| 0020_b | `20260528_0020_deprecar_exercise_db_id.sql` | 28-05-2026 | `exercise_db_id` nullable |
| 0021 | `20260528_0021_limpiar_ejercicios.sql` | 28-05-2026 | Limpieza de datos de ejercicios |
| 0022 | `20260528_0022_vista_ejercicios_security_invoker.sql` | 28-05-2026 | Vista SECURITY INVOKER |
| 0023 | `20260528_0023_actualizar_dificultad_ejercicios.sql` | 28-05-2026 | Dificultad: principiante/intermedio/avanzado |
| 0024-0027 | *(saltos en numeración)* | 28-05-2026 | Inserción de equipamientos (0024), partes_cuerpo (0025), músculos (0026), ejercicios (0027) |
| 0028 | `20260528_0028_eliminar_exercise_db_id.sql` | 28-05-2026 | Elimina `exercise_db_id`, `mv_ejercicios_completos` |
| 0029 | `20260529_0029_agregar_url_imagen_musculos.sql` | 29-05-2026 | `url_imagen` en `musculos` |
| 0030 | `20260529_0030_eliminar_musculos_duplicados.sql` | 29-05-2026 | Remapea y elimina 9 músculos redundantes |
| 0031 | `20260529_0031_actualizar_url_imagen_webp.sql` | 29-05-2026 | Conversión de PNG a WebP |
| 0032 | `20260529_0032_multi_finalidad.sql` | 29-05-2026 | `finalidad` pasa a `TEXT[]` (multi-finalidad) |
| 0033 | *(salto)* | — | (no utilizado) |
| 0034 | `20260529_0034_preparar_dataset_final.sql` | 29-05-2026 | Preparación para dataset final |
| 0035 | `20260529_0035_insertar_musculos_final.sql` | 29-05-2026 | Inserción de 93 músculos del dataset final |
| 0036 | `20260529_0036_insertar_partes_cuerpo_final.sql` | 29-05-2026 | 13 partes del cuerpo del dataset final |
| 0037 | `20260529_0037_insertar_equipamientos_final.sql` | 29-05-2026 | 24 equipamientos del dataset final |
| 0038 | `20260529_0038_insertar_ejercicios_final.sql` | 29-05-2026 | Inserción de ~909 ejercicios del dataset final |
| 0039 | `20260603_0039_optimizar_vista_ejercicios.sql` | 03-06-2026 | Optimización de `v_ejercicios_completos` |
| 0040 | `20260603_0040_optimizar_rendimiento_catalogo.sql` | 03-06-2026 | Optimización rendimiento catálogo |
| 0041 | `20260603_0041_corregir_nombres_ejercicios.sql` | 03-06-2026 | Corrección de nombres de ejercicios |
| 0042 | `20260603_0042_seed_completo_desde_json.sql` | 03-06-2026 | Seed completo desde `dataset_final.json` |
| 0043 | `20260604_0043_agregar_modalidad_medicion_circuito.sql` | 04-06-2026 | Modalidad medición y circuito |
| 0044 | `20260604_0044_estandarizar_finalidades_objetivo.sql` | 04-06-2026 | Estandarización de finalidades y objetivo |
| 0045 | `20260605_0045_pesos_por_serie.sql` | 05-06-2026 | Columna `pesos_kg jsonb` en `seleccion_de_ejercicios` |
| 0046 | `20260606_0046_historial_objetivos.sql` | 06-06-2026 | Tabla `historial_objetivos` (transición de objetivos) |
| 0047 | `20260606_0047_failed_reps.sql` | 06-06-2026 | Columna `failed_reps` en `series_sesion` |
| 0048 | `20260606_0048_recomendaciones_pendientes.sql` | 06-06-2026 | Tabla `recomendaciones_pendientes` (feedback engine) |
| 0049 | `20260606_0049_func_daily_recommendations.sql` | 06-06-2026 | Función `generar_recomendaciones_diarias()` para pg_cron |
| 0050 | `20260607_0050_fix_objetivo_constraint.sql` | 07-06-2026 | `ck_perfil_objetivo_estandar` con finalidadesEstandar |

> **Nota sobre numeración:** El proyecto tiene 49 archivos de migración. La numeración salta algunos números (0024-0027 se fusionaron, 0033 no se usó, 0016-0020 tienen dos archivos cada uno). La migración más alta es la 0050. Siempre aplicar en orden cronológico (por fecha en el nombre del archivo), no por número.

## 3. Servicio de IA — `RecomendacionIaService`

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart` (1047 líneas)

**Modelo:** Gemini Flash (`gemini-flash-latest`) vía REST API.
**Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent`
**Autenticación:** `X-goog-api-key` header (API key desde `.env`)
**Timeout:** 15 segundos (configurado en `Dio`)

### 3.1 Configuración

```dart
// EnvConfig (app/lib/core/config/env_config.dart)
static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');

// Uso en el servicio
final apiKey = EnvConfig.geminiApiKey;
if (apiKey.trim().isEmpty) {
  return RecomendacionRutinaResult(..., error: 'Falta GEMINI_API_KEY...');
}
```

### 3.2 Métodos del Servicio

#### 3.2.1 `generarRecomendacionRutina()`

**Propósito:** Generar metadatos de una rutina (nombre, descripción, objetivo, duración, estructura semana×día con ejercicios) basándose en el perfil completo del usuario.

**Parámetros:**
```dart
Future<RecomendacionRutinaResult> generarRecomendacionRutina({
  required String apiKey,                    // GEMINI_API_KEY
  required PerfilBienestarDb perfil,         // Datos antropométricos + objetivo + equipamiento
  required List<EjercicioDb> ejerciciosDisponibles,  // Catálogo completo (se filtra por equipamiento)
  HistorialSesionDto? historial,             // Historial de sesiones (opcional)
  EstadoDiarioDb? estadoDiario,              // Check-in de hoy (opcional)
})
```

**Flujo de ejecución:**

```
1. Validar apiKey → si vacía, retornar error
2. Filtrar ejerciciosDisponibles por equipamiento compatible (_ejercicioUsaEquipamiento)
3. Si no hay ejercicios compatibles → retornar error con equipamiento listado
4. Construir prompt con 7 secciones:
   a. CONTEXTO DEL USUARIO (perfil completo + IMC + categoría IMC)
   b. REGLAS DE SEGURIDAD SEGÚN BIOMETRÍA (_reglasSeguridadIMC)
   c. REGLAS DE EQUIPAMIENTO (solo equipamiento declarado)
   d. HISTORIAL DEPORTIVO (_formatearHistorial)
   e. REGLAS DE RECOMENDACIÓN SEGÚN OBJETIVO (reps, descanso, tipo ejercicios)
   f. PERIODIZACIÓN (reglas de tipo de semana)
   g. FORMATO JSON ESPERADO
5. Enviar prompt a Gemini vía _callGemini()
6. Extraer JSON de la respuesta (_extraerJson)
7. Parsear estructura: semanas → días → ejercicios → List<EjercicioRecomendado>
8. Retornar RecomendacionRutinaResult con nombre, desc, objetivo, duración, estructura
```

**Prompt Engineering — Secciones clave:**

- **System prompt implícito:** "Eres un entrenador personal profesional con amplia experiencia en prescripción de ejercicio."
- **Constraint:** "Responde ÚNICAMENTE con un JSON válido. No uses Markdown ni bloques de código."
- **Biometría:** Se incluye edad, sexo, peso, altura, IMC con 1 decimal y categoría (Normal, Sobrepeso, Obesidad, Bajo peso).
- **Equipamiento:** "SOLO puedes recomendar ejercicios que usen el equipamiento listado arriba."
- **Estructura esperada:** `{"nombre": "...", "descripcion": "...", "objetivo": "...", "duracionSemanas": N, "estructura": {"1": {"1": [{...}]}}}`

#### 3.2.2 `generarEstructuraCompleta()`

**Propósito:** Generar la estructura completa de ejercicios (semanas × días × ejercicios) para una rutina ya configurada por el usuario.

**Diferencias clave con `generarRecomendacionRutina()`:**

| Aspecto | `generarRecomendacionRutina` | `generarEstructuraCompleta` |
|---------|---------------------------|---------------------------|
| Metadatos de rutina | Los genera la IA | Vienen del usuario (ya configurados) |
| Catálogo | Filtrado pero no enviado completo al prompt | Enviado como JSON embebido (exerciseId + nombre + músculos + equipamiento) |
| Periodización | Genérica ("la app asigna automáticamente") | Específica por semana con volúmenes exactos |
| Sobrecarga progresiva | No incluida (no hay ejercicios previos) | Incluida si hay historial (_formatearProgresion) |
| Alternancia muscular | "Los días deben alternar grupos musculares" | Obligatorio: "No repitas el mismo grupo muscular en días consecutivos" |

**Uso en UI:** Botón "Recomendar ejercicios" en Paso 1 (visible tras haber usado "Recomendar rutina con IA").

#### 3.2.3 `generarRecomendacionEjercicios()`

**Propósito:** Sugerir 3-6 ejercicios adicionales para un día específico, sin repetir los ya agregados.

**Cuándo se usa:** Botón "Sugerir ejercicios con IA" en cada día del Paso 2 de creación de rutina.

**Particularidades:**
- El catálogo se envía COMPLETO como JSON en el prompt (limitado a ejercicios del equipamiento)
- Los `ejerciciosYaAgregados` (lista de IDs) se pasan como lista de exclusión en el prompt
- La respuesta es un **array JSON** (no objeto): `[{exerciseId, series, reps, ...}]`
- Mínimo 3, máximo 6 ejercicios

#### 3.2.4 `generarProgresionEjercicio()`

**Propósito:** Analizar el historial real de un ejercicio específico y sugerir la siguiente progresión de carga (peso, reps, series).

**Datos de entrada:**
- `historialEjercicio`: Lista de `EjericicioRecienteDto` (peso promedio, reps promedio, RPE, fecha) de sesiones previas
- `rpeUltimaSesion`: RPE reportado en la última sesión (1-10)

**Reglas de progresión (en el prompt):**

| RPE | Acción | Objetivo fuerza | Objetivo ganar_masa | Objetivo perder_peso |
|-----|--------|-----------------|--------------------|--------------------|
| < 7 | Subir peso 5-10% o +1-2 reps | Priorizar peso | Equilibrio peso/reps | Mantener peso, subir reps |
| 7-8 | Subir peso 2.5-5% | Subir peso | Subir peso o reps | Mantener |
| 8.5-9.5 | Mantener peso y reps | Mantener | Mantener | Mantener |
| = 10 | NO subir (fallo) | No subir | No subir | No subir |

**Retorno:** `EjercicioRecomendado?` (null si no hay historial o falla la API)

### 3.3 Helpers de Prompt Engineering

#### `_ejercicioUsaEquipamiento()`
Filtro de compatibilidad entre el equipamiento del ejercicio y el del usuario. `peso_corporal` siempre es compatible. Incluye mapeo de equivalencias:
- `mancuerna` ↔ `mancuernas`
- `banda_elastica` ↔ `banda de resistencia`
- `kettlebell` ↔ `pesa rusa`
- `polea` ↔ `polea`
- `maquina` ↔ contiene `máquina`

#### `_reglasSeguridadIMC(imc, edad)`
Genera restricciones condicionales basadas en guías ACSM:

| Condición | Reglas generadas |
|-----------|-----------------|
| IMC > 30 | Evitar saltos pliométricos, carrera. Priorizar bajo impacto articular. Evitar carga lumbar excesiva. |
| IMC 25-30 | Moderar ejercicios de alto impacto. Buena técnica ante todo. |
| IMC < 18.5 | Evitar déficit calórico extremo. Priorizar ganancia de masa muscular. |
| Edad > 50 | Priorizar fortalecimiento articular y equilibrio. Evitar 1RM. Rangos 8-15 reps. Calentamiento articular 5-10 min. |
| Edad < 18 | Priorizar técnica sobre carga. Evitar pesos máximos. Énfasis en peso corporal. |

#### `_reglasPeriodizacion(duracionSemanas, historial)`
Genera la estructura de periodización lineal modificada:

| Duración | Estructura |
|----------|-----------|
| 1 semana | Sin periodización (carga) |
| 2 semanas | Adaptación (80%) → Carga (85%) |
| 3 semanas | Adaptación → Carga → Pico |
| 4+ semanas | Adaptación → Carga × (N-2) → Descarga (60%) |

**Caso especial:** Si `historial.requiereDescarga == true`, la semana 1 es DESCARGA ACTIVA y la estructura se desplaza (Descarga → Adaptación → Carga → Carga).

#### `_formatearEstadoDiario(estado)`
Traduce el check-in diario a reglas concretas para la IA:

| Condición | Instrucción a la IA |
|-----------|-------------------|
| `requiereAdaptacion` (fatiga > 50) | Reducir volumen un 30%. |
| `zonasDolor` no vacío | "SUSTITUIR ejercicios que trabajen: [zonas]. Buscar alternativas de otros grupos musculares." |
| `nivelEnergia <= 2` | "Priorizar movilidad y ejercicios de baja intensidad." |
| `calidadSueno <= 2` | "Evitar ejercicios de alta demanda neuromuscular (peso muerto, squat máximo)." |

### 3.4 Mecanismo de Parsing JSON Robusto

**`_extraerJson(String raw)`** implementa 3 estrategias en cascada:

1. **Regex para bloques de código Markdown:** Busca `` ```json ... ``` `` o `` ``` ... ``` `` y extrae el contenido interno.
2. **Búsqueda de delimitadores:** Encuentra el primer `{` o `[` y el último `}` o `]` correspondiente, extrayendo el substring.
3. **Fallback:** Si no encuentra delimitadores, lanza `Exception('No se encontró JSON en la respuesta de Gemini')`.

Esto es necesario porque Gemini a veces envuelve el JSON en bloques de código Markdown a pesar de las instrucciones en contrario.

### 3.5 Manejo de Errores de IA

**`_parseError(Object e)`** clasifica los errores:

| Tipo de error | Mensaje al usuario |
|--------------|-------------------|
| `DioException` con status 400/401/403 | "Error de autenticación con Gemini. Revisa GEMINI_API_KEY." |
| `DioException` (otros) | "No se pudo conectar con Gemini en este momento." |
| `FormatException` | "Gemini generó una respuesta con formato no válido. Inténtalo de nuevo." |
| Otros | "Error inesperado: {primeros 100 caracteres}" |

### 3.6 Motor de Reglas Determinista (Fases 0-2)

#### 3.6.1 Sistema Unificado de Objetivos — `string_utils.dart`

**Archivo:** `app/lib/shared/utils/string_utils.dart` (63 líneas)

Define la fuente única de verdad para los 7 objetivos de entrenamiento en español:

```dart
const finalidadesEstandar = [
  'Hipertrofia Muscular',
  'Fuerza Máxima',
  'Potencia y Explosividad',
  'Fuerza Resistencia',
  'Movilidad y Flexibilidad',
  'Estabilidad y Control Motor',
  'Acondicionamiento Metabólico',
];

String sanitizarObjetivo(String raw) {
  // 1. Coincidencia exacta normalizada contra finalidadesEstandar
  // 2. Mapeo legacy (hipertrofia→Hipertrofia Muscular, fuerza→Fuerza Máxima, etc.)
  // 3. Fallback: 'Hipertrofia Muscular'
}
```

Esta función es usada por todos los servicios del motor de recomendaciones: `ParametrosObjetivo.de()`, `RecomendacionReglasService`, `RecomendacionContextoService`, `TransicionObjetivoService` y los 4 prompts de Gemini.

#### 3.6.2 Tabla de Parámetros por Objetivo — `ParametrosObjetivo`

**Archivo:** `app/lib/features/bienestar/infrastructure/parametros_objetivo.dart` (196 líneas)

Clase inmutable con `static const tabla` de 7 entradas calibradas contra `dataset_final.json`. Factory `ParametrosObjetivo.de(String objetivo)` usa `sanitizarObjetivo()` internamente.

**Campos por entrada:**
- `seriesMin/Max`, `repsMin/Max`, `descansoMin/Max` — rangos de prescripción
- `rpeMin/Max` — Rate of Perceived Exertion objetivo
- `intensidadRelativa` — % de 1RM recomendado (0.30-0.85)
- `ejerciciosPorDia` — densidad de la sesión
- `priorizarCompuestos` — si el objetivo se beneficia de multiarticulares
- `modalidades` — tipo de entrenamiento (fuerza, aerobica, metabolica, movilidad)
- `finalidadesEjercicio` — finalidades de ejercicio compatibles con este objetivo
- `volumenSemanalObjetivo` — sets semanales recomendados
- `admiteCircuito` — si permite estructura de circuito

#### 3.6.3 Servicio de Reglas — `RecomendacionReglasService`

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_reglas_service.dart` (429 líneas)

Motor determinista de generación de estructura de rutina. No depende de IA.

**Métodos públicos:**
- `generarEstructura(perfil, catalogo, params, historial?)` → `Map<int, Map<int, List<EjercicioInput>>>`
- `determinarSplit(diasSemana, nivelActividad)` → `TipoSplit` (fullBody/upperLower/pushPullLegs)
- `splitLabel(split)` → `String` ("Full-Body", "Upper/Lower", "Push/Pull/Legs")

**Pipeline interno:**
1. Determinar split según días disponibles y nivel de actividad
2. Asignar músculos objetivo a cada día según split
3. Aplicar 5 filtros encadenados (dificultad, equipamiento, modalidad, músculo, historial)
4. Scorear ejercicios con 4 criterios ponderados (finalidad 40%, compuesto 25%, dificultad 20%, multi-finalidad 15%)
5. Selección balanceada: 60% compuestos + aislados, sin músculos primarios duplicados

### 3.7 Capa de Contexto (Fase 3)

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_contexto_service.dart` (216 líneas)

**DTOs:**
- `ContextoAcademico`: horasEstudioReales, nivelEstres, evaluacionesSemana, horasSuenoPromedio, tieneExamenesProximos
- `ContextoFisiologico`: pesoActual, pesoSemanaAnterior, rachaActual, nivelUsuario, modoExamenes, tendenciaPesoSemanal
- `AjusteContexto`: factorSeries, factorDescanso, restricciones, motivo

**`calcularAjustes(contextoAcademico, contextoFisiologico, estadoDiario?)` → `AjusteContexto`**

6 reglas encadenadas:
1. **Modo exámenes**: -20% series, -15% descanso
2. **FCT (Factor de Carga Total)**: Pondera horas estudio, estrés, evaluaciones, sueño (baseline 8h), dolor, energía → factor 0.5-1.0
3. **Racha**: ≥7 días → +10% series; ≥30 días → +15% series
4. **Tendencia peso**: Alerta si va contra objetivo
5. **Fatiga diaria**: >50 → -30% series; >70 → -50% series
6. **Listo para entrenar**: false → -40% series

**`aplicarAjustes(ejercicios, ajuste, params)`**: Clampa series/descanso a rangos del `ParametrosObjetivo`.

### 3.8 Calculadora de Sobrecarga Progresiva (Fase 4)

**Archivo:** `app/lib/features/bienestar/infrastructure/progresion_calculator.dart` (335 líneas)

**Métodos principales:**
- `calcular1RM(peso, reps)` → `double`: Fórmula no lineal con guard para pesos <3kg
- `generarPesosPorSerie(series, pesoBase)` → `List<double>`: Rampa 50%→75%→100%
- `calcularProgresion(ejercicioId, historialSeries, tipoMedicion, params)` → `ProgresionEjercicio`
- `degradarPorInactividad(diasInactivo, pesoActual)` → `double`: >14d→-20%, >21d→-30%
- `generarInicial(ejercicioId, series, params)` → `ProgresionEjercicio`
- `progresionarEstructura(estructura, historial, params)` → `Map<int, Map<int, List<EjercicioInput>>>`

**DTO `ProgresionEjercicio`:** nuevasSeries, nuevasRepeticiones, nuevoDescanso, nuevoPeso, pesosPorSerie, nuevaDuracionSegundos, nuevaDistanciaMetros, log.

### 3.9 Servicio de Transición de Objetivos (Fase 5)

**Archivo:** `app/lib/features/bienestar/infrastructure/transicion_objetivo_service.dart` (155 líneas)

**`calcularTransicion(objetivoActual, registroAnterior?)` → `ParametrosTransicion`**

Si el usuario cambió de objetivo (ej: Hipertrofia→Fuerza), interpola parámetros en 3 fases durante 3 semanas:
- Fase temprana (semana 1): factor 0.30 — 30% nuevo, 70% viejo
- Fase media (semana 2): factor 0.70 — 70% nuevo, 30% viejo
- Fase completa (semana 3+): factor 1.0 — 100% nuevo objetivo

**`_interpolar(a, b, t)`**: `lerpInt`/`lerpDouble` con guard `min>max` para evitar inversión de rangos.

**`aplicarTransicion(ejercicios, transicion)`**: Clampa ejercicios a rangos interpolados.

### 3.10 Refinamiento IA (Fase 6)

**Modificación en `RecomendacionIaService`:**

**`refinarRutina(estructuraBase, perfil, catalogo, apiKey)` → `Map<int, Map<int, List<EjercicioInput>>>`**

A diferencia de los métodos legacy que generaban desde cero, `refinarRutina()` recibe una estructura ya generada por el motor de reglas y la refina:
- **Prompt**: Pide mejorar nombre, descripción, variar 1-2 ejercicios por día, reordenar. NO modifica series/reps/descanso.
- **`_validarYReparar()`**: Post-procesa la respuesta de Gemini. Valida cada ejercicio contra 4 reglas: ID existe en catálogo, equipamiento compatible, dificultad válida, parámetros en rango. Si falla → revierte al ejercicio original.
- **`_validarEjercicio()`**: Validación individual con `orElse` defensivo.
- **Guards**: Catálogo vacío → retorna estructura base sin modificar. API key ausente → retorna estructura base.

### 3.11 Motor de Feedback Post-Entrenamiento (Fase 7)

**Archivo:** `app/lib/features/bienestar/infrastructure/feedback_engine.dart` (130 líneas)

**`procesarSesion(sesionId, usuarioId, rutinaId?)`**: 
- Lee `series_sesion` con la nueva columna `failed_reps`
- Calcula degradación dinámica: cada repetición fallida descuenta 5% (clamp 70-95%). No usa 15% fijo.
- Inserta en `recomendaciones_pendientes` con tipo `degradacion` o `progresion`.

**`detectarInactividad(usuarioId)`**:
- `DateTime.tryParse` seguro sobre `completada_en`
- Si >7 días inactivo → inserta recomendación de reenganche al 80%.

**`generarAlertaFatiga(usuarioId)`**:
- Try-catch defensivo. Si fatiga promedio 3 días >50 → inserta en `notificaciones`.

### 3.12 Orquestador del Pipeline (Fase 8)

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_orquestador_service.dart` (352 líneas)

**`generarRutina({perfil, catalogo, historial?, estadoDiario?, contextoAcademico?, contextoFisiologico?, registroObjetivoAnterior?, usarIa})` → `ResultadoGeneracion`**

Pipeline de 7 etapas secuenciales:

```
1. sanitizarObjetivo(perfil.objetivoPrincipal)
2. RecomendacionReglasService.generarEstructura()        → estructura base
3. Validación de estructura vacía (error temprano)
4. RecomendacionContextoService.aplicarAjustes()         → ajusta por academia/fisiología
5. TransicionObjetivoService.aplicarTransicion()         → interpola si cambió objetivo
6. ProgresionCalculator.progresionarEstructura()         → aplica sobrecarga
7. RecomendacionIaService.refinarRutina() [opcional]     → refina con Gemini
```

**DTOs:**
- `MetadatosGeneracion`: objetivo, split, motivoAjustes, factorCargaTotal, iaRefinada
- `ResultadoGeneracion`: nombre, descripcion, objetivo, duracionSemanas, estructura, metadatos, tieneError

**Helpers críticos:**
- `_buildTipoMedicionCache()`: Construye mapa `ejercicioId → tipoMedicion` desde catálogo real.
- `_capturarPesosKg()` / `_preservarPesosKg()`: Preserva `pesos_kg` por serie en round-trip de IA.
- `_determinarSplitLabel()`: Delega a `RecomendacionReglasService.splitLabel()` (DRY).

### 3.13 Job Nocturno — pg_cron (Fase 10)

**Función:** `generar_recomendaciones_diarias()` en PostgreSQL

**Configuración (ejecutar en SQL Editor de Supabase):**
```sql
SELECT cron.schedule(
  'recomendaciones-diarias',
  '0 2 * * *',
  'SELECT generar_recomendaciones_diarias();'
);
```

**Lógica de la función (3 pasos):**
1. **Inactividad 7-30 días**: Inserta recomendación de reenganche con factor 0.80. Deduplica (no repite si ya hay una en últimos 7 días).
2. **Fatiga alta 3 días**: Calcula fórmula de fatiga (misma que el cliente). Promedio >50 → inserta recomendación de descarga. Deduplica (no repite en últimos 3 días).
3. **Retorno**: `RETURN QUERY` de las recomendaciones generadas en esta ejecución.

**Seguridad:** `SECURITY DEFINER SET search_path = ''` para acceso a todas las tablas. `GRANT EXECUTE` solo a `authenticated`.

## 4. Sistema de Check-in Diario

### 4.1 Tabla `estado_diario_usuario` (Migración 0016)

```sql
CREATE TABLE estado_diario_usuario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  fecha DATE NOT NULL DEFAULT current_date,
  calidad_sueno INT CHECK (calidad_sueno BETWEEN 1 AND 5),
  nivel_estres INT CHECK (nivel_estres BETWEEN 1 AND 5),
  nivel_energia INT CHECK (nivel_energia BETWEEN 1 AND 5),
  dolor_muscular INT CHECK (dolor_muscular BETWEEN 1 AND 5),
  zonas_dolor TEXT[] DEFAULT '{}',
  listo_para_entrenar BOOLEAN DEFAULT true,
  notas TEXT,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(usuario_id, fecha)
);

CREATE INDEX idx_estado_diario_usuario_fecha
  ON estado_diario_usuario (usuario_id, fecha DESC);
```

### 4.2 Políticas RLS

```sql
-- Solo el propietario puede leer su check-in
CREATE POLICY estado_diario_select ON estado_diario_usuario
  FOR SELECT USING (auth.uid() = usuario_id);

-- Solo el propietario puede insertar/actualizar
CREATE POLICY estado_diario_insert ON estado_diario_usuario
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY estado_diario_update ON estado_diario_usuario
  FOR UPDATE USING (auth.uid() = usuario_id);
```

### 4.3 Lógica de Negocio (Cliente Dart)

**Puntuación de fatiga compuesta (0-100):**

```dart
int get puntuacionFatiga {
  final suenoInv = (6 - calidadSueno) * 5;    // 0-25  (sueño malo = alto)
  final estres = (nivelEstres - 1) * 5;       // 0-20  (estrés alto = alto)
  final energiaInv = (6 - nivelEnergia) * 4;  // 0-20  (energía baja = alto)
  final dolor = (dolorMuscular - 1) * 7;      // 0-28  (dolor alto = alto)
  return (suenoInv + estres + energiaInv + dolor).clamp(0, 100);
}
```

**Umbral de adaptación:** `puntuacionFatiga > 50` → `requiereAdaptacion = true`

**Justificación de pesos:** El dolor muscular recibe el mayor peso (×7) porque es la señal más directa de recuperación incompleta. El sueño (×5) es el segundo factor más importante según literatura deportiva. La energía (×4) y el estrés (×5) completan el perfil.

**`listoParaEntrenar`:** Auto-calculado como `calidadSueno > 1 OR nivelEnergia > 2`. Solo se marca como NO listo si AMBOS indicadores están en niveles críticos.

### 4.4 Persistencia — `guardarEstadoDiario()`

```dart
Future<void> guardarEstadoDiario({
  required int calidadSueno,
  required int nivelEstres,
  required int nivelEnergia,
  required int dolorMuscular,
  required List<String> zonasDolor,
  required bool listoParaEntrenar,
  String? notas,
  required WidgetRef ref,
}) async {
  final hoy = DateTime.now().toIso8601String().substring(0, 10);
  await client.from('estado_diario_usuario').upsert({
    'usuario_id': user.id,
    'fecha': hoy,
    'calidad_sueno': calidadSueno,
    'nivel_estres': nivelEstres,
    'nivel_energia': nivelEnergia,
    'dolor_muscular': dolorMuscular,
    'zonas_dolor': zonasDolor,
    'listo_para_entrenar': listoParaEntrenar,
    if (notas != null) 'notas': notas,
  }, onConflict: 'usuario_id,fecha');

  ref.invalidate(estadoDiarioHoyProvider);
}
```

**Comportamiento:** Un solo registro por usuario y día. Si el usuario ya hizo check-in hoy, se actualiza (upsert). Esto permite correcciones antes de iniciar la sesión.

## 5. Sistema de Periodización Inteligente

### 5.1 Tabla `semanas_rutina` con `tipo_semana` (Migración 0017)

```sql
ALTER TABLE semanas_rutina
  ADD COLUMN tipo_semana TEXT NOT NULL DEFAULT 'carga'
  CHECK (tipo_semana IN ('adaptacion', 'carga', 'pico', 'descarga'));

CREATE INDEX idx_semanas_rutina_tipo
  ON semanas_rutina(rutina_id, numero_semana, tipo_semana);
```

### 5.2 Algoritmo de Asignación — `_calcularTipoSemana()`

```dart
String _calcularTipoSemana(int semanaNum, int totalSemanas) {
  if (totalSemanas <= 1) return 'carga';
  if (semanaNum == 1) return 'adaptacion';
  if (semanaNum == totalSemanas && totalSemanas >= 4) return 'descarga';
  if (semanaNum == totalSemanas && totalSemanas >= 3) return 'pico';
  return 'carga';
}
```

**Tabla de decisión completa:**

| Total Semanas | Sem 1 | Sem 2 | Sem 3 | Sem 4 | Sem 5+ |
|---------------|-------|-------|-------|-------|--------|
| 1 | carga | — | — | — | — |
| 2 | adaptacion | carga | — | — | — |
| 3 | adaptacion | carga | pico | — | — |
| 4 | adaptacion | carga | carga | descarga | — |
| 5+ | adaptacion | carga | carga | carga | ... descarga |

### 5.3 Detección Automática de Necesidad de Descarga

**Provider:** `estadoPeriodizacionProvider`

**Algoritmo:**

```
ENTRADA: usuario_id
SALIDA: PeriodizacionEstado

1. Consultar sesiones_registradas (últimas 3 semanas)
   - Campos: rpe, duracion_minutos, completada_en, rutina_id
   
2. Calcular RPE promedio de todas las sesiones
   - rpePromedio = SUM(rpe) / COUNT(rpe)

3. Agrupar volumen por semana (suma de duracion_minutos)
   - volumenPorSemana[inicioSemana] += duracion_minutos

4. Detectar volumen decreciente (3 semanas consecutivas)
   - volumenDecreciente = V[n] < V[n-1] AND V[n-1] < V[n-2]

5. Consultar estado_diario_usuario (hoy)
   - puntuacionFatigaDiaria = EstadoDiarioDb.puntuacionFatiga

6. Determinar necesidad de descarga:
   necesitaDescarga = (
     rpePromedio > 8.0 AND semanasConsecutivas >= 3 AND volumenDecreciente
   ) OR (
     puntuacionFatigaDiaria > 50
   )
```

**DTO `PeriodizacionEstado`:**

```dart
class PeriodizacionEstado {
  final bool necesitaDescarga;         // TRUE si se recomienda descarga
  final double rpePromedioReciente;    // RPE promedio últimas 3 semanas
  final bool volumenDecreciente;       // TRUE si volumen bajando 3 semanas
  final int semanasConsecutivas;       // Semanas seguidas con sesiones
  final int puntuacionFatigaDiaria;    // Puntuación del check-in de hoy (0-100)
}
```

**Consumo en UI:**
- `RutinaDetalleScreen` lee `estadoPeriodizacionProvider`
- Si `necesitaDescarga == true` → banner naranja: "Tu cuerpo muestra signos de fatiga. Considera una semana de descarga."
- `NuevaRutinaScreen` pasa este dato a `generarRecomendacionRutina()` → si `necesitaDescarga`, la primera semana sugerida es de descarga

## 6. Proveedor de Historial de Sesiones

### 6.1 `historialSesionUsuarioProvider`

**Propósito:** Proporcionar a la IA un perfil completo del historial de entrenamiento del usuario.

**Consulta SQL equivalente:**

```sql
-- 1. Sesiones recientes (últimas 30)
SELECT id, rpe, completada_en
FROM sesiones_registradas
WHERE usuario_id = $userId
ORDER BY completada_en DESC
LIMIT 30;

-- 2. Series de las últimas 4 sesiones (JOIN triple)
SELECT ss.peso_kg, ss.repeticiones_realizadas,
       se.ejercicio_id, ej.nombre
FROM series_sesion ss
JOIN seleccion_de_ejercicios se ON ss.seleccion_id = se.id
JOIN ejercicios ej ON se.ejercicio_id = ej.id
WHERE ss.sesion_id IN ($ultimas4SesionesIds)
ORDER BY ss.creado_en DESC;
```

**Campos calculados en Dart (no en BD):**
- `rpePromedio`: Media aritmética de todos los RPE
- `volumenSemanalEstimado`: Suma de (peso × reps) de ejercicios recientes
- `semanasConsecutivasEntrenando`: Conteo de semanas con al menos 1 sesión
- `ejerciciosRecientes`: Agrupados por nombre de ejercicio con promedios de peso/reps

## 7. Repositorios de Dominio

Contratos de la capa de infraestructura:

| # | Repositorio | Archivo | Métodos principales |
|---|-------------|---------|-------------------|
| 1 | `BienestarRepository` | `auth/infrastructure/bienestar_repository.dart` | `obtenerPerfilBienestar()`, `guardarPerfilBienestar()`, `actualizarPerfilParcial()`, `actualizarNombre()`, `obtenerHistorialPeso()` |
| 2 | `EjerciciosRepository` | `bienestar/infrastructure/ejercicios_repository.dart` | `obtenerEjercicios()`, `obtenerEjercicioPorId()`, `obtenerCatalogos()`, `buscarEjercicios()` |
| 3 | `RecomendacionIaService` | `bienestar/infrastructure/recomendacion_ia_service.dart` | `generarRecomendacionRutina()`, `generarEstructuraCompleta()`, `generarRecomendacionEjercicios()`, `generarProgresionEjercicio()` |
| 4 | `AuthRepository` | `auth/infrastructure/auth_repository.dart` | `signInWithGoogle()`, `signInWithEmail()`, `signUp()`, `signOut()` |
| 5 | `RepositorioPlanesEstudio` | `academico/` | `crearPlan()`, `actualizarPlan()`, `eliminarPlan()`, `listarPlanesVisibles()` |
| 6 | `RepositorioApuntes` | `academico/` | `crearApunte()`, `actualizarApunte()`, `eliminarApunte()`, `listarApuntesVisibles()` |
| 7 | `RepositorioRetos` | `retos/` | `crearRetoSimple()`, `crearRetoComplejo()`, `actualizarProgreso()`, `clonarRetoPublico()` |
| 8 | `RepositorioMuro` | `social/` | `listarMuro()`, `darMeGusta()`, `quitarMeGusta()` |

## 8. Vista de Ejercicios Completos

**Vista principal:** `v_ejercicios_completos` (standalone, SECURITY INVOKER — migración 0022)

**Vista materializada (legacy):** `mv_ejercicios_completos` — ya no es consultada por `v_ejercicios_completos` desde la migración 0018. Se mantiene por compatibilidad con triggers de refresco heredados.

**Propósito:** Pre-calcular los arrays de catálogos (partes_cuerpo, musculos_objetivo, musculos_secundarios, equipamientos) para cada ejercicio mediante subqueries correlacionadas, evitando múltiples JOINs en cada consulta del frontend.

**Comportamiento de seguridad:** `SECURITY INVOKER` — la vista ejecuta con los permisos RLS del usuario que realiza la consulta, no del creador de la vista. Como las tablas subyacentes tienen política `public-read`, el acceso funciona correctamente tanto para usuarios anónimos como autenticados.

**Triggers de refresco automático:** 5 triggers sobre las tablas base (`ejercicios`, `ejercicio_parte_cuerpo`, `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_equipamiento`) ejecutan `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ejercicios_completos` ante cualquier INSERT, UPDATE o DELETE.

**Índices GIN:** Sobre los 4 arrays (`partes_cuerpo`, `musculos_objetivo`, `musculos_secundarios`, `equipamientos`) + índice FTS para búsqueda en español.

**Consulta típica del frontend:**
```dart
final data = await supabase
  .from('v_ejercicios_completos')
  .select('*')
  .ilike('nombre', '%press%')
  .eq('dificultad', 'medio')
  .limit(20);
```

## 9. Realtime — Canales Activos

| Canal / Tabla | Eventos | Uso en Frontend |
|---------------|---------|-----------------|
| `ejercicios` | INSERT, UPDATE, DELETE | `ejerciciosProvider` usa `.stream()` para refresco en vivo del explorador |
| `partes_cuerpo` | INSERT, UPDATE, DELETE | Sincronización de catálogo |
| `musculos` | INSERT, UPDATE, DELETE | Sincronización de catálogo |
| `equipamientos` | INSERT, UPDATE, DELETE | Sincronización de catálogo |
| `ejercicio_musculo_objetivo` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M |
| `ejercicio_musculo_secundario` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M |
| `ejercicio_parte_cuerpo` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M |
| `ejercicio_equipamiento` | INSERT, UPDATE, DELETE | Actualización de relaciones N:M |

## 10. Cloudflare Worker — Proxy R2

**Archivo:** `cloudflare/synaptixfit-r2-proxy/worker.js`

**Propósito:** Servir archivos multimedia de ejercicios desde el bucket R2 con CORS configurado.

**Comportamiento:**
- Las URLs de GIFs se construyen como `https://pub-XXX.r2.dev/ejercicios/360/{exercise_db_id}.gif`
- El worker aplica headers CORS para permitir acceso desde cualquier origen
- Sin autenticación (acceso público de solo lectura)

---

**Documento compilado:** 07-06-2026
**Última revisión:** v3.0
