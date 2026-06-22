# AGENTS.md — SynaptixFit

## Tech Stack
- **Frontend:** Flutter (Dart 3.3+) at `app/` — Riverpod, GoRouter, Supabase SDK, Hive, fl_chart, connectivity_plus, file_picker
- **Backend:** Supabase (PostgreSQL + Auth + Realtime) — no traditional server, no Node.js/Express
- **Storage proxy:** Cloudflare Worker at `cloudflare/synaptixfit-r2-proxy/worker.js`
- **No `package.json`, no `yarn`, no npm** — this is a Flutter repo, not Node.js
- **No CI/CD** implemented yet

## Language convention
- Code (variables, files, endpoints): **English**
- Comments (DartDoc) and docs/ files: **Spanish**

## Essential commands

### Flutter (run inside `app/`)
```bash
flutter pub get                  # install deps
dart format .                    # format all Dart code
flutter analyze                  # lint (uses flutter_lints from analysis_options.yaml)
flutter test                     # unit + widget tests
flutter test --coverage          # with coverage
dart run build_runner build      # regenerate Riverpod .g.dart files after changing providers
flutter run -d chrome            # web dev
flutter build apk --release      # Android release
```

### Supabase (run from repo root)
```bash
supabase db push                 # deploy migrations to linked project
supabase functions deploy --all  # deploy edge functions (if any)
```

### Data seeding (Python, from repo root)
```bash
python supabase/seed_catalogo_v2.py    # populate academic catalog v2 from grados.json
```

### DB Sync (local ↔ remote)
```bash
# Poblar remoto desde local
python supabase/seed_catalogo_v2.py

# Volcar remoto a migración local
supabase db dump --linked --data-only > supabase/seed_data.sql

# Aplicar migraciones pendientes a local y remoto
python supabase/apply_migrations.py
```

### DB migrations (manual fallback)
```bash
supabase db push                 # deploy migrations to linked project
# If CLI not linked, run migraciones_pendientes.sql in Supabase SQL Editor
```

