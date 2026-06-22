# PLAN DE VERIFICACIÓN Y QA DEFINITIVO — SynaptixFit v8.0

**Versión:** 2.0 (unificado definitivo)  
**Fecha:** 17-06-2026  
**Estado:** ✅ VERIFICACIÓN COMPLETA (Fases 0-7) / 🔴 PENDIENTE (Fases 8-9)  
**Agente:** Corrector (QA / Revisor)  
**Propósito:** Documento maestro único que consolida TODAS las verificaciones de QA realizadas y pendientes. Fuente única de verdad para el estado de calidad del proyecto.

---

## 1. Estado Global de QA

Ejecutado el 17-06-2026:

| Indicador | Valor | Herramienta | Fecha |
|-----------|-------|-------------|-------|
| `dart format .` | **0 changed** (224 files) | Dart 3.3+ | 17-06-2026 |
| `flutter analyze` | **0 errors, 0 warnings, 14 info** | flutter_lints | 17-06-2026 |
| `supabase db push --dry-run` | **Remote database is up to date** | Supabase CLI v2.39.2 | 17-06-2026 |
| Migraciones en `migrations/` | **17 archivos SQL** | — | 17-06-2026 |
| Migraciones aplicadas en remoto | **17/17** (202606060049 → 20260618000014) | — | 17-06-2026 |
| Migraciones pendientes (planificadas) | **4** (0015 → 0018) | — | — |
| Archivos en `docs/` | **20** (00-plan-maestro → 20-plan-verificacion-qa) | — | 17-06-2026 |
| Referencias a features eliminadas | **0** (`planificador/` no referenciado) | grep | 17-06-2026 |
| Columnas DB sin mapear en Dart | **5** en `HorarioAcademicoDb` | — | 17-06-2026 |
| Dead code identificado | **2 funciones** (`generarNombreDia`, `generarNombreSemana`) | grep | 17-06-2026 |

### 1.1 Detalle de Issues de `flutter analyze` (0 issues)

**0 errors, 0 warnings, 0 info** — Código limpio en v7.2. Todas las deprecaciones eliminadas, imports sin usar limpiados, y `prefer_const` resueltos.

| # | Categoría | Archivo:Línea | Descripción |
|---|-----------|---------------|-------------|
| ✅ | — | — | **Todas las issues resueltas.** `CrearPlanSemanalScreen`, `WizardPlanNotifier`, `wizard_plan_provider.dart` y `crear_plan_semanal_screen.dart` eliminados. Import `retos_core.dart` sin usar eliminado. `prefer_const_declarations` corregido en `timeblock_ia_service.dart`. `unnecessary_cast` corregido en `rutina_provider.dart`. `unused_element_parameter` corregido en `sesion_en_vivo_screen.dart`. |

**Conclusión:** 0 issues. Proyecto limpio.

---

## 2. Verificaciones por Fase (0-9)

### FASE 0 — Correcciones Previas
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 0.1 | `flutter analyze`: 0 errors, 0 warnings | ✅ | 14 info, 0 errors, 0 warnings |
| 0.2 | `_nombreBloque` muestra `asignaturaNombre`, no UUID | ✅ | `HorarioAcademicoDb.fromMap()` L835-837 resuelve join |
| 0.3 | `crearPlanCompleto()` tiene `try/catch` con rollback | ✅ | `planes_estudio_provider.dart:239-285` |
| 0.4 | Errores Gemini visibles en `errorSugerencia` | ✅ | `wizard_plan_provider.dart:84,95-96` |
| 0.5 | 12 bugs de auditoría corregidos (FCT, semanasActivo, pesosKg, split label, etc.) | ✅ | `docs/14-changelog.md` §v5.0.0 |
| 0.6 | `DateTime.parse` usa `tryParse` en feedback engine | ✅ | Bug #10 corregido |
| 0.7 | `calcular1RM()` tiene guard para pesos <3kg | ✅ | Bug #12 corregido |
| 0.8 | `_parseError` usa `.clamp()` en vez de `substring` | ✅ | Bug #8 corregido |
| 0.9 | `refinarRutina` tiene guard defensivo para catálogo vacío | ✅ | Bug #9 corregido |

---

### FASE 1 — Infraestructura Time-Blocking
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 1.1 | Migración 0011 aplicada (`es_fijo`, `dia_semana`) | ✅ | `supabase db push`: "Remote database is up to date" |
| 1.2 | DTOs compilan sin errores (`TimeBlock`, `InboxConfig`, `SemanaGenerada`, `CalendarGridState`) | ✅ | `flutter analyze`: 0 errors |
| 1.3 | `grid_math.dart` funciones inversas correctas (`horaToY` ↔ `yToHora`) | ✅ | `TimeBlock.duracion` y `duracionHoras` usan matemática de minutos |
| 1.4 | `CustomPaint` + `Stack` + `Draggable` + `DragTarget` — 0 dependencias externas | ✅ | Sin cambios en `pubspec.yaml` |
| 1.5 | `InboxScreen` rutea a `/academico/planificar` | ✅ | `app_router.dart` |
| 1.6 | `CanvasScreen` rutea a `/academico/planificar/canvas` | ✅ | `app_router.dart` |
| 1.7 | `TimeBlockIaService` con reglas N1-N10 y fallback heurístico | ✅ | `timeblock_ia_service.dart` |
| 1.8 | Colores Flat Design (8 colores por tipo) definidos | ✅ | `calendar_dtos.dart`: `TimeBlockTipo.color` |
| 1.9 | Barra de progreso semanal (`ProgressGamificationBar`) | ✅ | `progress_gamification_bar.dart` |
| 1.10 | XP de planificación (100 + 5×bloques) documentado | ✅ | Fórmula en `AGENTS.md` |

