# 07 - Backend (Servicios y Lógica del Servidor)

**Proyecto:** SynaptixFit
**Versión:** 3.5
**Fecha:** 29-06-2026
**Referencia:** [03-architecture.md](03-architecture.md), [04-data-model.md](04-data-model.md)

---

## 1. Arquitectura Backend

SynaptixFit utiliza Supabase como backend gestionado (PostgreSQL + Auth + Realtime + Edge Functions), con Cloudflare R2 para almacenamiento multimedia y Google Gemini Flash como motor de IA generativa.

| Capa | Tecnología | Responsabilidad |
|------|-----------|----------------|
| Base de datos | Supabase PostgreSQL 15 | Almacén relacional con 50+ tablas, RLS, vistas (53 migraciones: 0049 esquema base + 0050 dependencias retos + 0001 trigger semana + 0001 v_analitica_semanal + 0002 social_moderacion + 0003 insignias + 0004 consolidacion_fixes + 0005 fechas_coherencia + 0006 admin_rol + 0007 nivel_actividad_check + 0008 asignaturas_usuario_semestre + 0009 admin_panel_v2 + 0010 admin_delete_user + 0011 calendar_grid + 0012 xp_planificacion + 0013 bloque_xp_tracking + 0014 retos_bloques_bridge + 0015 dia_rutina_fk + 0016 rutina_fk_fix + 0017 trigger_hito_progreso + 0018 unique_dias_rutina + 0019 fix_duplicate_fk_rutina + 0022 lienzo_continuo + 0023 lienzo_continuo_v2 + 0024 ics_sync + 0025 ics_upsert_fix + 0001 dias_disponibles_array + 0002 fix_nivel_umbral + 0003 xp_overflow_multinivel + 20260622000004 visibilidad_rls + 20260622000005 carga_xp_estudio_otorgado + 20260622000006 retos_sinergia_v2 + 20260622000007 retos_xp_tracking + 20260622000008 retos_deep_linking + 20260622000009 social_realtime + 20260622000010 perfil_fechas_semestre + 20260622000011 social_publicaciones_v2 + 20260622000012 procedencia_clones + 20260622000013 archivos_asignatura + 20260622000014 apuntes_actualizado_en + 20260622000015 apuntes_visibilidad_fix + 20260622000016 documentos_ia + 20260622000017 documentos_ia_ampliar_check + 20260625000018 perfil_academico_rls + 20260625000019 usuario_insignias_update_asignaturas_rls + 20260626000020 valor_met_ejercicios + 20260626000021 duracion_real + 20260628000022 materiales_estudio + 20260628000023 bancos_preguntas + 20260628000024 fix_rls_preguntas + 20260628000025 test_sessions + 20260629000026 horarios_metadata) |
| Autenticación | Supabase Auth (GoTrue) | JWT, Google OAuth, Email OTP/Magic Link |
| Tiempo real | Supabase Realtime (WebSocket) | Streaming de cambios en 8 tablas del catálogo de ejercicios |
| Orquestación | Supabase Edge Functions (Deno) | Lógica de negocio sensible (clonación, validación, notificaciones) |
| Jobs programados | pg_cron (PostgreSQL) | Job nocturno de recomendaciones diarias (2 AM) |
| Almacenamiento multimedia | Cloudflare R2 | GIFs de ejercicios (~1300 archivos, resolución 360x360) |
| Proxy multimedia | Cloudflare Worker `synaptixfit-r2-proxy` | CORS + subida/descarga/borrado a bucket R2 (GET, PUT, DELETE) |
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

## 2. Migraciones — Esquema Consolidado

Todas las migraciones en `supabase/migrations/` se aplican en orden numérico con `supabase db push`. Tras la consolidación (Fase 3 del Plan Maestro, 11-06-2026) y las ampliaciones posteriores, el proyecto tiene **53 archivos de migración**:

