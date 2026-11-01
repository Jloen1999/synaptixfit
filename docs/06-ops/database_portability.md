# Portabilidad de la base de datos

> **Qué es:** qué parte del backend ya es independiente del motor, qué sigue siendo propio de PostgreSQL (y dónde) y los pasos para cambiar a MySQL 8.
> **Decisión:** [ADR 0012](../02-adr/0012_database_independent_business_rules.md). Revisado el 2026-10-18.
> **Regla:** la base de datos solo guarda y devuelve datos. Las reglas de negocio viven en `domain/` y `application/`, en Java puro y con tests unitarios.

## 1. Lo que ya es portable

| Pieza | Estado |
|---|---|
| Dominio y casos de uso | Sin dependencias de base de datos. Lo verifica `ArchitectureTest.coreIsDatabaseAgnostic` (prohíbe `java.sql`, `javax.sql`, Hibernate, Flyway y drivers en `domain/` y `application/`). |
| Reglas que antes calculaba SQL | Movidas al dominio (tabla de abajo) y probadas en `DatabaseIndependentRulesTest`, `DashboardServiceTest` y los tests de cada módulo. |
| JPQL de los repositorios Spring Data | Portable (Hibernate lo traduce al dialecto). |
| Consultas `JdbcClient` | SQL estándar salvo lo listado en el apartado 2: `SUM(CASE …)` en lugar de `FILTER`, `SqlLike` (`lower(col) LIKE … ESCAPE '!'`) en lugar de `ILIKE`, `CASE WHEN col IS NULL` en lugar de `NULLS LAST`, fechas restadas y agrupadas por día o semana en Java. |
| Valores generados | Los ids (`UUID.randomUUID()`) y las fechas los pone siempre la aplicación, también en los `INSERT` y `UPDATE` con `JdbcClient` (`AdminAuditJdbcAdapter`, `ModerationAuditJdbcAdapter`, `BadgePersistenceAdapter`, `UserDataErasureJdbcAdapter`, que recibe el instante como parámetro); no depende de `DEFAULT gen_random_uuid()` ni `DEFAULT now()`. Las únicas claves `serial` son las de catálogos de solo lectura (`equipamientos`, `musculos`, `partes_cuerpo`), que llegan con el seed. |
| Errores de integridad | Spring traduce las excepciones del driver a `DataIntegrityViolationException`; `GlobalExceptionHandler` no mira códigos SQL de un motor concreto. |
| Configuración | `DB_VENDOR` (por defecto `postgresql`) elige la URL por defecto `jdbc:<DB_VENDOR>://DB_HOST:DB_PORT/DB_DATABASE` y la carpeta de migraciones `db/migration/<DB_VENDOR>`. `DB_URL` completa tiene prioridad. El driver y el dialecto de Hibernate se deducen de la URL. |

### Reglas que salieron del SQL

| Antes (en la base de datos) | Ahora (dominio) |
|---|---|
| `CASE` de progreso de retos en `DashboardJdbcAdapter.activeChallenges` (además, sumaba el progreso de las tareas) | `DashboardService` usa `ListMyChallengesUseCase` y `Challenge.progress()` (`ActiveChallenge.of`) |
| `count(*) FILTER` por estado en `ChallengePersistenceAdapter.summarize` | `Challenge.statusOf` + `ChallengeSummary.of` |
| Visibilidad de un reto ajeno decidida a medias en SQL (`ChallengeAudiencePersistenceAdapter.canView`) | El adaptador solo trae los datos (`AuthorAudience`, con `SharedContentSql.audienceColumns`) y decide `Challenge.isVisibleTo` → `EffectiveVisibility` |
| Columna generada `carga_diaria` sumada en SQL (insights y SM-2) | Los puertos devuelven filas y `TrainingLoadService` / `StudyMaterialService` aplican `PhysicalLoadRecord.load(rpe, min)` + `PhysicalLoadHistory` |
| Vista `v_analitica_semanal` (`date_trunc`, RPE medio) | `WeeklyTrainingMetric.byWeek` en `AnalyticsService` (con la zona de la app) |
| Vista `v_admin_metricas` y `generate_series` del panel (usuario activo, «hoy» en UTC) | `AdminActivityAggregation.daily` en `AdminMetricsService` |
| Serie semanal, adherencia y minutos de estudio del detalle de usuario (`date_trunc`, `EXTRACT(EPOCH)`, fórmula de adherencia) | `AdminActivityAggregation.weekly` y `AdminUserStats.of` (`adherencePercent`, `studyMinutes`) en `AdminUserQueryService` |
| Orden por XP total con la fórmula de niveles en SQL | Orden por `(nivel, xp_nivel_actual)`, equivalente sin repetir la fórmula de `User` |
| Tipos de estudio escritos a mano `('estudio', 'repaso')` | `ActivityType.codesWhere(ActivityType::countsAsStudy)` como parámetro |
| `NOT EXISTS` que evitaba contar dos veces Pomodoros y repasos | `PracticeSessions.countable` (`focusCounts` / `reviewCounts`) dentro de `StudyActivity.of`, aplicado en `CognitiveStateService` |
| `rpe >= 8` y tipos de publicación excluidos en la insignia | `BadgeActivitySnapshot.HIGH_RPE_MIN` y `AUTOMATIC_POSTS`, enviados como parámetros |
| Horas y días de estudio con `EXTRACT(EPOCH)` y `CAST(… AS date)` en el contexto de entrenamiento | Sumados en Java (`TrainingContextPersistenceAdapter`) |
| Vistas `v_admin_metricas`, `v_analitica_semanal`, `v_ejercicios_completos` | Eliminadas en `V550__portability_drop_business_views.sql` |