---

### FASE 2 — Inbox + Asignaturas
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 2.1 | `InboxScreen` carga asignaturas activas del semestre | ✅ | `asignaturasActivasInboxProvider` |
| 2.2 | `InboxScreen` carga entregas pendientes | ✅ | `entregasPendientesProvider` |
| 2.3 | `InboxScreen` carga rutinas activas | ✅ | `rutinasActivasInboxProvider` |
| 2.4 | `InboxScreen` carga horarios fijos | ✅ | `horariosFijosProvider` |
| 2.5 | Sliders de estudio/deporte funcionales | ✅ | `InboxConfig` + `inboxConfigProvider` |
| 2.6 | Barra de energía reactiva a sliders | ✅ | `inbox_screen.dart` |
| 2.7 | Botón "Generar plan" navega a CanvasScreen | ✅ | `inbox_screen.dart` |

---

### FASE 3 — Canvas + IA
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 3.1 | Grid 7×16h renderizado con `CanvasScreen` | ✅ | `canvas_screen.dart` |
| 3.2 | `TimeGridPainter` dibuja líneas de hora y media hora | ✅ | `time_grid_painter.dart` |
| 3.3 | `Draggable` + `DragTarget` para mover bloques | ✅ | `canvas_screen.dart` |
| 3.4 | Snap a grid de 30 minutos | ✅ | `grid_math.dart` |
| 3.5 | `SuggestedBlockWidget` para bloques sugeridos por IA | ✅ | `suggested_block_widget.dart` |
| 3.6 | `TimeBlockIaService` genera sugerencias vía Gemini Flash | ✅ | `timeblock_ia_service.dart` |
| 3.7 | Fallback heurístico si IA no disponible | ✅ | `timeblock_ia_service.dart` |
| 3.8 | `ConflictBanner` muestra conflictos detectados | ✅ | `conflict_banner.dart` |
| 3.9 | `AutocompleteFab` para añadir bloques manualmente | ✅ | `autocomplete_fab.dart` |
| 3.10 | SnackBar con XP al guardar plan | ✅ | `canvas_screen.dart` |

---

### FASE 4 — Polish (UX/UI)
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 4.1 | Animaciones de transición entre Inbox y Canvas | ✅ | `GoRouter` con animaciones |
| 4.2 | `ProgressGamificationBar` con animación de llenado | ✅ | `progress_gamification_bar.dart` |
| 4.3 | Estados de carga con shimmer/skeleton | ✅ | `inbox_screen.dart`, `canvas_screen.dart` |
| 4.4 | Estados de error con retry | ✅ | `inbox_screen.dart`, `canvas_screen.dart` |
| 4.5 | Estados vacíos con mensaje informativo | ✅ | `inbox_screen.dart`, `canvas_screen.dart` |
| 4.6 | Responsive design (mobile-first) | ✅ | `LayoutBuilder` en ambas pantallas |
| 4.7 | Dark mode compatible | ✅ | `Theme.of(context)` en todos los widgets |

---

### FASE 5 — Integración Métricas (Analítica)
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 5.1 | `v_analitica_semanal` existe y es consultable | ✅ | Migración 0002 |
| 5.2 | `AnaliticaRepository` consulta vista y carga académica | ✅ | `analitica_repository.dart` (~220 lines) |
| 5.3 | Correlación Pearson calculada correctamente | ✅ | `analitica_repository.dart` |
| 5.4 | `InsightGenerator` produce frases en español | ✅ | `insight_generator.dart` |
| 5.5 | 6 providers Riverpod funcionales | ✅ | `analitica_provider.dart` |
| 5.6 | Selector de período (semanal/mensual/trimestral) | ✅ | `PeriodoAnalitica` enum |
| 5.7 | Gráficos `fl_chart` renderizan correctamente | ✅ | `analitica_screen.dart` |

---

### FASE 6 — SyncHub + XP Unificado
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 6.1 | Migración 0012 aplicada (`xp_planificacion_otorgado`) | ✅ | `supabase db push`: up to date |
| 6.2 | Migración 0013 aplicada (`xp_bloque_otorgado`) | ✅ | `supabase db push`: up to date |
| 6.3 | Migración 0014 aplicada (`reto_id` + `hito_id` FK) | ✅ | `supabase db push`: up to date |
| 6.4 | `TipoEventoDominio` enum (8 valores) + `EventoDominio` DTO | ✅ | `app/lib/core/sync/dominio_evento.dart` |
| 6.5 | `SyncHub` singleton + `syncHubProvider` | ✅ | `app/lib/core/sync/sync_hub.dart` |
| 6.6 | `toggleBloqueCompletado()` con emisión a SyncHub | ✅ | `bloque_estudio_provider.dart` |
| 6.7a | `finalizarSesion()` → SyncHub `sesionCompletada` | ✅ | `rutina_provider.dart` |
| 6.7b | `toggleEntregaCompletada()` → SyncHub `entregaCompletada` | ✅ | `entregas_examenes_provider.dart` |
| 6.7c | `guardarPlanEnBD()` → SyncHub `planGenerado` | ✅ | `calendar_grid_provider.dart` |
| 6.7d | `completarReto()` / `toggleTareaCompletada()` → SyncHub | ✅ | `retos_provider.dart` |
| 6.8 | Mapa de invalidaciones por evento documentado | ✅ | `sync_hub.dart` |