| # | Archivo | Fecha | Descripción |
|---|---------|-------|-------------|
| 0049 | `202606060049_esquema_base.sql` | 06-06-2026 | Esquema base completo (~12K líneas, pg_dump con 43+ tablas, índices, funciones, triggers, políticas RLS y datos del catálogo de ejercicios). Contiene todo el schema acumulado de las migraciones 0001→0048. |
| 0050 | `202606120050_dependencias_retos.sql` | 12-06-2026 | Sprint 7A: columnas `estado`, `dependencias UUID[]`, `tipo_condicion`, `condicion_n` en `hitos_de_reto`. Trigger `trg_hito_completado` con función `desbloquear_hitos()` (evalúa condiciones AND/OR/X_OF_Y). |
| 0001 | `202606130001_marcar_semana_completada.sql` | 13-06-2026 | Trigger `trg_marcar_semana_completada`: al completar todos los días de una semana, se marca automáticamente como `completada` (Fase A de correcciones). |
| 0001 | `202606140001_v_analitica_semanal.sql` | 14-06-2026 | Sprint 7B: vista `v_analitica_semanal` que agrega sesiones por semana (RPE promedio, volumen total, días entrenados, calorías, ejercicios distintos). Tabla `insights_analitica` para cachear insights generados. |
| 0002 | `20260616_0002_social_moderacion.sql` | 16-06-2026 | Sprint 9: moderación de feed social. Tabla `comentarios_feed` con RLS (autor edita/elimina). |
| 0003 | `20260616_0003_insignias.sql` | 16-06-2026 | Sprint 9: sistema de insignias. Tablas `insignias` (catálogo público 15 insignias) y `usuario_insignias` (M:N). |
| 0004 | `20260616_0004_consolidacion_fixes.sql` | 16-06-2026 | Consolidación de correcciones: 3 tablas nuevas (`planes_estudio`, `apuntes`, `sesiones_focus`), vista `v_ejercicios_completos`, 19 columnas añadidas a 9 tablas, 5 índices, 1 constraint corregido. |
| 0005 | `20260616_0005_fechas_coherencia.sql` | 16-06-2026 | Sprint 9: corrección de coherencia de fechas en `rutinas` (`fecha_inicio`), `retos` (`fecha_fin`), y `entregas_examenes` (`hora_entrega`). Asegura que los timestamps sean consistentes entre creación y visualización. |
| 0006 | `20260616000006_admin_rol.sql` | 16-06-2026 | Panel de administración: columna `rol` en `usuarios` (CHECK usuario/admin), función RPC `wipe_user_data(p_usuario_id)` (elimina historial preservando perfil, resetea nivel/XP/racha), políticas RLS admin bypass para `usuarios` y `sesiones_registradas`, función helper `es_admin()`. |
| 0007 | `20260616000007_nivel_actividad_check.sql` | 16-06-2026 | Rediseño del onboarding: CHECK constraint en `perfil_bienestar_usuario.nivel_actividad` (`sedentario`/`ligero`/`moderado`/`alto`). |
| 0008 | `20260616000008_asignaturas_usuario_semestre.sql` | 16-06-2026 | Mapeo de transversales: tabla `asignaturas_usuario_semestre(id, usuario_id, asignatura_id, curso, semestre)` con RLS propietario + admin bypass, UNIQUE(usuario_id, asignatura_id). Permite mapear asignaturas de semestre=0 a curso+semestre específicos. |
| 0009 | `20260616000009_admin_panel_v2.sql` | 16-06-2026 | Panel admin Fase 1 MVP: tabla `admin_auditoria` (trazabilidad de acciones administrativas con CHECK de 5 tipos de acción), vista `v_admin_metricas` (10 KPIs globales agregados), columnas de moderación en `actividades_sociales` (`reportado`, `reportado_por`, `esta_eliminado`, `eliminado_por`, `eliminado_en`), `comentarios_feed` (`reportado`, `reportado_por`) y `ejercicios` (`activo BOOLEAN DEFAULT true`). Nuevas políticas RLS admin para UPDATE/DELETE en actividades_sociales, comentarios_feed y ejercicios. |
| 0010 | `20260616000010_admin_delete_user.sql` | 16-06-2026 | Panel admin Fase 3: RPC `delete_user(p_usuario_id)` para eliminación hard de usuarios. Elimina 28+ tablas de historial + perfiles + `auth.users`. Solo admin, no puede auto-eliminarse. Complementa a `wipe_user_data` (que conserva perfil) con una eliminación definitiva para casos de spam/abuso. |
| 0011 | `20260617000011_calendar_grid.sql` | 17-06-2026 | Sprint Time-Blocking: columnas `es_fijo`, `dia_semana` en tabla `horarios_academicos`. Índice `idx_horarios_dia_semana` para consultas rápidas por día de la semana. |
| 0012 | `20260618000012_xp_planificacion.sql` | 18-06-2026 | XP unificado para planificación: columna `xp_planificacion_otorgado` en `planes_estudio`. XP base por guardar plan semanal (100 XP + 5 XP por bloque). |
| 0013 | `20260618000013_bloque_xp_tracking.sql` | 18-06-2026 | Tracking de XP por bloque y entrega: columnas `xp_bloque_otorgado` y `xp_entrega_otorgado` en `horarios_academicos`. XP por bloque completado: `ceil(minutos/30)*10`. |
| 0014 | `20260618000014_retos_bloques_bridge.sql` | 18-06-2026 | Vinculación retos↔bloques: columnas `reto_id` y `hito_id` (FK) en `horarios_academicos` para asociar bloques de estudio a retos/hitos. |
| 0015 | `20260618000015_dia_rutina_fk.sql` | 18-06-2026 | FK para días de rutina: columnas `dia_rutina_id` y `semana_rutina_id` (FK) en `dias_rutina` para trazabilidad completa. |
| 0016 | `20260618000016_rutina_fk_fix.sql` | 18-06-2026 | Corrección de FK: `rutina_id` en `dias_rutina` convertido a FK real (anteriormente era solo UUID sin constraint). |
| 0017 | `20260618000017_trigger_hito_progreso.sql` | 18-06-2026 | Trigger `trg_hito_progreso`: actualiza automáticamente el progreso de hitos cuando se completan bloques de estudio vinculados. |
| 0018 | `20260618000018_unique_dias_rutina.sql` | 18-06-2026 | Constraints UNIQUE y CHECK en `dias_rutina`: evita duplicados de día por semana y valida días 1-7.
| 0019 | `20260618000019_fix_duplicate_fk_rutina.sql` | 18-06-2026 | Elimina FK duplicada `horarios_academicos_rutina_id_fkey` que causaba error PostgREST PGRST201. |
| 0022 | `20260618000022_lienzo_continuo.sql` | 18-06-2026 | Lienzo Continuo v1: amplía CHECK de `tipo_actividad` en `horarios_academicos` (8 valores), FK `entrega_examen_id` → `entregas_examenes`, columnas nuevas en `entregas_examenes`, índice `idx_horarios_fecha_inicio`. |
| 0023 | `20260618000023_lienzo_continuo_v2.sql` | 18-06-2026 | Lienzo Continuo v2: columna `es_hito_inamovible BOOLEAN` en `horarios_academicos` + índice `idx_horarios_fecha_rango`. |
| 0024 | `20260619000024_ics_sync.sql` | 19-06-2026 | Soporte para importación/exportación de calendarios ICS (RFC 5545) a `horarios_academicos`. |
| 0025 | `20260620000025_ics_upsert_fix.sql` | 20-06-2026 | Corrección de UPSERT en sincronización ICS: maneja correctamente conflictos de clave duplicada durante importación.
| 0001 | `20260621000001_dias_disponibles_array.sql` | 21-06-2026 | Array `dias_disponibles` en `perfil_bienestar_usuario` para especificar días de entrenamiento (L-D).
| 0002 | `20260621000002_fix_nivel_umbral.sql` | 21-06-2026 | Corrección del umbral de subida de nivel: `100 × nivel` (consistente con la UI).
| 0003 | `20260621000003_xp_overflow_multinivel.sql` | 21-06-2026 | Subida de nivel inmediata con arrastre del sobrante multinivel en `otorgar_xp()`.
| 20260622000004 | `20260622000004_visibilidad_rls.sql` | 22-06-2026 | RLS en `rutinas`/`retos`/`horarios_academicos` con políticas dueño + admin + lectura de pares. Funciones SECURITY DEFINER `es_admin`/`nivel_privacidad_de`/`son_amigos`. Trigger `trg_invalidar_contenido_privado`.
| 20260622000005 | `20260622000005_carga_xp_estudio_otorgado.sql` | 22-06-2026 | Columna `xp_estudio_otorgado` en `carga_academica_semanal` (faltaba en remoto, corregía error 42703).
| 20260622000006 | `20260622000006_retos_sinergia_v2.sql` | 22-06-2026 | Refactor de Retos Fase 1: `asignatura_id`, `dificultad`, `entidad_vinculada` en `retos` y `hitos_de_reto`.
| 20260622000007 | `20260622000007_retos_xp_tracking.sql` | 22-06-2026 | Refactor de Retos Fase 5: `xp_otorgado` en `retos`/`hitos_de_reto`, RPC `restar_xp`.
| 20260622000008 | `20260622000008_retos_deep_linking.sql` | 22-06-2026 | Sincronización bidireccional reto/tarea ⇄ examen/entrega con triggers SECURITY DEFINER.
| 20260622000009 | `20260622000009_social_realtime.sql` | 22-06-2026 | Publicación `supabase_realtime` de tablas sociales con `REPLICA IDENTITY FULL`.
| 20260622000010 | `20260622000010_perfil_fechas_semestre.sql` | 22-06-2026 | Columnas `fecha_inicio_clases`/`fecha_fin_clases` en `perfil_academico_usuario` para flujo de escaneo IA.
| 20260622000011 | `20260622000011_social_publicaciones_v2.sql` | 22-06-2026 | Columnas en `actividades_sociales` para tipos de publicación enriquecidos.
| 20260622000012 | `20260622000012_procedencia_clones.sql` | 22-06-2026 | Columna `procedencia` en `rutinas` para trazabilidad de clones.
| 20260622000013 | `20260622000013_archivos_asignatura.sql` | 22-06-2026 | Tabla `archivos_asignatura` con metadatos de archivos adjuntos a una asignatura (Cloudflare R2).
| 20260622000014 | `20260622000014_apuntes_actualizado_en.sql` | 22-06-2026 | Columna `actualizado_en` en `apuntes` (faltaba en migración original).
| 20260622000015 | `20260622000015_apuntes_visibilidad_fix.sql` | 22-06-2026 | Corrige CHECK de `apuntes.visibilidad` heredado en español → valores canónicos `private`/`public`/`solo_amigos`.
| 20260622000016 | `20260622000016_documentos_ia.sql` | 22-06-2026 | Tabla `documentos_ia` para persistir resúmenes y mapas mentales generados por IA.
| 20260622000017 | `20260622000017_documentos_ia_ampliar_check.sql` | 22-06-2026 | Amplía CHECKs en `documentos_ia` para `guia_docente`.
| 20260625000018 | `20260625000018_perfil_academico_rls.sql` | 25-06-2026 | Habilita RLS en `perfil_academico_usuario` con políticas owner + admin.
| 20260625000019 | `20260625000019_usuario_insignias_update_asignaturas_rls.sql` | 25-06-2026 | UPDATE policy en `usuario_insignias` + RLS en `asignaturas`.
| 20260626000020 | `20260626000020_valor_met_ejercicios.sql` | 26-06-2026 | Columna `valor_met` en `ejercicios` (MET Compendio Adultos 2024) + recrea `v_ejercicios_completos`.
| 20260626000021 | `20260626000021_duracion_real.sql` | 26-06-2026 | RENAME `duracion_segundos` → `duracion_objetivo_segundos` + ADD `duracion_real_segundos` en `seleccion_de_ejercicios`.
| 20260628000022 | `20260628000022_materiales_estudio.sql` | 28-06-2026 | **Sistema SM-2 Fase 1:** Tabla `materiales_estudio` (wrapper de apuntes+archivos con 9 columnas SM-2: estado_dominio, intervalo, facilidad, repasos). Amplía CHECKs de `tipo_actividad` en `horarios_academicos` para `'repaso'` y de `tipo`/`fuente_tipo` en `documentos_ia` para `'practica'`. RLS dueño + admin.
| 20260628000023 | `20260628000023_bancos_preguntas.sql` | 28-06-2026 | **Sistema SM-2 Fase 2:** Tablas `bancos_preguntas` (cabecera de test IA), `preguntas` (opcion_multiple/rellenar_hueco con JSONB opciones) y `intentos_pregunta` (historial de respuestas). RLS: dueño gestiona bancos + intentos; preguntas visibles vía JOIN con banco del dueño.
| 20260628000024 | `20260628000024_fix_rls_preguntas.sql` | 28-06-2026 | **Sistema SM-2 Fase 3:** Extiende política RLS de `preguntas` de SELECT a FOR ALL (necesario para INSERT de preguntas generadas por IA). Añade políticas admin SELECT en `preguntas` e `intentos_pregunta`.
| 20260628000025 | `20260628000025_test_sessions.sql` | 28-06-2026 | **Sistema SM-2 Fase 4:** Tabla `test_sessions` para sesiones de práctica persistentes con subconjunto JSONB del banco de preguntas, respuestas, resultados, índice y status (`in_progress`/`completed`/`abandoned`). RLS dueño + admin.
| 20260629000026 | `20260629000026_horarios_metadata.sql` | 29-06-2026 | **Metadatos de timeline:** Columnas `is_private BOOLEAN NOT NULL DEFAULT false` (visibilidad solo dueño) y `tipo_clase VARCHAR` (`'teoria'`/`'practica'`) en `horarios_academicos`. Soportan el enum `ClassType` en `TimelineItem`.