**Excepción aceptada:** los filtros de visibilidad y de estado de los listados paginados (muro y búsqueda de usuarios en `SocialQueryJdbcAdapter`, comunidad en `ChallengeAudiencePersistenceAdapter.findCommunity`, `RoutinePersistenceAdapter` y `NotePersistenceAdapter`, estado en `ChallengePersistenceAdapter.findByOwner`) siguen en SQL porque hay que filtrar antes de paginar. Son SQL estándar. Muro, retos, rutinas y apuntes usan `SharedContentSql`, que solo compara columnas con los niveles de `EffectiveVisibility` recibidos como parámetros; la búsqueda de usuarios replica `ContentVisibility.canDiscover` y el estado `Challenge.statusOf`. Un elemento suelto no se filtra en SQL: el adaptador trae `AuthorAudience` y decide el caso de uso. El dominio es la fuente de verdad y los tests de integración (`SharedContentVisibilityIT`, entre otros) fijan su comportamiento.

## 2. Lo que sigue siendo propio de PostgreSQL

Todo está en `backend/src/main/java/com/synaptixfit/infrastructure/adapter/output/persistence/` (rutas relativas a esa carpeta) o en las migraciones. Nada de esto afecta al dominio.

| Qué | Dónde | Por qué no se cambió | Qué haría falta en MySQL 8 |
|---|---|---|---|
| Columnas `jsonb` escritas con `CAST(:x AS jsonb)` y leídas con `::text` | `adapter/admin/AdminAuditJdbcAdapter.java:45, 99, 112`; `adapter/social/ModerationAuditJdbcAdapter.java` (`record`) | El tipo de columna es `jsonb` | `CAST(:x AS JSON)` y `CAST(detalle AS CHAR)`; columna `JSON` |
| Exportación RGPD con `to_jsonb`, `jsonb_build_object`, `jsonb_agg`, `||` | `adapter/privacy/UserDataExportJdbcAdapter.java:53-154` | Construir el JSON en la base de datos es una sola consulta | `JSON_OBJECT` / `JSON_ARRAYAGG`, o mejor reescribirlo en Java (filas → mapas → Jackson) |
| `INSERT … ON CONFLICT DO NOTHING` (concesión idempotente de insignias) | `adapter/badge/BadgePersistenceAdapter.java:59` | En PostgreSQL un error de clave duplicada aborta la transacción: no se puede «insertar y capturar» | `INSERT … ON DUPLICATE KEY UPDATE id = id` |
| `LEFT JOIN LATERAL (…) f ON true` | `adapter/social/SocialQueryJdbcAdapter.java:156` | — | Funciona igual en MySQL ≥ 8.0.14 (no hay que cambiarlo) |
| Búsqueda de texto completo `to_tsvector`/`to_tsquery('spanish')` + índice GIN `idx_ejercicios_fts` | `adapter/training/ExercisePersistenceAdapter.java:64` y `tsQuery`; migración `V1` | No hay equivalente estándar | `MATCH(nombre, descripcion) AGAINST (:q IN BOOLEAN MODE)` con índice `FULLTEXT`, o solo el `LIKE` que ya acompaña |
| Arrays `text[]`, `integer[]`, `uuid[]` | Entidades con `@JdbcTypeCode(SqlTypes.ARRAY)`: `entity/challenge/MilestoneEntity.java:32-34` (`uuid[]`), `entity/notification/NotificationPreferencesEntity.java:22`, `entity/profile/GoalHistoryEntity.java:31`, `entity/profile/WellnessProfileEntity.java:38-46`, `entity/training/DailyCheckInEntity.java:33`, `entity/training/ExerciseEntity.java:30-48`. Lecturas con `rs.getArray`: `adapter/training/ExerciseSqlReader.java:75, 98-100`, `adapter/training/TrainingContextPersistenceAdapter.java:57-58`. Filtro `:purpose = ANY (e.finalidad)`: `adapter/training/ExercisePersistenceAdapter.java:92` | MySQL no tiene arrays | Columnas `JSON` con `@JdbcTypeCode(SqlTypes.JSON)` (`List<String>`), leer con Jackson en los adaptadores JDBC y `JSON_CONTAINS(e.finalidad, JSON_QUOTE(:purpose))` |
| Columnas `jsonb` mapeadas con `@JdbcTypeCode(SqlTypes.JSON)` | `entity/notification/NotificationEntity.java` (`parametros_mensaje`), `entity/academic/QuestionEntity.java:26`, `entity/academic/TestSessionEntity.java:26-32`, `entity/training/ExerciseSelectionEntity.java:42`, `entity/training/RecommendationEntity.java:33` | — | Nada en el código: Hibernate usa `JSON` en MySQL. Solo cambia la migración |
| Tipo `uuid` nativo | Todas las tablas; lecturas `rs.getObject(col, UUID.class)` y `query(UUID.class)` en 13 adaptadores JDBC (36 puntos; helpers `adapter/insights/JdbcRows.java` y `adapter/admin/JdbcValues.java`) y parámetros `UUID` en todos los `JdbcClient` | El driver de PostgreSQL convierte `java.util.UUID` | Columnas `CHAR(36)` (o `BINARY(16)`), `hibernate.type.preferred_uuid_jdbc_type=CHAR` para JPA y, en JDBC, pasar `uuid.toString()` y leer con `UUID.fromString(rs.getString(col))`. Recomendado: centralizarlo en `JdbcRows`/`JdbcValues` y un pequeño helper de parámetros |
| `timestamp with time zone` leído como `OffsetDateTime` | `JdbcRows.instant`, `JdbcValues.instant` y lecturas directas | — | `DATETIME(6)` guardando UTC; URL con `connectionTimeZone=UTC&preserveInstants=true` (Connector/J ≥ 8.0.23). La app ya trabaja siempre en UTC (`hibernate.jdbc.time_zone: UTC`) |
| Columnas generadas `acwr_actual`, `carga_diaria` | Migración `V1` (y `V400`); entidades `CrossRegulationEntity`, `PhysicalLoadEntity` (`insertable = false`) | Se conservan como copia informativa; **la app no las lee** | Omitirlas (y quitar el campo de la entidad) o crearlas con `GENERATED ALWAYS AS (…) STORED` |
| Índices parciales (`WHERE … IS NOT NULL`), `USING btree/gin`, `COMMENT ON`, secuencias `serial`, `gen_random_uuid()`, casts `::`, literales de array `'{…}'` | Migraciones `V1`, `V2` (909 literales de array en el catálogo de ejercicios), `V100`, `V150`, `V300` (`ON CONFLICT`), `V400`, `V450`, `V500`, las generadas `V700`, `V800`, `V850` y `V930` (`ARRAY[…]::text[]`, `CAST(… AS uuid)`, `VALUES` como tabla derivada) y `V940` (expresiones regulares `~` y `substring(… from '…')`, `jsonb_build_object`) | SQL de esquema propio de cada motor | Traducir (apartado 3). Un índice `UNIQUE` de MySQL ya admite varios `NULL`, así que `ux_carga_fisica_sesion` queda como índice único normal |
| `UPDATE … FROM …` (pasar los vínculos de bloque antiguos a `horarios_academicos.hito_id`) | Migración `V1012` | Migración de datos de una sola vez | `UPDATE horarios_academicos b JOIN hitos_de_reto h ON … SET …` |
| `cb.like(…, '\\')` (Criteria API) | `adapter/catalog/AcademicCatalogPersistenceAdapter.java:152` | Hibernate genera el escape según el dialecto | Probar; si falla, usar `'!'` como en `SqlLike` |