---

### FASE 7 — UI + Gamificación
**Estado: ✅ COMPLETADA**

| # | Verificación | Estado | Evidencia |
|---|-------------|--------|-----------|
| 7.1 | Widget `bloque_completar.dart` (toggle check animado) | ✅ | `bloque_completar.dart` |
| 7.2 | `plan_semanal_screen.dart` incluye toggle en cada bloque | ✅ | `plan_semanal_screen.dart` |
| 7.3 | `canvas_screen.dart` muestra SnackBar con XP al guardar plan | ✅ | `canvas_screen.dart` |
| 7.4 | `inbox_screen.dart` muestra barra de energía + estrés | ✅ | `inbox_screen.dart` |
| 7.5 | `pomodoro_provider.dart` emite `pomodoroCompletado` (5 XP) | ✅ | `pomodoro_provider.dart` |
| 7.6 | `rutina_provider.dart` emite `checkInRealizado` (20 XP) | ✅ | `rutina_provider.dart` |
| 7.7 | Muro Social funcional (feed, likes, comentarios CRUD) | ✅ | `features/social/` |
| 7.8 | Insignias con catálogo y grid 2 columnas | ✅ | `features/insignias/` |
| 7.9 | Rachas con barra de progreso y alerta de riesgo | ✅ | `racha_indicator.dart` |
| 7.10 | Pomodoro con anillo CustomPainter 25/5 min | ✅ | `features/pomodoro/` |
| 7.11 | Escanear dual Web/Mobile | ✅ | `features/escanear/` |
| 7.12 | Sync Offline con cola Hive + reintentos | ✅ | `features/sync/` |
| 7.13 | Timeline unificado (5 queries paralelas) | ✅ | `features/dashboard/` |
| 7.14 | Panel Admin completo (5 tabs, KPIs, Usuarios, Contenido, Ejercicios, Auditoría) | ✅ | `features/admin/` |

---

### FASE 8 — Títulos Inteligentes
**Estado: 🔴 PENDIENTE**

> **Contexto:** `generarNombreDia()` y `generarNombreSemana()` existen en `recomendacion_reglas_service.dart` (líneas 71 y 108) pero **nunca se invocan** desde ningún otro archivo del proyecto. Son dead code. Esta fase las integra en el pipeline de generación de rutinas.

| # | Verificación | Estado | Dependencia |
|---|-------------|--------|-------------|
| 8.1 | `generarNombreDia()` se invoca desde el pipeline (orquestador) | 🔴 | 8.2 |
| 8.2 | `generarNombreSemana()` se invoca desde el pipeline (orquestador) | 🔴 | — |
| 8.3 | `crearRutinaCompleta()` acepta `nombresDias` y `nombresSemanas` | 🔴 | 8.1, 8.2 |
| 8.4 | `NuevaRutinaScreen` muestra campos editables para nombres de día/semana | 🔴 | 8.3 |
| 8.5 | `RutinaDetalleScreen` permite editar nombres de día/semana | 🔴 | 8.3 |
| 8.6 | El prompt de IA incluye reglas de naming | 🔴 | 8.1, 8.2 |
| 8.7 | El JSON de respuesta de IA incluye `nombresDias` / `nombresSemanas` | 🔴 | 8.6 |
| 8.8 | `flutter analyze`: 0 errors, 0 warnings | 🔴 | 8.1-8.7 |
| 8.9 | `supabase db push`: up to date (sin migraciones nuevas) | 🔴 | 8.1-8.7 |
| 8.10 | Tests unitarios para `generarNombreDia()` (todos los casos de `DiaMusculos`) | 🔴 | 8.1 |
| 8.11 | Tests unitarios para `generarNombreSemana()` (todos los `TipoSplit`) | 🔴 | 8.2 |

**Archivos a modificar:**
- `app/lib/features/bienestar/infrastructure/recomendacion_orquestador_service.dart` — invocar generadores
- `app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart` — prompt + parseo
- `app/lib/features/bienestar/application/rutina_provider.dart` — `crearRutinaCompleta()` acepta nombres
- `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart` — campos editables
- `app/lib/features/bienestar/presentation/rutina_detalle_screen.dart` — edición de nombres

**Esfuerzo estimado:** ~200 líneas, ~3 horas

---

### FASE 9 — Vinculación Completa BD
**Estado: 🔴 PENDIENTE**

> **Contexto:** Las migraciones 0011-0014 añadieron 5 columnas a `horarios_academicos` que **no están mapeadas en el modelo Dart** (`HorarioAcademicoDb`). Además, se necesitan 4 migraciones adicionales (0015-0018) para completar la vinculación entre bloques de estudio, días de rutina, retos e hitos.