> **Nota histórica:** Las migraciones intermedias 0001–0048 fueron consolidadas en `202606060049_esquema_base.sql` durante la Fase 3. Las migraciones 0050 anteriores (0050–0052 de xp_estudio_flag, retos_racha, etc.) también fueron absorbidas. El orden de aplicación real es cronológico por timestamp del nombre del archivo, no por el número de secuencia en el nombre.

## 3. Servicio de IA — `RecomendacionIaService`

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart` (~1357 líneas)

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
- `historialEjercicio`: Lista de `EjercicioRecienteDto` (peso promedio, reps promedio, RPE, fecha) de sesiones previas
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

## 12. Servicio de IA para Time-Blocking — `TimeBlockIaService`

**Archivo:** `app/lib/features/academico/infrastructure/timeblock_ia_service.dart`
**Modelo:** Gemini Flash (`gemini-flash-latest`) — mismo endpoint y autenticación que `RecomendacionIaService`
**Timeout:** 20 segundos (respuesta más larga por la complejidad del scheduling)

### 12.1 Propósito

Generar una distribución semanal óptima de bloques de estudio, deporte y preparación de entregas, respetando los horarios fijos del usuario (clases, compromisos) y aplicando 10 reglas de time-blocking académico.

### 12.2 Datos de Entrada

```dart
Future<TimeblockIaResult> generarPlanSemanal({
  required String apiKey,
  required InboxConfig inbox,               // Horas estudio, días deporte, entregas
  required List<HorarioAcademicoDb> horariosFijos,  // Clases y compromisos (es_fijo=true)
  required PerfilBienestarDb? perfil,       // Para duración de sesiones de deporte
})
```

| Dato | Origen | Uso |
|------|--------|-----|
| `inbox.horasEstudioSemana` | Slider (5-40h) | Volumen total de estudio a distribuir |
| `inbox.diasDeporteSemana` | Slider (1-6 días) | Cantidad y frecuencia de bloques de entrenamiento |
| `inbox.entregasProximas` | `entregas_examenes` (próximos 14 días) | La IA crea bloques de preparación 2-3 días antes de cada entrega |
| `horariosFijos` | `horarios_academicos WHERE es_fijo=true` | Huecos ocupados que la IA NO puede usar |
| `perfil.minutosPorSesion` | `perfil_bienestar_usuario` | Duración de cada bloque de deporte |

### 12.3 Reglas de Time-Blocking (N1-N10)

La IA recibe estas 10 reglas inyectadas en el prompt como restricciones obligatorias:

| # | Regla | Descripción |
|---|-------|-------------|
| **N1** | No solapar con fijos | Ningún bloque generado puede solaparse con `horariosFijos` |
| **N2** | Pausa comida 12:00-14:00 | Reservar 2h centrales para descanso/comida. No generar bloques en esa franja |
| **N3** | Máximo 2h continuas de estudio | Ningún bloque de estudio >120 min. Si se necesitan más horas, crear bloques separados con ≥15 min de pausa |
| **N4** | Deporte no trasnochador | No programar deporte después de las 21:00 (afecta al sueño) |
| **N5** | Buffer pre-entrega | Para cada entrega en ≤3 días, reservar 2 bloques de 60 min en los 2 días previos |
| **N6** | Buffer pre-examen | Para cada examen en ≤5 días, reservar bloques diarios de 90 min |
| **N7** | Distribución balanceada | Las horas de estudio se reparten equitativamente entre días hábiles. Máximo 2:1 de ratio entre el día más cargado y el menos cargado |
| **N8** | Alternancia estudio/deporte | No colocar bloques de deporte inmediatamente después de estudio (>30 min de separación). Idealmente en franjas opuestas del día |
| **N9** | Respetar preferencia horaria | Usuario puede indicar preferencia "mañana" (estudio 7-12), "tarde" (14-19) o "noche" (19-23). La IA prioriza la franja elegida |
| **N10** | Mínimo 1 día libre | Si el usuario estudia 5+ días, dejar al menos 1 día (generalmente sábado o domingo) sin bloques de estudio |

### 12.4 Prompt Engineering

```dart
String _buildPrompt(InboxConfig inbox, List<HorarioAcademicoDb> fijos) {
  return '''
Eres un planificador académico profesional. Genera UN plan semanal de time-blocking.

## RESTRICCIONES OBLIGATORIAS:
${_formatearReglasN1N10()}

## HORARIOS FIJOS (NO MODIFICAR):
${_formatearHorariosFijos(fijos)}

## INTENCIONES DEL USUARIO:
- Horas totales de estudio: ${inbox.horasEstudioSemana}h
- Días de deporte: ${inbox.diasDeporteSemana}
- Duración por sesión deportiva: ${perfil?.minutosPorSesion ?? 60} min
- Entregas próximas: ${_formatearEntregas(inbox.entregasProximas)}
- Preferencia horaria: ${inbox.preferenciaHoraria}

## FORMATO JSON DE RESPUESTA:
{
  "nombrePlan": "Semana del X al Y",
  "bloques": [
    {
      "diaSemana": 1,
      "horaInicio": "09:00",
      "duracionMinutos": 90,
      "tipo": "estudio",
      "asignatura": "Cálculo I",
      "notas": "Preparar entrega del viernes"
    }
  ],
  "metricas": {
    "horasEstudioTotal": 20,
    "horasDeporteTotal": 4,
    "diasConBloques": 5,
    "ratioBalance": 1.3
  }
}

Responde ÚNICAMENTE con el JSON. Sin Markdown.
''';
}
```

### 12.5 Validación Post-IA

Tras recibir la respuesta de Gemini, `_validarPlan()` verifica:

| Validación | Acción si falla |
|------------|----------------|
| No solapamiento con fijos | Elimina el bloque conflictivo |
| Suma de horas ≈ inbox.horasEstudio (±15%) | Ajusta duraciones proporcionalmente |
| Regla N3 (máx 120 min) | Divide bloques >120 min en 2 |
| Cada bloque tiene `diaSemana` 1-7 | Descarta bloques con día inválido |
| `horaInicio` entre 7:00-23:00 | Descarta bloques fuera de rango |

Si quedan <3 bloques válidos tras la validación, se retorna fallback determinista (distribución equitativa simple sin IA).

### 12.6 Fallback Determinista

Cuando `GEMINI_API_KEY` no está configurada o Gemini falla, `_generarFallback()`:

1. Calcula horas de estudio por día = `horasEstudioSemana / díasHábiles`
2. Distribuye en bloques de 60-90 min entre 9:00-12:00 y 15:00-19:00
3. Respeta horarios fijos (recorta o desplaza bloques)
4. Los bloques de deporte se asignan a última hora de la tarde (18:00-20:00)
5. Las entregas generan bloques de preparación 2 días antes

### 12.7 Métricas de Rendimiento

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| Latencia Gemini | <6s | `Stopwatch` en `_callGemini()` |
| Tasa de éxito de parsing | >95% | Contador de `FormatException` vs éxitos |
| Tasa de validación post-IA | >90% bloques válidos | `bloquesValidos / bloquesGenerados` |
| Uso de fallback | <10% | Cuando no hay API key o Gemini falla |

---

## 13. Cloudflare Worker — Proxy R2

**Archivos:**
- `cloudflare/synaptixfit-r2-proxy/worker.js` — código fuente del Worker (217 líneas)
- `cloudflare/synaptixfit-r2-proxy/wrangler.jsonc` — configuración de despliegue Wrangler CLI

### 13.1 Propósito

Servir como proxy unificado para operaciones de lectura, escritura y borrado sobre el bucket Cloudflare R2 `synaptixfit-r2`. El Worker gestiona CORS, caché CDN y verificación de configuración.

### 13.2 Configuración de despliegue (`wrangler.jsonc`)

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/cloudflare/workers-sdk/main/packages/wrangler/config-schema.json",
  "name": "synaptixfit-r2-proxy",
  "main": "worker.js",
  "compatibility_date": "2025-06-23",
  "r2_buckets": [
    {
      "binding": "R2_BUCKET",
      "bucket_name": "synaptixfit-r2"
    }
  ],
  "observability": {
    "enabled": true
  }
}
```

