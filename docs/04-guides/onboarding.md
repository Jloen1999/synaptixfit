# Puesta en marcha

## Versiones

| Herramienta | Versión |
|---|---|
| JDK | 21 |
| Maven | 3.9 (incluido el wrapper `./mvnw`) |
| Spring Boot | 4.1.1 |
| PostgreSQL | 17 (imagen `postgres:17-alpine`) |
| Flutter / Dart | 3.44 / 3.12 |
| Docker | 24 o superior |

## Backend

```bash
docker compose up -d db
cp backend/.env.example backend/.env     # al menos JWT_SECRET (openssl rand -base64 48)
cd backend
./mvnw spring-boot:run                   # aplica las migraciones Flyway al arrancar
```

- Swagger UI: http://localhost:8080/swagger-ui.html
- Salud: http://localhost:8080/actuator/health
- Sin `DEEPSEEK_API_KEY` o sin credenciales de R2 la app funciona, pero las funciones de IA y archivos devuelven `AI_UNAVAILABLE` / `STORAGE_UNAVAILABLE`.
- Variables de entorno: `backend/.env.example`. Para cargarlas en local sin Docker, expórtalas en tu shell o usa la configuración de ejecución del IDE.

## Frontend

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run tool/merge_arb.dart && flutter gen-l10n
cp config/dev.example.json config/dev.json   # la primera vez; rellena GOOGLE_CLIENT_ID
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/dev.json
```

`config/dev.json` no se sube al repositorio. Valores que admite (también como `--dart-define` sueltos):

| Clave | Para qué |
|---|---|
| `API_BASE_URL` | URL del backend (`http://10.0.2.2:8080` en el emulador Android) |
| `GOOGLE_CLIENT_ID` | ID de cliente OAuth de Google para web/iOS. En web, sin él no se muestra el botón de Google |
| `GOOGLE_SERVER_CLIENT_ID` | ID de cliente web (Android lo necesita para obtener el ID token) |

El mismo ID web va en `GOOGLE_CLIENT_IDS` de `backend/.env` (el backend valida el ID token contra él). En Google Cloud Console → Credenciales → ese cliente OAuth, añade los **orígenes de JavaScript autorizados**: `http://localhost:5173` (desarrollo) y `https://synaptixfit.jloenit.dev` (producción).

## Primer administrador

Regístrate desde la app y ejecuta:

```bash
docker compose exec db psql -U synaptixfit -c "update usuarios set rol = 'admin' where email = 'tu@email.com';"
```

Cierra sesión y vuelve a entrar para que el token lleve el rol.

## Datos demo

Para tener cuentas con varias semanas de historia (estudio, entrenamiento, retos, insignias, red social y un administrador), con el backend arrancado:

```bash
python tools/demo/seed_demo.py --db local      # crea las cuentas @demo.synaptixfit.test
python tools/demo/purge_demo.py --db local     # las borra
```

Personas, contraseña, ejecución en producción y guion de pruebas: [`tools/demo/README.md`](../../tools/demo/README.md).