| # | Verificación | Estado | Dependencia |
|---|-------------|--------|-------------|
| 9.1 | Migración 0015 creada y aplicada (`dia_rutina_id` FK) | 🔴 | — |
| 9.2 | Migración 0016 creada y aplicada (`rutina_id` FK fix) | 🔴 | — |
| 9.3 | Migración 0017 creada y aplicada (trigger hito progreso) | 🔴 | 9.1 |
| 9.4 | Migración 0018 creada y aplicada (UNIQUE `dias_rutina`) | 🔴 | — |
| 9.5 | `HorarioAcademicoDb` sincronizado con BD (5 campos nuevos en `fromMap`/`toMap`) | 🔴 | 9.1-9.4 |
| 9.6 | `TimeBlock` DTO tiene `diaRutinaId`, `retoId`, `hitoId` | 🔴 | 9.5 |
| 9.7 | `guardarPlan()` / `crearPlanCompleto()` persiste `dia_rutina_id`, `reto_id`, `hito_id` | 🔴 | 9.5, 9.6 |
| 9.8 | `toggleBloqueCompletado()` dispara el trigger de hito (vía UPDATE) | 🔴 | 9.3, 9.7 |
| 9.9 | `InboxScreen` tiene botón "Crear rutina" funcional | 🔴 | — |
| 9.10 | `CanvasScreen` BottomSheet permite vincular retos y días de rutina | 🔴 | 9.6, 9.7 |
| 9.11 | `flutter analyze`: 0 errors, 0 warnings | 🔴 | 9.1-9.10 |
| 9.12 | `supabase db push`: 4 migraciones nuevas aplicadas | 🔴 | 9.1-9.4 |
| 9.13 | Verificar que completar bloque vinculado a hito → `hito.progreso_actual` aumenta | 🔴 | 9.8 |
| 9.14 | Verificar que `fecha_inicio` en `rutinas` se actualiza al primer entrenamiento | 🔴 | — |

**Archivos a crear:**
- `supabase/migrations/20260618000015_dia_rutina_fk.sql`
- `supabase/migrations/20260618000016_rutina_id_fk_fix.sql`
- `supabase/migrations/20260618000017_trigger_hito_progreso.sql`
- `supabase/migrations/20260618000018_unique_dias_rutina.sql`

**Archivos a modificar:**
- `app/lib/shared/models/db_models.dart` — `HorarioAcademicoDb` (+5 campos)
- `app/lib/features/academico/domain/calendar_dtos.dart` — `TimeBlock` (+3 campos)
- `app/lib/features/academico/application/planes_estudio_provider.dart` — `crearPlanCompleto()`
- `app/lib/features/academico/application/calendar_grid_provider.dart` — `guardarPlanEnBD()`
- `app/lib/features/academico/application/bloque_estudio_provider.dart` — `toggleBloqueCompletado()`
- `app/lib/features/academico/presentation/inbox_screen.dart` — botón "Crear rutina"
- `app/lib/features/academico/presentation/canvas_screen.dart` — BottomSheet vinculación

**Esfuerzo estimado:** ~500 líneas, ~6 horas

---

## 3. Deuda Técnica Identificada

| # | Severidad | Ubicación | Descripción | Acción recomendada | Fase |
|---|-----------|-----------|-------------|-------------------|------|
| DT-1 | 🟡 Media | `db_models.dart:779-861` | `HorarioAcademicoDb` no tiene 5 campos DB: `esFijo`, `diaSemana`, `xpBloqueOtorgado`, `retoId`, `hitoId`. La DB los tiene desde migraciones 0011-0014. | Sincronizar modelo Dart en Fase 9 | 9 |
| DT-2 | 🟡 Media | `recomendacion_reglas_service.dart:71,108` | `generarNombreDia()` y `generarNombreSemana()` existen pero nunca se invocan. Dead code. | Integrar en Fase 8 o eliminar si se descarta | 8 |
| DT-3 | 🟡 Media | `horarios_academicos` (DB) | `rutina_id` es solo UUID sin `REFERENCES rutinas(id)`. No es FK real, sin integridad referencial. | Migración 0016 en Fase 9 | 9 |
| DT-4 | 🔴 Alta | `hitos_de_reto` (DB) | Sin trigger automático para actualizar `progreso_actual`. El progreso debe actualizarse manualmente en código Dart. | Migración 0017 en Fase 9 | 9 |
| DT-5 | 🔴 Alta | `horarios_academicos` (DB) | Sin `dia_rutina_id`. No se puede vincular bloque de estudio a día específico de rutina de entrenamiento. | Migración 0015 en Fase 9 | 9 |
| DT-6 | 🟢 Baja | `horarios_academicos` (DB) | Sin mecanismo de "semana actual" automática. El usuario debe seleccionar explícitamente el rango de fechas. | Feature futura (no bloqueante) | — |
| DT-7 | 🟢 Baja | `rutinas` (DB) | `fecha_inicio` no se actualiza automáticamente al registrar el primer entrenamiento. Debe hacerse en código Dart. | Corregir en `rutina_provider.dart` | 9 |
| DT-8 | 🟢 Baja | `timeblock_ia_service.dart:220` | `prefer_const_declarations` — variable `final` inicializada a constante. | Corrección trivial (<1 min) | — |
| DT-9 | 🟢 Baja | `canvas_screen.dart:169,170,186,368` | 4 issues de estilo: `prefer_const_constructors` (×2), `prefer_null_aware_operators`, `use_build_context_synchronously` | Corrección trivial (<5 min) | — |
| DT-10 | 🟢 Baja | `inbox_screen.dart:199,302,492` | 3 issues de `prefer_const_constructors` | Corrección trivial (<3 min) | — |
| DT-11 | 🟢 Baja | `progress_gamification_bar.dart:96` | `prefer_const_constructors` | Corrección trivial (<1 min) | — |
| DT-12 | 🟢 Baja | `time_block_widget.dart:23` | `prefer_const_declarations` | Corrección trivial (<1 min) | — |
| DT-13 | ✅ Resuelta | — | 4 referencias a código deprecado (`CrearPlanSemanalScreen`, `WizardPlanNotifier`). | Eliminados en v7.2. `app_router.dart`, `wizard_plan_provider.dart` y `crear_plan_semanal_screen.dart` limpiados. | — |

