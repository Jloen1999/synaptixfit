# AGENTS.md — SynaptixFit

## Tech Stack
- **Frontend:** Flutter (Dart 3.3+) at `app/` — Riverpod, GoRouter, Supabase SDK, Hive
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
python supabase/seed_ejercicios.py      # populate exercise catalog + M:N relations
python supabase/seed_usuarios.py        # create mock auth users
python supabase/seed_demo_data.py       # full demo dataset
python supabase/seed_catalogo.py        # populate catalog: universidades, carreras, asignaturas
python supabase/seed_asignaturas.py     # user-specific asignaturas from grados.json
```

### DB migrations (manual fallback)
```bash
supabase db push                 # deploy migrations to linked project
# If CLI not linked, run migraciones_pendientes.sql in Supabase SQL Editor
```

## Architecture at a glance
- **`app/lib/main.dart`** — entry point, loads `.env`, initializes Supabase, wraps in ProviderScope
- **`app/lib/core/routing/app_router.dart`** — GoRouter with shell route + bottom nav (5 tabs)
- **`app/lib/shared/models/db_models.dart`** — all DB model classes (~1645 lines)
- **`app/lib/core/config/env_config.dart`** — reads Supabase URL/anonKey, Google OAuth, Gemini, R2 from `.env`
- **`app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart`** — 4 Gemini prompts for routine/exercise recommendations
- **`app/lib/features/perfil/application/perfil_provider.dart`** — profile data cache with selective invalidation (PerfilCambio enum)
- **`supabase/migrations/`** — 18 migration files, 27 tables + RLS, apply in order
- **`docs/`** — 15-file documentation structure (01 through 15), kept in sync with code
- **`migraciones_pendientes.sql`** — consolidated SQL for manual deployment when CLI not linked

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
| `documentacion` | `documentacion.md` | Tech Writer — sincroniza `docs/` (14 archivos) con el código fuente, verifica discrepancias |
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
