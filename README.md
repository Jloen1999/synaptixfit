# SynaptixFit

Aplicación para estudiantes universitarios que equilibra **estudio y entrenamiento**: planifica la semana en un calendario de bloques, repasa con tarjetas y tests generados por IA (repaso espaciado SM-2), sigue rutinas de entrenamiento personalizadas, compite en retos y ajusta la carga física y cognitiva con indicadores neurofisiológicos.

| Parte | Tecnología | Carpeta |
|---|---|---|
| App (Android, iOS, web, escritorio) | Flutter + BLoC | `frontend/` |
| API | Spring Boot 4 (Java 21), arquitectura hexagonal | `backend/` |
| Base de datos | PostgreSQL 17 + Flyway | `docker-compose.yml` |
| Servicios externos | DeepSeek (IA), Cloudflare R2 (archivos), Google Sign-In | solo desde el backend |

## Arranque en 5 minutos

Requisitos: Docker, JDK 21, Flutter 3.44 (versiones exactas en `docs/04-guides/onboarding.md`).

```bash
docker compose up -d db                      # PostgreSQL en localhost:5432
cp backend/.env.example backend/.env         # rellena JWT_SECRET (y DeepSeek/R2 si los vas a usar)
cd backend && ./mvnw spring-boot:run         # API en http://localhost:8080 (Swagger: /swagger-ui.html)
cd frontend && flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Documentación

- Mapa de la arquitectura en una página: [`ARCHITECTURE.md`](ARCHITECTURE.md).
- Todo lo demás en [`docs/`](docs/): arquitectura, decisiones (ADR), API y errores, guías y diseño.
- Contexto para asistentes de código: [`CLAUDE.md`](CLAUDE.md).