## 3. Checklist para cambiar a MySQL 8

1. **Dependencias** (`backend/pom.xml`): añadir `com.mysql:mysql-connector-j` (runtime) y `org.flywaydb:flyway-mysql`. Se pueden dejar las de PostgreSQL mientras convivan los dos motores.
2. **Configuración** (variables, sin tocar `application.yml`):
   ```
   DB_VENDOR=mysql
   DB_URL=jdbc:mysql://<host>:3306/synaptixfit?connectionTimeZone=UTC&preserveInstants=true
   DB_USERNAME=…  DB_PASSWORD=…
   ```
   Hibernate deduce `MySQLDialect` de la URL. Añadir `spring.jpa.properties.hibernate.type.preferred_uuid_jdbc_type: CHAR` (en un `application-mysql.yml` o por variable `SPRING_JPA_PROPERTIES_HIBERNATE_TYPE_PREFERRED_UUID_JDBC_TYPE=CHAR`).
3. **Migraciones:** crear `backend/src/main/resources/db/migration/mysql/` con el esquema final ya consolidado (no hace falta repetir la historia de PostgreSQL): `V1__baseline_schema.sql` traducido desde el estado actual (hasta `V550`) y `V2__seed_catalog.sql`. Las migraciones futuras se añaden en las dos carpetas con el mismo número (> 550). Traducciones:
   - `uuid` → `CHAR(36)`; `DEFAULT gen_random_uuid()` → quitarlo (la app pone los ids) o `DEFAULT (UUID())`.
   - `timestamp with time zone` → `DATETIME(6)`; `DEFAULT now()` → `DEFAULT CURRENT_TIMESTAMP(6)`.
   - `text` → `TEXT` (o `VARCHAR(n)` si lleva índice o `UNIQUE`, p. ej. `email`); `boolean` → `BOOLEAN`; `double precision` → `DOUBLE`; `numeric(p,s)` → `DECIMAL(p,s)`.
   - `jsonb` → `JSON`; `text[]`, `integer[]`, `uuid[]` → `JSON` (y en el seed, `'{a,b}'` → `'["a","b"]'`).
   - `serial`/secuencias → `AUTO_INCREMENT`; índices parciales → índices normales; quitar `USING btree`, `COMMENT ON` (o pasarlo a `COMMENT '…'`) y el índice GIN (sustituirlo por `FULLTEXT`).
   - Columnas generadas: omitirlas (recomendado) o `GENERATED ALWAYS AS (…) STORED`.
   - Los `CHECK` se mantienen (MySQL ≥ 8.0.16 los aplica).