**Campos clave:**
- `r2_buckets[0].binding`: Nombre de la variable disponible en `env.R2_BUCKET` dentro del Worker.
- `r2_buckets[0].bucket_name`: Nombre real del bucket R2 en Cloudflare Dashboard.
- `observability.enabled`: Activa logs y métricas en Cloudflare Dashboard.

### 13.3 Despliegue

Hay dos métodos para desplegar el Worker:

**Opción recomendada — Wrangler CLI:**
```bash
npm i -g wrangler               # Instalar Wrangler
npx wrangler login              # Autenticarse en Cloudflare
# Ajustar "bucket_name" en wrangler.jsonc al bucket real
npx wrangler deploy             # Desplegar con configuración del archivo
```

**Alternativa — Cloudflare Dashboard:**
1. Ir a Workers & Pages → `synaptixfit-r2-proxy` → Edit Code
2. Settings → Bindings → Add R2 Bucket Binding:
   - Variable name: `R2_BUCKET`
   - R2 Bucket: `synaptixfit-r2` (o el nombre real del bucket)
3. Pegar el código de `worker.js` y hacer Deploy
4. Copiar la URL del Worker (`.workers.dev`) al `.env` de la app Flutter

### 13.4 Guarda de verificación del binding R2_BUCKET

**Problema original (resuelto):** Si el binding `R2_BUCKET` no estaba configurado en Cloudflare Dashboard (ni vía `wrangler.jsonc`), el código del Worker hacía `env.R2_BUCKET.put(...)` pero `env.R2_BUCKET` era `undefined`, causando el error opaco: `Cannot read properties of undefined (reading 'put')`.