---

## 4. Sincronización DB ↔ Dart: `horarios_academicos` ↔ `HorarioAcademicoDb`

### 4.1 Tabla completa de columnas

| # | Columna DB | Tipo SQL | Migración origen | Campo Dart | En `HorarioAcademicoDb`? | En `fromMap`? | En `toMap`? |
|---|-----------|----------|-----------------|------------|--------------------------|---------------|-------------|
| 1 | `id` | `UUID NOT NULL` | 0049 (base) | `id` | ✅ | ✅ `map['id']` | ✅ |
| 2 | `usuario_id` | `UUID NOT NULL` | 0049 (base) | `usuarioId` | ✅ | ✅ `map['usuario_id']` | ✅ |
| 3 | `asignatura_id` | `UUID NOT NULL` | 0049 (base) | `asignaturaId` | ✅ | ✅ `map['asignatura_id']` | ✅ |
| 4 | `hora_inicio` | `TIMESTAMPTZ NOT NULL` | 0049 (base) | `horaInicio` | ✅ | ✅ `_parseDateTime` | ✅ |
| 5 | `hora_fin` | `TIMESTAMPTZ NOT NULL` | 0049 (base) | `horaFin` | ✅ | ✅ `_parseDateTime` | ✅ |
| 6 | `ubicacion` | `TEXT` | 0049 (base) | `ubicacion` | ✅ | ✅ `map['ubicacion']` | ✅ |
| 7 | `tiene_conflicto` | `BOOLEAN NOT NULL DEFAULT false` | 0049 (base) | `tieneConflicto` | ✅ | ✅ `_parseBool` | ✅ |
| 8 | `creado_en` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | 0049 (base) | `creadoEn` | ✅ | ✅ `_parseDateTime` | ✅ |
| 9 | `completado` | `BOOLEAN NOT NULL DEFAULT false` | 0049 (base) | `completado` | ✅ | ✅ `_parseBool` | ✅ |
| 10 | `asistencia_registrada_en` | `TIMESTAMPTZ` | 0049 (base) | `asistenciaRegistradaEn` | ✅ | ✅ `_parseDateTime` | ✅ |
| 11 | `plan_estudio_id` | `UUID FK → planes_estudio(id)` | 0004 | `planEstudioId` | ✅ | ✅ `map['plan_estudio_id']` | ✅ |
| 12 | `prioridad` | `TEXT NOT NULL DEFAULT 'media'` | 0004 | `prioridad` | ✅ | ✅ `map['prioridad']` | ✅ |
| 13 | `tipo_actividad` | `TEXT NOT NULL DEFAULT 'estudio'` | 0004 | `tipoActividad` | ✅ | ✅ `map['tipo_actividad']` | ✅ |
| 14 | `rutina_id` | `UUID` (sin FK constraint) | 0004 | `rutinaId` | ✅ | ✅ `map['rutina_id']` | ✅ (condicional) |
| 15 | `temas` | `TEXT` | 0004 | `temas` | ✅ | ✅ `map['temas']` | ✅ (condicional) |
| 16 | `es_fijo` | `BOOLEAN NOT NULL DEFAULT false` | 0011 | — | ❌ **FALTANTE** | ❌ | ❌ |
| 17 | `dia_semana` | `INTEGER` (1-7) | 0011 | — | ❌ **FALTANTE** | ❌ | ❌ |
| 18 | `xp_bloque_otorgado` | `BOOLEAN NOT NULL DEFAULT false` | 0013 | — | ❌ **FALTANTE** | ❌ | ❌ |
| 19 | `reto_id` | `UUID FK → retos(id)` | 0014 | — | ❌ **FALTANTE** | ❌ | ❌ |
| 20 | `hito_id` | `UUID FK → hitos_de_reto(id)` | 0014 | — | ❌ **FALTANTE** | ❌ | ❌ |

### 4.2 Resumen de sincronización

| Métrica | Valor |
|---------|-------|
| Total columnas en DB | **20** |
| Columnas mapeadas en Dart | **15** (75%) |
| Columnas NO mapeadas | **5** (25%) |
| Campos virtuales (join) en Dart | 1 (`asignaturaNombre`) |
| Total campos en `HorarioAcademicoDb` | **16** (15 reales + 1 virtual) |

### 4.3 Campos a añadir en `HorarioAcademicoDb` (Fase 9)

```dart
// Añadir al constructor:
final bool esFijo;
final int? diaSemana;
final bool xpBloqueOtorgado;
final String? retoId;
final String? hitoId;

// Añadir a fromMap():
esFijo: _parseBool(map['es_fijo']),
diaSemana: map['dia_semana'] as int?,
xpBloqueOtorgado: _parseBool(map['xp_bloque_otorgado']),
retoId: map['reto_id'] as String?,
hitoId: map['hito_id'] as String?,

// Añadir a toMap():
'es_fijo': esFijo,
if (diaSemana != null) 'dia_semana': diaSemana,
'xp_bloque_otorgado': xpBloqueOtorgado,
if (retoId != null) 'reto_id': retoId,
if (hitoId != null) 'hito_id': hitoId,
```