4. **Entidades JPA con arrays** (6 ficheros del apartado 2): `@JdbcTypeCode(SqlTypes.JSON)` y `List<…>` en lugar de arrays. Quitar `columnDefinition = "uuid[]"` de `MilestoneEntity`.
5. **Adaptadores JDBC** con SQL propio (apartado 2): auditoría (`jsonb`), insignias (`ON CONFLICT`), exportación RGPD, búsqueda de ejercicios (FTS y `ANY`), lectura de arrays (`ExerciseSqlReader`, `TrainingContextPersistenceAdapter`) y conversión de `UUID` (helpers + parámetros). Si se quiere mantener los dos motores a la vez, aislar estas diferencias en una pequeña clase por motor elegida con `DB_VENDOR`.
6. **Tests de integración:** hoy usan PostgreSQL embebido (`EmbeddedPostgresSupport`, zonky, sin Docker). Para MySQL, añadir `org.testcontainers:mysql` (requiere Docker) y un `MySqlSupport` equivalente que registre `spring.datasource.*` y `DB_VENDOR=mysql`; ejecutar la misma batería con `./mvnw test -Pintegration` en un perfil `integration-mysql`.
7. **Datos de producción:** exportar cada tabla de PostgreSQL a CSV (`\copy … TO … CSV HEADER`), cargarla en MySQL con `LOAD DATA` (convirtiendo arrays a JSON) y validar los recuentos por tabla. Ajustar `infra/scripts/` (hoy crean un recurso PostgreSQL en Coolify y aplican las migraciones de `db/migration/postgresql`).
8. **Comprobar:** `./mvnw test` (arquitectura y reglas), `./mvnw test -Pintegration` contra MySQL y una pasada manual por inicio, retos, analítica, panel de administración y exportación RGPD.

**Estimación:** 0 ficheros de `domain/` y `application/`. En infraestructura, unos 25-30 ficheros: `pom.xml`, 2 migraciones nuevas, 6 entidades con arrays, ~7 adaptadores con SQL propio y los ~13 adaptadores que leen `UUID` (casi todo mecánico si antes se centraliza la conversión), más el soporte de tests de integración.

## 4. Cómo comprobar que sigue siendo portable

- `cd backend && ./mvnw test`: `ArchitectureTest` falla si el dominio o los casos de uso dependen de JDBC, Hibernate, Flyway o un driver; `DatabaseIndependentRulesTest` fija las reglas que salieron del SQL.
- Al revisar un cambio en `adapter/output/persistence/`, buscar sintaxis nueva propia de PostgreSQL:
  ```
  grep -rniE "filter \(where|ilike|nulls last|date_trunc|generate_series|at time zone|extract\(epoch|::(date|text|int|numeric|jsonb)" backend/src/main/java
  ```
  Si aparece algo, o se reescribe en SQL estándar o se añade a la tabla del apartado 2.