**Solución implementada:** Guarda justo después del bloque OPTIONS y antes del bloque `try` principal:

```javascript
// Guarda: verificar que el binding R2_BUCKET existe antes de usarlo
if (!env.R2_BUCKET) {
  console.error('[synaptixfit-r2-proxy] Binding R2_BUCKET no configurado en este Worker.');
  return new Response(JSON.stringify({
    error: 'Configuración incompleta del servidor',
    message: 'El binding R2_BUCKET no está configurado. Agrega el binding en Cloudflare Dashboard → Workers & Pages → synaptixfit-r2-proxy → Settings → Bindings, o despliega con `npx wrangler deploy` usando wrangler.jsonc.',
  }), {
    status: 503,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
```

**Mejora:** Reemplaza el error 500 genérico `Cannot read properties of undefined` por un **error 503 Service Unavailable** con un mensaje descriptivo que indica exactamente qué falta configurar y cómo solucionarlo (Dashboard vs Wrangler CLI).

### 13.5 Métodos HTTP soportados

| Método | Ruta | Propósito | Headers de respuesta |
|--------|------|-----------|---------------------|
| `GET` | `/{objectKey}` | Descargar objeto de R2 | `Content-Type` (del metadata), `Content-Length`, `Cache-Control: public, max-age=31536000, immutable`, `ETag` |
| `PUT` | `/{objectKey}` | Subir objeto a R2 | `{ success: true, key, url }` (JSON) |
| `DELETE` | `/{objectKey}` | Eliminar objeto de R2 | `{ success: true, message, key }` (JSON) |
| `OPTIONS` | `/*` | Preflight CORS | 204 No Content con headers CORS |
| `POST` | `/_proxy/ics` | Proxy ICS (CORS abierto) | Texto del calendario descargado |