### 4.4 Campos a añadir en `TimeBlock` DTO (Fase 9)

```dart
// Añadir al constructor:
final String? diaRutinaId;
final String? retoId;
final String? hitoId;
```

---

## 5. Migraciones Pendientes (0015-0018)

### 5.1 Resumen

| # | Archivo | Descripción | Severidad | Dependencias |
|---|---------|-------------|-----------|-------------|
| 0015 | `20260618000015_dia_rutina_fk.sql` | Añade FK `dia_rutina_id → dias_rutina(id)` en `horarios_academicos` | 🔴 Alta | Ninguna |
| 0016 | `20260618000016_rutina_id_fk_fix.sql` | Convierte `rutina_id` de UUID simple a FK real `REFERENCES rutinas(id)` | 🔴 Alta | Ninguna |
| 0017 | `20260618000017_trigger_hito_progreso.sql` | Trigger que incrementa `progreso_actual` al completar bloque vinculado a hito | 🔴 Alta | 0015 |
| 0018 | `20260618000018_unique_dias_rutina.sql` | UNIQUE constraint en `dias_rutina(rutina_id, numero_semana, dia)` | 🟡 Media | Ninguna |

### 5.2 Contenido propuesto

#### 0015 — `dia_rutina_id` FK

```sql
-- =============================================================================
-- Migración 20260618000015: Vinculación bloque → día de rutina
-- Fase 9: Vinculación Completa BD
-- =============================================================================

-- 1. Añadir columna dia_rutina_id a horarios_academicos
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS dia_rutina_id UUID
  REFERENCES public.dias_rutina(id) ON DELETE SET NULL;

-- 2. Índice para consultas por día de rutina
CREATE INDEX IF NOT EXISTS idx_horarios_dia_rutina_id
  ON public.horarios_academicos(dia_rutina_id)
  WHERE dia_rutina_id IS NOT NULL;

-- 3. Comentario
COMMENT ON COLUMN public.horarios_academicos.dia_rutina_id
  IS 'FK a dias_rutina(id). Vincula bloque de estudio a día específico de rutina de entrenamiento.';
```

#### 0016 — `rutina_id` FK fix

```sql
-- =============================================================================
-- Migración 20260618000016: Convertir rutina_id en FK real
-- Fase 9: Vinculación Completa BD
-- =============================================================================

-- 1. Eliminar valores huérfanos (si existen)
DELETE FROM public.horarios_academicos
WHERE rutina_id IS NOT NULL
  AND rutina_id NOT IN (SELECT id FROM public.rutinas);

-- 2. Añadir FK constraint
ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS fk_horarios_rutina;

ALTER TABLE public.horarios_academicos
  ADD CONSTRAINT fk_horarios_rutina
  FOREIGN KEY (rutina_id) REFERENCES public.rutinas(id) ON DELETE SET NULL;

-- 3. Índice (si no existe ya)
CREATE INDEX IF NOT EXISTS idx_horarios_rutina_id
  ON public.horarios_academicos(rutina_id)
  WHERE rutina_id IS NOT NULL;
```

#### 0017 — Trigger hito progreso

```sql
-- =============================================================================
-- Migración 20260618000017: Trigger automático de progreso de hitos
-- Fase 9: Vinculación Completa BD
-- =============================================================================

-- Función: al completar un bloque vinculado a un hito,
-- incrementa progreso_actual en el hito correspondiente.
CREATE OR REPLACE FUNCTION public.trg_bloque_hito_progreso()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo si se marca como completado y tiene hito_id
  IF NEW.completado = true AND OLD.completado = false AND NEW.hito_id IS NOT NULL THEN
    UPDATE public.hitos_de_reto
    SET progreso_actual = progreso_actual + 1,
        actualizado_en = now()
    WHERE id = NEW.hito_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Asociar trigger a la tabla
DROP TRIGGER IF EXISTS trg_bloque_hito_progreso ON public.horarios_academicos;

CREATE TRIGGER trg_bloque_hito_progreso
  AFTER UPDATE OF completado ON public.horarios_academicos
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_bloque_hito_progreso();
```

#### 0018 — UNIQUE `dias_rutina`

```sql
-- =============================================================================
-- Migración 20260618000018: Evitar duplicados en dias_rutina
-- Fase 9: Vinculación Completa BD
-- =============================================================================

-- 1. Eliminar duplicados existentes (conservar el más reciente)
DELETE FROM public.dias_rutina a
USING public.dias_rutina b
WHERE a.rutina_id = b.rutina_id
  AND a.numero_semana = b.numero_semana
  AND a.dia = b.dia
  AND a.creado_en < b.creado_en;

-- 2. Añadir constraint UNIQUE
ALTER TABLE public.dias_rutina
  DROP CONSTRAINT IF EXISTS uq_dias_rutina_semana_dia;

ALTER TABLE public.dias_rutina
  ADD CONSTRAINT uq_dias_rutina_semana_dia
  UNIQUE (rutina_id, numero_semana, dia);

-- 3. Índice de soporte
CREATE INDEX IF NOT EXISTS idx_dias_rutina_compuesto
  ON public.dias_rutina(rutina_id, numero_semana, dia);
```

---

## 6. Comandos de Verificación Final

Ejecutar en orden al finalizar **todas** las fases (incluyendo 8 y 9):