## Architecture at a glance
- **`app/lib/main.dart`** — entry point, loads `.env`, initializes Supabase, wraps in ProviderScope
- **`app/lib/core/routing/app_router.dart`** — GoRouter with shell route + bottom nav (5 tabs)
- **`app/lib/shared/models/db_models.dart`** — all DB model classes (~2330 lines, incl. `CargaAcademicaSemanalDb` and `AsignaturaUsuarioSemestreDb`)
- **`app/lib/shared/widgets/metric_gauge.dart`** — animated radial gauge CustomPainter (1200ms) for dashboard metrics
- **`app/lib/core/config/env_config.dart`** — reads Supabase URL/anonKey, Google OAuth, Gemini, R2 from `.env`
- **`app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart`** — Gemini prompts with JSON mode + smart catalog (top 60) + unified context formatting (~1357 lines)
- **`app/lib/features/bienestar/infrastructure/recomendacion_orquestador_service.dart`** — pipeline orchestrator: 7 stages + fallback + param preservation (~412 lines)
- **`app/lib/features/bienestar/infrastructure/recomendacion_contexto_service.dart`** — ContextoAcademico DTO + FCT calculation + energy gates (~381 lines)
- **`app/lib/features/bienestar/infrastructure/recomendacion_reglas_service.dart`** — deterministic rule engine with per-modality parameters (~710 lines)
- **`app/lib/features/bienestar/infrastructure/progresion_calculator.dart`** — progressive overload with isometric support (~380 lines)
- **`app/lib/features/bienestar/application/rutina_provider.dart`** — all routine + academic + energy providers (~1678 lines, incl. `adherenciaAcademicaProvider`, `estadoEnergeticoProvider`, `contextoAcademicoProvider`, `diaPendienteProvider`, `syncCargaAcademicaSemanal`, `otorgarXp()`, `finalizarSesion()`, DTO `XpResultado`)
- **`app/lib/features/perfil/application/perfil_provider.dart`** — profile data cache with selective invalidation (PerfilCambio enum)
- **`app/lib/shared/models/timeline_item.dart`** — DTO `TimelineItem` with enum `TimelineTipo` (9 values) + 5 factory constructors (~186 lines)
- **`app/lib/features/dashboard/application/timeline_provider.dart`** — `timelineHoyProvider` with 5 parallel queries + `diaPendienteProvider` unificado (~91 lines)
- **`app/lib/features/analitica/domain/metrica_semanal_dto.dart`** — DTO `MetricaSemanal` con factory `fromMap` para datos de `v_analitica_semanal`
- **`app/lib/features/analitica/domain/insight_correlacion_dto.dart`** — DTO `InsightCorrelacion` para resultados de correlacion Pearson
- **`app/lib/features/analitica/domain/periodo_analitica.dart`** — enum `PeriodoAnalitica` (semanal/mensual/trimestral) con getters `semanas` y `etiqueta`
- **`app/lib/features/analitica/infrastructure/analitica_repository.dart`** — `AnaliticaRepository` consulta `v_analitica_semanal` + `carga_academica_semanal`, calcula correlacion Pearson (~220 lines)
- **`app/lib/features/analitica/infrastructure/insight_generator.dart`** — generador estatico de frases interpretativas en espanol (racha, consistencia, volumen, correlacion)
- **`app/lib/features/analitica/application/analitica_provider.dart`** — 6 providers Riverpod: `analiticaRepositoryProvider`, `analiticaSemanalProvider`, `tendenciaRpeProvider`, `volumenSemanalProvider`, `correlacionCargaProvider`, `periodoSeleccionadoProvider`
- **`app/lib/features/sync/domain/connectivity_state.dart`** — enum `ConnectivityState` (online/offline/syncing)
- **`app/lib/features/sync/infrastructure/connectivity_service.dart`** — Stream de estado de conectividad (connectivity_plus)
- **`app/lib/features/sync/infrastructure/offline_queue_service.dart`** — cola Hive para operaciones pendientes con reintentos (max 3)
- **`app/lib/features/sync/application/sync_provider.dart`** — providers Riverpod: `connectivityStateProvider`, `offlineQueueServiceProvider`, `offlineQueueLengthProvider`, `syncProvider`
- **`app/lib/features/pomodoro/domain/pomodoro_session.dart`** — DTO con estados de sesión Pomodoro (idle/estudio/descanso/pausado)
- **`app/lib/features/pomodoro/application/pomodoro_provider.dart`** — `pomodoroProvider` (StateNotifier con Timer.periodic, 25/5 min)
- **`app/lib/features/pomodoro/presentation/pomodoro_screen.dart`** — Pantalla con anillo CustomPainter y controles (iniciar/pausar/reanudar/reiniciar/skip)
- **`app/lib/features/pomodoro/presentation/widgets/pomodoro_progress_painter.dart`** — Anillo circular animado que decrece con el tiempo restante
- **`app/lib/features/escanear/domain/escanear_result.dart`** — DTO con texto escaneado y metadatos
- **`app/lib/features/escanear/infrastructure/scanner_service.dart`** — Abstracción `ScannerService` con implementaciones condicionales Web/Mobile
- **`app/lib/features/escanear/application/escanear_provider.dart`** — Provider del servicio de escaneo
- **`app/lib/features/escanear/presentation/escanear_screen.dart`** — Pantalla dual: Web (mensaje informativo), Mobile (TextField + guardar como apunte Markdown)
- **`app/lib/features/social/domain/social_dto.dart`** — DTOs `Publicacion` y `Comentario` con factory `fromMap` que resuelven joins de Supabase (usuarios, conteos, mi_like)
- **`app/lib/features/social/infrastructure/social_repository.dart`** — `SocialRepository` con queries reales: feed paginado, likes, comentarios (CRUD con soft delete), notificaciones best-effort
- **`app/lib/features/social/application/social_provider.dart`** — providers Riverpod: `socialFeedProvider`, `socialCommentsProvider.family`, `likeStateProvider.family`; mutaciones: `toggleLike`, `publicarEnFeed`, `enviarComentario`, `editarComentarioMutation`, `eliminarComentarioMutation`
- **`app/lib/features/social/presentation/muro_social_screen.dart`** — `ConsumerStatefulWidget` con filtros temporales, RefreshIndicator, FAB → BottomSheet para crear publicaciones
- **`app/lib/features/social/presentation/widgets/feed_item_card.dart`** — Card de publicación con avatar, tipo, likes animados, sección de comentarios expandible con `ComentarioInput`
- **`app/lib/features/social/presentation/widgets/comentario_card.dart`** — Card individual de comentario con avatar, editar/eliminar para autor
- **`app/lib/features/social/presentation/widgets/comentario_input.dart`** — Barra de input de comentario con validación 1-500 chars
- **`app/lib/features/insignias/domain/insignia_dto.dart`** — DTOs `Insignia` (catálogo con rareza/color) y `RachaState` (estado de racha con hitos)
- **`app/lib/features/insignias/infrastructure/insignias_repository.dart`** — `InsigniasRepository` consulta catálogo LEFT JOIN usuario_insignias, otorga por UNIQUE constraint
- **`app/lib/features/insignias/infrastructure/insignia_engine.dart`** — `InsigniaEngine` evalúa 13 criterios contra BD y otorga insignias automáticamente (~258 lines). Incluye métrica `semanas_plan_adherencia` para insignia "Planificador Maestro" (4 semanas consecutivas con ≥80% adherencia).
- **`app/lib/features/insignias/infrastructure/racha_service.dart`** — `RachaService` calcula racha diaria (sesiones + check-ins), hitos (7/30/100/365), riesgo (<4h)
- **`app/lib/features/insignias/application/insignias_provider.dart`** — 6 providers: `catalogoInsigniasProvider`, `insigniasUsuarioProvider`, `insigniasCountProvider`, `rachaStateProvider`, `insigniasRecienObtenidasProvider`; acción `evaluarInsignias()` + toast `mostrarInsigniaToast()`
- **`app/lib/features/insignias/presentation/insignias_screen.dart`** — `ConsumerStatefulWidget` con filtro por categoría (6 chips), grid 2 columnas, bottom sheet de detalle
- **`app/lib/features/insignias/presentation/widgets/insignia_card.dart`** — Card de insignia (obtenida = color vibrante, bloqueada = gris + candado)
- **`app/lib/features/insignias/presentation/widgets/racha_indicator.dart`** — Widget de racha con barra de progreso, alerta de riesgo, récord histórico
- **`app/lib/features/admin/`** — Panel de administración Fase 3 (final): `AdminHubScreen` (TabBar 5 tabs: KPIs, Usuarios, Contenido, Ejercicios, Auditoría), `AdminPanelScreen` (refactorizado como pestaña Usuarios con búsqueda, filtros, ordenamiento y botón eliminar), `AdminUsuarioDetalle` (3 sub-pestañas: Perfil/Estadísticas/Timeline con gráficos fl_chart y timeline real, configuración de usuario: editar nombre/email, reset XP, cambiar nivel, eliminar usuario), `AdminWipeDialog`; 7 DTOs en domain/ (`UsuarioAdmin`, `AdminMetricasGlobales`, `AuditoriaRegistro`, `ContenidoReportado`, `AdminEjercicio`, `AdminUsuarioEstadisticas`, `AdminTimelineEntry`), 6 repositorios en infrastructure/ (`AdminRepository` extendido con `deleteUser()`, `AdminMetricasRepository`, `AdminAuditoriaRepository`, `AdminContenidoRepository`, `AdminEjercicioRepository`, `AdminUsuarioStatsRepository`), 6 provider files en application/ (`admin_provider.dart` con `eliminarUsuario()` y mutaciones de configuración, `admin_metricas_provider.dart`, `admin_auditoria_provider.dart`, `admin_contenido_provider.dart`, `admin_ejercicio_provider.dart`, `admin_usuario_stats_provider.dart`), 15 widgets/pantallas en presentation/ (3 pantallas + 12 widgets: `AdminKpiCard`, `AdminKpiDashboard` con gráfico de tendencia 30 días fl_chart, `AdminLogEntry`, `AdminAuditoriaList`, `AdminPaginacionBar`, `AdminWipeDialog`, `AdminContenidoCard`, `AdminContenidoList`, `AdminEjercicioCard`, `AdminEjercicioList`, `AdminGraficosUsuario`, `AdminTimelineUsuario`); ruta `/admin` protegida por rol; `errorBuilder` añadido a todos los `Image.network`
- **`app/lib/features/academico/`** — Time-Blocking académico (refactor v7.1 — Lienzo Continuo): Custom Grid nativo (Stack+Positioned+Draggable+ DragTarget, 0 dependencias), `InboxScreen` (ruta `/academico/planificar`, sliders de estudio/deporte + barra de energía), `CanvasScreen` (ruta `/academico/planificar/canvas`, grid 7×16h con Drag & Drop + SnackBar XP, fondo oscuro #1A1A2E, barra de navegación semanal infinita `< Anterior | Fechas | Siguiente > | Hoy`, eje horario inline, barra inferior solo "← Volver" y "Guardar plan" — eliminado el botón "Rutina" independiente), `AcademicBlockSheet` (sheet unificado para crear/editar bloques con pestaña Deporte que integra distribución completa de rutina: selector de rutina, switch "Distribuir rutina completa" con selector de días FilterChips L-D, DatePicker de inicio, resumen de bloques, consulta `dias_rutina` reales vía `semana_id`), `RutinaConfigSheet` (conservado pero ya no se usa desde canvas; solo invocado por `placeRutinaDistribuida`), widgets (`TimeGridPainter`, `TimeBlockWidget` con indicador visual de rutina: barra blanca semitransparente + nombre del día + nombre de rutina en subtitle para bloques con `diaRutinaId != null`, `ProgressGamificationBar`, `ConflictBanner`), DTOs (`InboxConfig`, `TimeBlock` con campos `fecha`, `esHitoInamovible` y getter `diaSemanaEfectivo`, `SemanaGenerada`, `CalendarGridState` con campos `semanaOffset`, `fechaInicioPantalla`, `sincronizando` y getter `fechaFinPantalla` en `domain/calendar_dtos.dart`; `TimeBlockTipo` con 8 valores: estudio, deporte, clase, descanso, comida, sueno, entrega, examen), providers (`inboxConfigProvider`, `entregasPendientesProvider`, `asignaturasActivasInboxProvider`, `rutinasActivasInboxProvider`, `horariosFijosProvider`, `calendarGridProvider` con debounce 500ms, persistencia instantánea en moveBlock/resizeBlock y `placeRutinaDistribuida()` para distribución completa de rutina usando columna correcta `semana_id` en `dias_rutina`, `bloque_estudio_provider.dart` con `toggleBloqueCompletado()`), `@Deprecated` en `inyectarRutinaCascada` (queries columnas inexistentes `dia_semana`, `enfoque` en `dias_rutina`), `TimeblockIaService` (Gemini Flash, prompt español, N1-N10 + H1-H5, fallback heurístico), `GridMath` (conversión hora↔píxel con snap 30min + 5 nuevos métodos: `fechaToColumnIndex`, `columnIndexToFecha`, `fechaToOffsetX`, `offsetXToColumnIndex`, `dayHeaderLabel`), XP unificado (plan 100+5×bloques, bloque ceil(mins/30)×10, entrega 30, check-in 20). Eliminados `wizard_plan_provider.dart`, `crear_plan_semanal_screen.dart`, `gestion_asignaturas_screen.dart` y ruta `/plan-semanal/crear` (deprecados en v7.1).
- **`app/lib/features/academico/` (Escaneo de horarios con IA)** — `infrastructure/ai_schedule_parser_service.dart` (`AiScheduleParserService` + `AiParsingException`: Gemini multimodal `gemini-2.5-flash` con `inline_data` base64, prompt determinista que inyecta las asignaturas activas y extrae SOLO el patrón semanal, saneamiento de Markdown y ensamblaje del paquete `{fecha_inicio_clases, fecha_fin_clases, horarios:[...]}`; recibe `Uint8List bytes`+`mimeType` para ser cross-platform); `application/escanear_horario_provider.dart` (`aiScheduleParserServiceProvider`, `guardarFechasSemestre()`, motor `generarHorariosDesdePaquete()` que materializa el patrón en ocurrencias semanales fechadas en `horarios_academicos` con `es_fijo=false`+`es_hito_inamovible=true`, idempotente vía `ics_uid` sintético); `presentation/widgets/escanear_horario_boton.dart` (flujo Clean UI: verifica fechas de semestre en el perfil → Rama A `BottomSheet` plano para pedirlas y guardarlas / Rama B fricción cero, `file_picker` con `withData:true`, `LinearProgressIndicator`/`CircularProgressIndicator`, SnackBar «Horario sincronizado con éxito»); integrado en `app/lib/features/perfil/presentation/perfil_screen.dart` (tarjeta "Mis asignaturas" → pestaña Académico). `PerfilAcademicoDb` ampliado con `fechaInicioClases`/`fechaFinClases` + getter `tieneFechasSemestre`.
- **`app/lib/features/bienestar/presentation/nueva_rutina_screen.dart`** — Creación de rutinas con IA (3 pasos) + edición de nombres de semanas y días vía dialog con TextField, maps `_nombresSemanas`/`_nombresDias`, métodos `_editarNombreSemana()`/`_editarNombreDia()`.
- **`app/lib/core/sync/`** — SyncHub (Fase 2): `DominioEvento` enum (8 eventos: planGuardado, bloqueEstudioCompletado, sesionCompletada, checkInRealizado, entregaCompletada, retoCompletado, pomodoroCompletado, xpOtorgado), `EventoPayload` DTO, `SyncHub` con mapa de invalidaciones por evento, `syncHubProvider` (Riverpod Provider).
- **`app/lib/shared/widgets/exercise_metrics.dart`** — `SemanticMicroChip`, `ExerciseMetricsRow`, enum `ExerciseMetricCategoria` con `desdeModalidad`/`desdeFinalidad`. Aplicado en `nueva_rutina_screen`, `rutina_detalle_screen`, `sesion_en_vivo_screen`, `rutinas_comunidad_screen`.
- **Localización (i18n):** `flutter_localizations` en `pubspec.yaml`. `MaterialApp.router` con `localizationsDelegates` (GlobalMaterialLocalizations/GlobalWidgetsLocalizations/GlobalCupertinoLocalizations) y `supportedLocales` (`es_ES`, `es`, `en`). `DateFormat` con locale `'es'` en `canvas_screen.dart`. Todos los `showDatePicker` en español.
- **`supabase/migrations/`** — 38 archivos de migración. NOTA: 0002-0004 renombrados para evitar colisión; 0004 con DROP VIEW IF EXISTS; 0005 corrige fechas; 0006 admin_rol; 0007 nivel_actividad; 0008 asignaturas_usuario_semestre; 0009 admin_panel_v2; 0010 admin_delete_user; 0011 calendar_grid (es_fijo + dia_semana); 0012 xp_planificacion (xp_planificacion_otorgado en planes_estudio); 0013 bloque_xp_tracking (xp_bloque_otorgado + xp_entrega_otorgado); 0014 retos_bloques_bridge (reto_id + hito_id FK); 0015 dia_rutina_fk (dia_rutina_id + semana_rutina_id FK); 0016 rutina_fk_fix (rutina_id → FK real); 0017 trigger_hito_progreso (trigger progreso automático de hitos); 0018 unique_dias_rutina (UNIQUE + CHECK en dias_rutina); 0019 fix_duplicate_fk_rutina (elimina FK duplicada en horarios_academicos); 0022 lienzo_continuo (amplía CHECK tipo_actividad + FK a entregas_examenes + nuevas columnas en entregas_examenes); 0023 lienzo_continuo_v2 (columna es_hito_inamovible BOOLEAN + índice idx_horarios_fecha_rango en horarios_academicos); 0024 ics_sync (soporte importación/exportación ICS); 0025 ics_upsert_fix (corrección UPSERT en sincronización ICS); 0001 dias_disponibles_array; 0002 fix_nivel_umbral (umbral de subida de nivel = 100 × nivel, consistente con la UI); 0003 xp_overflow_multinivel (subida de nivel inmediata + arrastre del sobrante multinivel en `otorgar_xp`, evita mostrar XP por encima del objetivo); 20260622000004 visibilidad_rls (activa RLS en `rutinas`/`retos`/`horarios_academicos` con políticas dueño + admin + lectura de pares según `nivel_privacidad`/`amistades`; funciones SECURITY DEFINER `es_admin`/`nivel_privacidad_de`/`son_amigos`; trigger `trg_invalidar_contenido_privado` que privatiza rutinas/retos al pasar el perfil a 'privado'); 20260622000005 carga_xp_estudio_otorgado (añade la columna `xp_estudio_otorgado` que faltaba en remoto en `carga_academica_semanal`, corrige divergencia de esquema y el error 42703 al sincronizar la carga académica); 20260622000006 retos_sinergia_v2 (Fase 1 del refactor de Retos: añade `asignatura_id`, `dificultad` baja/media/alta, `entidad_vinculada_id` y `entidad_vinculada_tipo` examen/entrega a `retos` y `hitos_de_reto`, con CHECKs e índices para el deep-linking con la agenda); 20260622000007 retos_xp_tracking (Fase 5 del refactor de Retos: columna `xp_otorgado` en `retos`/`hitos_de_reto` para registrar el XP exacto otorgado por el estado completado actual —anti-farmeo— y RPC `restar_xp` que resta XP con bajada de nivel segura, inverso de `otorgar_xp`); 20260622000008 retos_deep_linking (sincronización bidireccional reto/tarea ⇄ examen/entrega: helper SQL `xp_por_dificultad` + triggers `trg_sync_entrega_a_reto` (con ajuste de XP coherente vía guarda `xp_otorgado`), `trg_sync_reto_a_entrega` y `trg_sync_hito_a_entrega`, todos SECURITY DEFINER y con anti-bucle `WHEN OLD IS DISTINCT FROM NEW` + guarda `IS DISTINCT`); 20260622000009 social_realtime (añade `actividades_sociales`, `interacciones_sociales` y `comentarios_feed` a la publicación `supabase_realtime` con `REPLICA IDENTITY FULL` para que el muro social se actualice en tiempo real; reasegura la lectura pública del feed `actividades_sociales`); 20260622000010 perfil_fechas_semestre (añade `fecha_inicio_clases` y `fecha_fin_clases` DATE a `perfil_academico_usuario` para que el flujo de escaneo de horarios con IA adjunte las fechas absolutas al patrón semanal extraído del documento); 20260622000011 social_publicaciones_v2 (añade columnas a `actividades_sociales` para tipos de publicación enriquecidos); 20260622000012 procedencia_clones (columna `procedencia` en `rutinas` para trazabilidad de clones).
- **`docs/`** — 22-file documentation structure: 00-plan-maestro → 21-plan-definitivo, kept in sync with code. Updated for Sprint Time-Blocking (v7.0) y 9 fases de coherencia.

## Database notes
- All tables have Row Level Security enabled; `ejercicios` + catalog tables are public-read
- User-owned tables are owner-only write; some allow peer visibility
- `auth.users` ↔ `public.usuarios` sync via trigger (migration 0004)
- If adding/modifying tables: create a **new** migration file, never edit old ones

## Git safety (Gatekeeper)
Per `.agents/rules/actualizacion-git.md`:
- **Never** commit/push automatically after writing code
- Pause and ask user to test manually; wait for explicit "OK" / "Aprobado" / "Funciona"
- Commit messages in **Spanish**, Conventional Commits format: `feat: [Módulo] Descripción`
- Push only to `master`

## Equipo de agentes (.opencode/agents/)

| Agente | Archivo | Rol |
|--------|---------|-----|
| `corrector` | `corrector.md` | QA — ejecuta `dart format .` + `flutter analyze`, reporta y corrige issues de lint/formato |
| `desarrollador` | `desarrollador.md` | Dev Flutter/Dart — implementa features, corrige bugs, escribe código de producción |
| `diseñador` | `diseñador.md` | Arquitecto — diseña estructura de carpetas, esquemas BD, contratos de API, diagramas Mermaid |
| `documentacion` | `documentacion.md` | Tech Writer — sincroniza `docs/` (22 archivos) con el código fuente, verifica discrepancias |
| `product-manager` | `product-manager.md` | PM — investiga mercado, define MVP y requisitos, escribe `docs/02-requirements.md` |

## Skills disponibles (.agents/skills/)

| Skill | Carpeta | Propósito |
|-------|---------|-----------|
| `equipo-jloen` | `equipo-jloen/SKILL.md` | Protocolo de orquestación: ciclo de vida de features, gatekeeping, doc-sync obligatorio, flujo Git |
| `frontend-design` | `frontend-design/SKILL.md` | Diseño de interfaces frontend con alta calidad estética |

## Regla de sincronización de AGENTS.md

Todo agente o skill que modifique el código del proyecto debe:
1. **Leer `AGENTS.md` al iniciar** para tener contexto completo del proyecto.
2. **Actualizar `AGENTS.md` al finalizar** si sus cambios afectan: stack tecnológico, arquitectura, estructura de carpetas, rutas, dependencias, comandos, estructura de `docs/`, o convenciones de código.

## Regla de sincronización docs ↔ código

Todo cambio en el código que afecte APIs, rutas, modelos, tablas, dependencias o arquitectura **debe** reflejarse en `docs/`. El agente `documentacion` es responsable de esta sincronización.

| Cambio en código | Docs a actualizar |
|-----------------|-------------------|
| Nueva feature completa | `14-changelog.md` + doc del módulo afectado |
| Nuevo archivo/carpeta | `AGENTS.md` (§Architecture) + `03-architecture.md` |
| Nueva migración | `AGENTS.md` + `04-data-model.md` + `07-backend.md` |
| Nueva ruta | `06-frontend.md` (§2) |
| Cambio de nombre de archivo/clase | `AGENTS.md` + docs que lo referencien |
| Feature eliminada | Eliminar de TODOS los docs que la mencionen |

### Verificación de consistencia docs ↔ código

```bash
# Verificar que no hay referencias a carpetas de features inexistentes
grep -rn "planificador/" docs/  # Debe devolver 0 resultados

# Verificar que los nombres de providers en docs existen en código
grep -rn "Provider\|provider" docs/ | grep -v "AGENTS.md"

# Verificar conteo de migraciones
ls supabase/migrations/*.sql | wc -l  # Comparar con AGENTS.md y docs/
```

El agente `documentacion` DEBE ejecutar esta verificación al final de cada sprint.