### 13.6 CORS

- **Rutas R2 (`/*`):** CORS restringido. Orígenes permitidos: `synaptixfit.com` (producción) + `localhost:*` (desarrollo). Fallback al primer origen de la lista.
- **Ruta ICS (`/_proxy/ics`):** CORS abierto (`Access-Control-Allow-Origin: *`). Necesario porque la app descarga calendarios `.ics` de orígenes externos (universidades) y los reproduce vía el Worker para evitar bloqueos CORS del navegador.

### 13.7 Convención de claves de objeto

Las subidas desde la app Flutter usan la siguiente estructura jerárquica:

```
usuarios/{user_id}/asignaturas/{asignatura_id}/archivos/{timestamp}_{nombre_archivo}
```

Ejemplo: `usuarios/d4e5f6a7/asignaturas/b8c9d0e1/archivos/1719000000_apuntes_calculo.pdf`

Esta convención permite:
- Aislamiento por usuario (prefijo `usuarios/{user_id}`)
- Organización por asignatura (`asignaturas/{asignatura_id}`)
- Prevención de colisiones de nombres (timestamp Unix en segundos)
- Fácil enumeración y limpieza por prefijo

### 13.8 Flujo de subida desde Flutter

1. **UI:** `AsignaturaDetalleScreen` → botón "Subir archivo" → `file_picker` con `withData: true`
2. **Repositorio:** `ArchivosAsignaturaRepository.subirArchivo(asignaturaId, bytes, nombre, tipoMime)`
3. **Clave R2:** Construye `usuarios/{userId}/asignaturas/{asignaturaId}/archivos/{timestamp}_{nombre}`
4. **URL:** `{VITE_R2_WORKER_URL}/{objectKey}` (desde `app/.env`)
5. **HTTP PUT:** `Dio.put(url, data: bytes, options: Options(headers: {'Content-Type': tipoMime}))` con callback `onSendProgress`
6. **Worker:** Recibe PUT, extrae `key` del pathname, ejecuta `env.R2_BUCKET.put(key, body, { httpMetadata: { contentType } })`
7. **Respuesta Worker:** `{ success: true, key: "...", url: "..." }`
8. **Supabase:** Inserta metadatos en `archivos_asignatura`:
   - `asignatura_id`, `usuario_id`, `nombre_original`, `cloudflare_object_key`
   - `url_publica_o_firmada`, `tamano_bytes`, `tipo_mime`