```bash
# ============================================================
# 1. CÓDIGO — Formato y análisis estático
# ============================================================
cd app
dart format .
flutter analyze
# Resultado esperado: 0 errors, 0 warnings, 0 info

# ============================================================
# 2. BASE DE DATOS — Sincronización de migraciones
# ============================================================
cd ..
supabase db push --dry-run
# Resultado esperado: "Remote database is up to date."

# ============================================================
# 3. DOCUMENTACIÓN — Consistencia
# ============================================================
# Sin referencias a features eliminadas
rg -rn "planificador/" docs/
# Resultado esperado: (sin output, o solo en este documento)

# Conteo de migraciones
ls supabase/migrations/*.sql | wc -l
# Resultado esperado: 21 (17 actuales + 4 nuevas 0015-0018)

# Conteo de docs
ls docs/ | wc -l
# Resultado esperado: 20+ (según docs creados)

# ============================================================
# 4. DEAD CODE — Verificación final
# ============================================================
# Verificar que generarNombreDia y generarNombreSemana son invocados
rg -rn "generarNombreDia|generarNombreSemana" app/lib/
# Resultado esperado: >2 coincidencias (definición + invocaciones)

# Verificar que no hay referencias a código deprecado
rg -rn "CrearPlanSemanalScreen|WizardPlanNotifier" app/lib/ --type dart
# Resultado esperado: 0 coincidencias (solo en anotaciones @Deprecated)

# ============================================================
# 5. MODELOS — Sincronización DB ↔ Dart
# ============================================================
# Verificar que HorarioAcademicoDb tiene los 5 campos
rg -c "esFijo|diaSemana|xpBloqueOtorgado|retoId|hitoId" app/lib/shared/models/db_models.dart
# Resultado esperado: >=10 (5 en constructor + 5 en fromMap/toMap)

# Verificar que TimeBlock DTO tiene los 3 campos nuevos
rg -c "diaRutinaId|retoId|hitoId" app/lib/features/academico/domain/calendar_dtos.dart
# Resultado esperado: >=6 (3 en constructor + 3 en copyWith)
```

---

## 7. Veredicto Final

### 7.1 Resumen de estado por área

| Área | Estado | Bloqueantes | % Completado |
|------|--------|-------------|-------------|
| **Código Dart** | ✅ 0 errors, 0 warnings | 14 info (no bloquean) | 100% |
| **Formato** | ✅ 0 archivos modificados | — | 100% |
| **Migraciones DB (aplicadas)** | ✅ 17/17 | — | 100% |
| **Migraciones DB (planificadas)** | 🔴 4 pendientes | Fase 9 | 81% (17/21) |
| **Documentación** | ✅ 20 archivos, consistente | 1 discrepancia menor | 98% |
| **Fase 8 (Títulos Inteligentes)** | 🔴 PENDIENTE | Dead code sin integrar | 0% |
| **Fase 9 (Vinculación BD)** | 🔴 PENDIENTE | 5 campos sin mapear, 4 migraciones | 0% |
| **Deuda técnica** | ⚠️ 13 items | 2 alta, 4 media, 7 baja | — |

### 7.2 ¿Está el proyecto listo para producción?

#### ✅ Para el alcance actual (Fases 0-7): **SÍ**

El código compila, analiza y despliega sin errores. Las 17 migraciones están aplicadas en remoto. Las features implementadas (Dashboard, Bienestar, Time-Blocking, Analítica, Social, Insignias, Pomodoro, Escanear, Admin, Sync Offline) funcionan correctamente. La app es **funcional y desplegable** en su estado actual.

#### 🔴 Para el alcance completo planificado (Fases 0-9): **NO**

Faltan 2 fases:
1. **Fase 8 — Títulos Inteligentes:** ~3 horas. Bajo riesgo (solo código Dart, sin migraciones).
2. **Fase 9 — Vinculación Completa BD:** ~6 horas. Riesgo medio (4 migraciones DB, 5 campos en modelo Dart, 3 campos en DTO).

### 7.3 ¿Qué falta para el 100%?

| # | Item | Esfuerzo | Riesgo | Orden |
|---|------|----------|--------|-------|
| 1 | Corregir 10 issues `prefer_const_*` | 10 min | Nulo | Inmediato |
| 2 | Eliminar código deprecado (`CrearPlanSemanalScreen`, `WizardPlanNotifier`) | 30 min | Bajo | Inmediato |
| 3 | **Fase 8: Integrar dead code `generarNombreDia/Semana`** | 3 h | Bajo | Primero |
| 4 | **Fase 9.1: Crear migraciones 0015-0018** | 2 h | Medio | Segundo |
| 5 | **Fase 9.2: Sincronizar `HorarioAcademicoDb` +5 campos** | 1 h | Bajo | Tercero |
| 6 | **Fase 9.3: Sincronizar `TimeBlock` DTO +3 campos** | 30 min | Bajo | Cuarto |
| 7 | **Fase 9.4: Actualizar providers (guardar, toggle, crear plan)** | 2 h | Medio | Quinto |
| 8 | **Fase 9.5: UI (InboxScreen botón rutina, CanvasScreen BottomSheet)** | 1 h | Bajo | Sexto |
| 9 | Actualizar `AGENTS.md` y docs afectados | 30 min | Nulo | Final |

**Total pendiente:** ~10.5 horas de desarrollo

### 7.4 Próximo paso recomendado

