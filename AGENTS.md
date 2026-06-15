# AGENTS.md — SynaptixFit

## Tech Stack
- **Frontend:** Flutter (Dart 3.3+) at `app/` — Riverpod, GoRouter, Supabase SDK, Hive, fl_chart, connectivity_plus
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
- **`app/lib/features/insignias/infrastructure/insignia_engine.dart`** — `InsigniaEngine` evalúa 12 criterios contra BD y otorga insignias automáticamente (~170 lines)
- **`app/lib/features/insignias/infrastructure/racha_service.dart`** — `RachaService` calcula racha diaria (sesiones + check-ins), hitos (7/30/100/365), riesgo (<4h)
- **`app/lib/features/insignias/application/insignias_provider.dart`** — 6 providers: `catalogoInsigniasProvider`, `insigniasUsuarioProvider`, `insigniasCountProvider`, `rachaStateProvider`, `insigniasRecienObtenidasProvider`; acción `evaluarInsignias()` + toast `mostrarInsigniaToast()`
- **`app/lib/features/insignias/presentation/insignias_screen.dart`** — `ConsumerStatefulWidget` con filtro por categoría (6 chips), grid 2 columnas, bottom sheet de detalle
- **`app/lib/features/insignias/presentation/widgets/insignia_card.dart`** — Card de insignia (obtenida = color vibrante, bloqueada = gris + candado)
- **`app/lib/features/insignias/presentation/widgets/racha_indicator.dart`** — Widget de racha con barra de progreso, alerta de riesgo, récord histórico
- **`app/lib/features/admin/`** — Panel de administración: AdminPanelScreen, AdminUsuarioDetalle, AdminWipeDialog; provider `esAdminProvider`; ruta `/admin` protegida por rol
- **`supabase/migrations/`** — 11 migration files (202606060049 esquema base ~12K lines + 202606120050 dependencias_retos + 202606130001 marcar_semana_completada + 202606140001 v_analitica_semanal + 20260616000002 social_moderacion + 20260616000003 insignias + 20260616000004 consolidacion_fixes + 20260616000005 fechas_coherencia + 20260616000006_admin_rol + 20260616000007_nivel_actividad_check + 20260616000008_asignaturas_usuario_semestre), 50+ tables + 2 views + RLS. NOTA: 0002-0004 renombrados para evitar colisión de timestamp en schema_migrations; 0004 modificado con DROP VIEW IF EXISTS para v_ejercicios_completos; 0005 corrige coherencia de fechas en rutinas, retos y entregas; 0006 añade columna rol, RPC wipe_user_data, políticas admin bypass RLS y función es_admin(); 0007 añade CHECK constraint en nivel_actividad (sedentario/ligero/moderado/alto); 0008 añade tabla asignaturas_usuario_semestre para mapeo de transversales a curso+semestre.
- **`docs/`** — 18-file documentation structure: 00-plan-maestro → 17-dataset-lyfta, kept in sync with code

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
| `documentacion` | `documentacion.md` | Tech Writer — sincroniza `docs/` (18 archivos) con el código fuente, verifica discrepancias |
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