9. **Rollback:** Si falla la inserción en Supabase, se intenta `DELETE` al Worker para borrar el objeto ya subido a R2 (best-effort, sin garantía transaccional)
10. **URL pública:** Se construye usando `CLOUDFLARE_R2_BASE_URL` (si existe en `.env`) o la URL base del Worker como fallback

### 13.9 Tabla `archivos_asignatura` (migración 20260622000013)

```sql
CREATE TABLE archivos_asignatura (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asignatura_id UUID NOT NULL REFERENCES asignaturas(id) ON DELETE CASCADE,
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  nombre_original TEXT NOT NULL,
  cloudflare_object_key TEXT NOT NULL,
  url_publica_o_firmada TEXT,
  tamano_bytes BIGINT,
  tipo_mime TEXT,
  subido_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: solo dueño y admin
ALTER TABLE archivos_asignatura ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Dueño CRUD" ON archivos_asignatura
  FOR ALL USING (auth.uid() = usuario_id);
CREATE POLICY "Admin lectura" ON archivos_asignatura
  FOR SELECT USING (es_admin());

CREATE INDEX idx_archivos_asignatura ON archivos_asignatura(asignatura_id, subido_en DESC);
```

---

## 14. Algoritmo SM-2 — Repaso Espaciado

**Archivo:** `app/lib/features/academico/infrastructure/sm2_calculator.dart` (75 líneas)

