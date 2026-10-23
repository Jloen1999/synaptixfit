# Backend (Spring Boot hexagonal)

Perfil completo: `../docs/01-architecture/profiles/backend-spring-hexagonal.md`. Léelo antes de crear paquetes nuevos.
Cada capa (`domain/`, `application/`, `infrastructure/`) tiene su propio `CLAUDE.md`. Paquete base: `com.synaptixfit` (`src/main/java/com/synaptixfit/`).

Stack: Java 21 · Spring Boot 4.1 (Web MVC, Data JPA, Security resource server) · PostgreSQL 17 · Flyway · springdoc 3 · ArchUnit · Jackson 3 (`tools.jackson.*`).

## Mapa rápido

- `domain/` → modelos (`model/<feature>/`), excepciones con `code` (`exception/<feature>/`), puertos de salida (`port/output/<feature>/`) y eventos (`event/<feature>/`). Java puro.
- `application/` → puertos de entrada (`port/input/<feature>/`) y servicios (`service/<feature>/`). Sin Spring.
- `infrastructure/` → controllers y DTOs, oyentes de eventos, persistencia, clientes externos (DeepSeek, R2, Google), configuración.

## Convenciones del proyecto

- **Composición:** cada funcionalidad tiene su `infrastructure/config/<Feature>BeanConfiguration`. Patrón (ver `BeanConfiguration`): puertos por constructor, servicio con `@Bean(autowireCandidate = false)` y un bean por contrato envuelto con `TransactionalUseCaseFactory.wrap(...)`. La aplicación nunca usa `@Transactional`.
- **Errores:** las excepciones de dominio extienden una categoría (`NotFoundException`, `ConflictException`, `BusinessRuleException`, `InvalidInputException`, `ForbiddenOperationException`, `AuthenticationException`, `ExternalServiceException`). El `GlobalExceptionHandler` deriva el estado HTTP de la categoría; `STATUS_BY_CODE` solo para excepciones justificadas. Cada `code` nuevo va a `docs/03-api/errors.md`.
- **Propiedad de los datos:** un recurso ajeno se trata como inexistente (404 con el `code` del recurso). El id del usuario sale siempre del JWT (`@CurrentUserId UUID userId`), nunca del cuerpo.
- **Acoplamiento entre módulos:** mediante eventos de dominio (`domain/event/`, publicados con `DomainEventPublisherPort`, síncronos y en la misma transacción). Los oyentes son adaptadores de entrada en `infrastructure/adapter/input/event/<feature>/` y llaman a casos de uso. Deben ser idempotentes. Catálogo: `../docs/01-architecture/events.md`.
- **Experiencia (XP):** se suma o resta solo con `AwardExperienceUseCase` / `RevokeExperienceUseCase`.
- **Persistencia:** entidades en `persistence/entity/<feature>/`, una sola entidad JPA por tabla (la del módulo propietario, ver `../docs/01-architecture/data_model.md`). Las lecturas de tablas de otro módulo se hacen con `JdbcClient` dentro del adaptador. `jsonb` → `@JdbcTypeCode(SqlTypes.JSON)`, arrays → `@JdbcTypeCode(SqlTypes.ARRAY)`, columnas generadas → `insertable = false, updatable = false`. El esquema lo gobierna Flyway (`ddl-auto=validate`).
- **Migraciones:** en `src/main/resources/db/migration/postgresql/` (una carpeta por motor, `DB_VENDOR`); nunca se edita una migración aplicada; se añade `V<n>__<modulo>_<descripcion>.sql`.
- **Portabilidad (ADR 0012):** las consultas solo traen datos en SQL estándar; las reglas van al dominio. Lo propio de PostgreSQL queda listado en `../docs/06-ops/database_portability.md`.
- **IA:** cada funcionalidad define su puerto de dominio (p. ej. `StudyAssistantPort`) y lo implementa en `adapter/output/external/ai/<feature>/` usando `GenerativeAiPort` como transporte. Los prompts viven en ese adaptador.
- **API:** `/api/v1/...`, JSON camelCase, fechas ISO-8601 (`Instant` para instantes, `LocalDate` para días), enums en `UPPER_SNAKE_CASE`, listas paginadas con `PageResponse`.

## Pasos para una funcionalidad nueva

1. `domain/` → modelo, excepción(es) con `code` y puerto de salida.
2. `application/` → puerto de entrada + servicio.
3. `infrastructure/adapter/output/` → entidad JPA, repositorio Spring Data, mapper y adapter.
4. `infrastructure/adapter/input/rest/` → controller y DTOs.
5. `infrastructure/config/<Feature>BeanConfiguration` → registrar los casos de uso.
6. Fila en `docs/03-api/errors.md` por cada `code` nuevo.
7. Tests: unitario del servicio (con `new` y dobles) y, si aplica, de integración (`*IT`, PostgreSQL embebido).

## Comandos

- Tests unitarios y de arquitectura: `./mvnw test`.
- Con integración (arranca la app sobre PostgreSQL embebido): `./mvnw test -Pintegration`.
- Ejecutar: `docker compose up -d db` (desde la raíz) y `./mvnw spring-boot:run`.
- OpenAPI: con la app arrancada, `GET /v3/api-docs.yaml` → `../docs/03-api/openapi.yaml`.

## Comentarios

- Javadoc de una o dos líneas en cada clase pública: qué papel cumple y con qué se relaciona (p. ej. «Implementa FinishTrainingSessionUseCase; guarda con TrainingSessionRepositoryPort y publica TrainingSessionCompletionChanged»).
- Explica el porqué de las reglas de negocio y las fórmulas (con su origen); nada de comentarios evidentes ni código comentado.

## No hacer

- No crear un `ApiResponse<T>`: éxito con DTO directo, errores con `ProblemDetail`.
- No escribir `openapi.yaml` a mano.
- No mover lógica de negocio a triggers o funciones SQL.