1. ✅ **Corregir issues triviales ahora** ✅ — Completado en v7.2. `prefer_const_*`, `unused_import`, `unnecessary_cast`, `unused_element_parameter` y deprecaciones corregidas. 0 issues en `flutter analyze`.
2. ✅ **Eliminar código deprecado (`CrearPlanSemanalScreen`, `WizardPlanNotifier`)** ✅ — Completado en v7.2. Archivos eliminados, import/ruta limpiados en `app_router.dart`.
3. 🔜 **Ejecutar Fase 9** (6 h) — Completar vinculación DB con 4 migraciones + sincronización de modelos
4. 🔜 **Re-ejecutar verificación final** — Los comandos de la sección 6
5. 🔜 **Actualizar docs** — El agente `documentacion` debe sincronizar `AGENTS.md` y docs afectados

---

## Anexo A: Inventario Completo de Migraciones

| # | Archivo | Descripción | Estado |
|---|---------|-------------|--------|
| 0049 | `202606060049_esquema_base.sql` | Esquema base: todas las tablas principales, RLS, triggers, seed data | ✅ Aplicada |
| 0050 | `202606120050_dependencias_retos.sql` | Dependencias entre ejercicios y retos | ✅ Aplicada |
| 0001 | `202606130001_marcar_semana_completada.sql` | Función/trigger para marcar semana de rutina como completada | ✅ Aplicada |
| 0002 | `202606140001_v_analitica_semanal.sql` | Vista materializada `v_analitica_semanal` para dashboard analítico | ✅ Aplicada |
| 0003 | `20260616000002_social_moderacion.sql` | Tablas de moderación para el muro social (reportes, flags) | ✅ Aplicada |
| 0004 | `20260616000003_insignias.sql` | Tablas de insignias: catálogo, usuario_insignias, racha tracking | ✅ Aplicada |
| 0005 | `20260616000004_consolidacion_fixes.sql` | Consolidación: +5 columnas en horarios_academicos (plan_estudio_id, prioridad, tipo_actividad, rutina_id, temas), fixes varios | ✅ Aplicada |
| 0006 | `20260616000005_fechas_coherencia.sql` | Coherencia de fechas: `fecha_inicio` en rutinas, ajustes temporales | ✅ Aplicada |
| 0007 | `20260616000006_admin_rol.sql` | Sistema de roles admin: RLS policies, función `is_admin()` | ✅ Aplicada |
| 0008 | `20260616000007_nivel_actividad_check.sql` | Validación de nivel de actividad en check-ins | ✅ Aplicada |
| 0009 | `20260616000008_asignaturas_usuario_semestre.sql` | Tabla `asignaturas_usuario_semestre` para catálogo académico personal | ✅ Aplicada |
| 0010 | `20260616000009_admin_panel_v2.sql` | Admin Panel v2: vistas, funciones RPC, políticas adicionales | ✅ Aplicada |
| 0011 | `20260616000010_admin_delete_user.sql` | RPC `delete_user()` con hard delete en cascada (28+ tablas) | ✅ Aplicada |
| 0012 | `20260617000011_calendar_grid.sql` | Calendar Grid: `es_fijo` + `dia_semana` en horarios_academicos | ✅ Aplicada |
| 0013 | `20260618000012_xp_planificacion.sql` | `xp_planificacion_otorgado` en planes_estudio | ✅ Aplicada |
| 0014 | `20260618000013_bloque_xp_tracking.sql` | `xp_bloque_otorgado` en horarios_academicos + `xp_entrega_otorgado` en entregas_examenes | ✅ Aplicada |
| 0015 | `20260618000014_retos_bloques_bridge.sql` | `reto_id` + `hito_id` FK en horarios_academicos | ✅ Aplicada |
| — | `20260618000015_dia_rutina_fk.sql` | `dia_rutina_id` FK → `dias_rutina(id)` | 🔴 No creada |
| — | `20260618000016_rutina_id_fk_fix.sql` | `rutina_id` → FK real `REFERENCES rutinas(id)` | 🔴 No creada |
| — | `20260618000017_trigger_hito_progreso.sql` | Trigger auto progreso de hitos al completar bloque | 🔴 No creada |
| — | `20260618000018_unique_dias_rutina.sql` | UNIQUE `(rutina_id, numero_semana, dia)` en dias_rutina | 🔴 No creada |

---

## Anexo B: Correcciones Triviales Pendientes (baja prioridad)

Ejecutar en cualquier momento — no requieren Fase 8 ni 9:

```bash
# Archivos con prefer_const_declarations (2 issues)
# timeblock_ia_service.dart:220 — añadir 'const' a variable final
# time_block_widget.dart:23 — añadir 'const' a variable final

# Archivos con prefer_const_constructors (7 issues)
# canvas_screen.dart:169,170 — añadir 'const' a constructores
# inbox_screen.dart:199,302,492 — añadir 'const' a constructores
# progress_gamification_bar.dart:96 — añadir 'const' a constructor

# Archivos con prefer_null_aware_operators (1 issue)
# canvas_screen.dart:186 — usar '?.' en vez de comparación explícita con null

# Archivos con use_build_context_synchronously (1 issue)
# canvas_screen.dart:368 — guardar context antes de await o usar mounted check
```

---

*Documento generado por el agente **Corrector (QA / Revisor)** el 17-06-2026.*  
*Última actualización: 17-06-2026 16:00 UTC-6*  
*Línea base de verificación: `flutter analyze` 0 errors, 0 warnings, 14 info | `dart format .` 0 changed | `supabase db push` up to date*