### 14.1 Propósito

Implementar el algoritmo SuperMemo 2 (SM-2) para programar repasos espaciados de materiales de estudio. El algoritmo calcula el intervalo óptimo hasta el próximo repaso basándose en la calidad de la respuesta del usuario, maximizando la retención a largo plazo.

### 14.2 Parámetros del Algoritmo

| Parámetro | Variable | Inicial | Rango | Descripción |
|-----------|----------|---------|-------|-------------|
| Calidad | `q` | — | 0–2 | 0 = "Toca repasar", 1 = "Me cuesta", 2 = "Dominio absoluto" |
| Facilidad | `EF` | 2.5 | [1.3, 2.5] | Factor de facilidad del material (más alto = más fácil de recordar) |
| Intervalo | `I` | variable | ≥1 | Días hasta el próximo repaso |
| Repasos OK | `n` | variable | ≥0 | Repasos correctos consecutivos |

### 14.3 Fórmulas

**Cálculo del nuevo intervalo (I'):**

```
Si calidad < 2:  I' = 1  (reset)
Si calidad = 2:
  n=0 → I' = 1
  n=1 → I' = 3
  n=2 → I' = 7
  n≥3 → I' = ceil(I × EF)
```

**Cálculo de la nueva facilidad (EF'):**

```
EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))
```

Donde `q` es la calidad original (0, 1 o 2) y `5-q` es la "dificultad" invertida (3, 4 o 5). La fórmula estándar de SM-2 usa calidad 0-5, pero SynaptixFit la adapta a 3 niveles (0, 1, 2) mapeando internamente: calidad 0→q=0, calidad 1→q=3, calidad 2→q=5.

**Clampeo de EF:**
```
Si EF' > 2.5 → EF' = 2.5
Si EF' < 1.3 → EF' = 1.3
```

### 14.4 Estados de Dominio

| Estado | Condición | Significado |
|--------|-----------|-------------|
| `sin_evaluar` | Nunca se ha practicado | Material nuevo, pendiente de primer repaso |
| `necesita_repaso` | calidad = 0 | El usuario no recuerda el material; reiniciar desde I=1 |
| `en_progreso` | calidad = 1 o n < 3 | El usuario está aprendiendo; intervalos cortos |
| `dominado` | n ≥ 3 con calidad = 2 | Material consolidado; intervalos largos |
| `abandonado` | Manual | El usuario decide no seguir repasando este material |

### 14.5 Clase `Sm2Calculator`

```dart
class Sm2Calculator {
  static const _facilidadInicial = 2.5;
  static const _facilidadMinima = 1.3;

  static Sm2Resultado calcular({
    required int calidad,             // 0, 1 o 2
    required int intervaloActualDias,
    required double facilidad,
    required int repasosCompletados,
  }) { ... }
}
```

**DTO `Sm2Resultado`:**
```dart
class Sm2Resultado {
  final int intervaloDias;         // Días hasta el próximo repaso
  final double facilidad;          // Nueva facilidad
  final int repasosCompletados;    // Nuevo conteo de repasos OK
  final String estadoDominio;      // Nuevo estado de dominio
}
```

### 14.6 Integración con la Práctica

El flujo de práctica (en `PracticaScreen`) sigue estos pasos:

1. **Carga:** `bancoPreguntasProvider(materialId)` obtiene/crea banco y preguntas.
2. **Preguntas secuenciales:** El usuario responde cada pregunta (opción múltiple o rellenar hueco). Cada respuesta se registra en `intentos_pregunta`.
3. **Autoevaluación SM-2:** Al finalizar todas las preguntas, se muestra un modal con 3 botones de calidad:
   - "Toca repasar" (rojo) → calidad 0, estado `necesita_repaso`, I=1
   - "Me cuesta" (naranja) → calidad 1, estado `en_progreso`, I=1
   - "Dominio absoluto" (verde) → calidad 2, aplica algoritmo SM-2 completo
4. **Actualización SM-2:** `MaterialesEstudioRepository.actualizarEstadoSm2()` persiste el nuevo estado en `materiales_estudio`.
5. **Inyección en timeline:** Si el material pasa a `necesita_repaso` o `en_progreso` con `siguiente_repaso_en` en ≤7 días, se inserta un bloque de `tipo_actividad='repaso'` en `horarios_academicos` con `es_fijo=false`.
6. **XP de práctica:** `PracticaRepository.otorgarXpSiProcede()` otorga XP la primera vez que se completa un banco (flag `xp_otorgado`), evitando farmeo.

---

**Documento compilado:** 29-06-2026
**Última revisión:** v3.5 — Migraciones 53 (añadidas 0025 `test_sessions` + 0026 `horarios_metadata` con columnas `is_private` y `tipo_clase`), enum `ClassType` en DTO `TimelineItem`.
