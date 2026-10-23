# Integración continua

`.github/workflows/ci.yml` se ejecuta en cada push y pull request a `master`:

| Job | Pasos |
|---|---|
| `backend` | JDK 21 → `./mvnw -B test -Pintegration` (unitarios, arquitectura e integración con PostgreSQL embebido) |
| `frontend` | Flutter 3.44.0 → `pub get` → `build_runner` → `merge_arb` + `gen-l10n` → `flutter analyze` → `flutter test` |
| `images` | Solo en push a `master` y con los dos anteriores en verde: compila `backend/Dockerfile` y `frontend/Dockerfile` y publica `ghcr.io/jloen1999/synaptixfit-{backend,web}` con las etiquetas `latest` y el commit |

Variables del repositorio (GitHub → Settings → Variables): `GOOGLE_WEB_CLIENT_ID` (no es secreta) y, opcional, `PUBLIC_APP_URL`.

El despliegue en el VPS es un paso explícito con la etiqueta del commit: [`deploy.md`](deploy.md). No es automático porque el panel de Coolify no es accesible desde Internet (solo por túnel SSH).
