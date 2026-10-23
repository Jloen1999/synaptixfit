# 0012. Reglas de negocio independientes de la base de datos

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
El propietario quiere poder cambiar PostgreSQL por MySQL en el futuro con cambios mínimos. Una auditoría del SQL del backend encontró reglas de negocio escondidas en la base de datos o en consultas, además de sintaxis propia de PostgreSQL:

- El progreso de los retos del inicio se calculaba con un `CASE` en SQL que duplicaba `Challenge.progress()` (y ya divergía: sumaba también el progreso de las tareas).
- Vistas con cálculos de negocio: `v_admin_metricas` (qué es un usuario activo, «hoy» en UTC), `v_analitica_semanal` (semanas, RPE medio) y `v_ejercicios_completos` (sin uso).
- La carga física se sumaba con la columna generada `carga_diaria` (RPE × minutos), aunque la fórmula ya estaba en `PhysicalLoadRecord`.
- Fórmulas y umbrales dentro del SQL: adherencia académica, XP total para ordenar usuarios, RPE ≥ 8 de la insignia, tipos de publicación que no cuentan, deduplicación de Pomodoros y repasos con `NOT EXISTS`.
- Sintaxis no portable: `FILTER (WHERE …)`, `ILIKE`, `NULLS LAST`, `EXTRACT(EPOCH …)`, `date_trunc`, `generate_series`, `AT TIME ZONE`, `::` casts.

## Decisión
1. **La base de datos solo guarda y devuelve datos.** Toda regla (fórmula, umbral, clasificación, agrupación con significado) vive en el dominio y la aplican los casos de uso, en Java puro y con tests unitarios. Los puertos de salida devuelven **filas sin agregar** (traídas con SQL estándar) y es el servicio de aplicación quien llama al dominio; así los tests de los servicios ejercitan la regla con dobles que solo guardan filas. La zona horaria también la decide el caso de uso (se inyecta en el servicio, no en el adaptador):
   - Retos del inicio → `DashboardService` con `ListMyChallengesUseCase` + `Challenge.progress()` (`ActiveChallenge.of`).
   - Recuento de retos por estado → `Challenge.statusOf` + `ChallengeSummary.of`.
   - Visibilidad de un reto ajeno → el adaptador trae `OwnerAudience` y decide `Challenge.isVisibleTo`.
   - Carga física → los puertos devuelven `PhysicalLoadHistory.Entry` y `TrainingLoadService` (ACWR, serie de 28 días, máximo diario) y `StudyMaterialService` (fatiga del SM-2) aplican `PhysicalLoadHistory` (con `PhysicalLoadRecord.load(rpe, minutos)`).
   - Analítica semanal → `AnalyticsSourcePort` devuelve `CompletedSession` y `AnalyticsService` aplica `WeeklyTrainingMetric.byWeek` en la zona de la app.
   - Panel de administración → los puertos devuelven recuentos (`PlatformCounts`, `AdminUserCounts`) y filas (`UserActivity`, `UserFocus`, `StudyInterval`, `StudyWeek`, `CompletedSession`); `AdminMetricsService` y `AdminUserQueryService` aplican `AdminActivityAggregation` (usuario activo, series diarias y semanales, adherencia, minutos de estudio).
   - Prácticas sin bloque → `InsightsSourcePort.practiceLog` devuelve las filas (con `insideCompletedBlock` y `materialId`) y `CognitiveStateService` aplica `PracticeSessions.countable` dentro de `StudyActivity.of`, la definición única de actividad de estudio (`GetStudyActivityUseCase`), que usa también el inicio.
   - Umbrales de insignias → constantes de `BadgeActivitySnapshot`, que llegan al SQL como parámetros (igual que los tipos de `ActivityType`).
   - Fechas → las pone siempre la aplicación, también en las sentencias directas (p. ej. `UserDataErasurePort.wipeContent(userId, at)`); nada de `now()` en SQL.
2. **Las vistas con lógica se eliminan** (`V550__portability_drop_business_views.sql`). Las columnas generadas `acwr_actual` y `carga_diaria` se mantienen como copia informativa, pero la aplicación no las lee.
3. **SQL estándar en los adaptadores** siempre que sea barato (`SUM(CASE …)`, `lower(col) LIKE … ESCAPE '!'` con `SqlLike`, `CASE WHEN col IS NULL` para ordenar, fechas restadas en Java). Lo que no es barato de portar (`jsonb`, arrays, búsqueda de texto completo, `ON CONFLICT`, `LATERAL`, `uuid` nativo) queda **aislado en adaptadores de persistencia** y listado en `docs/06-ops/database_portability.md`.
4. **Excepción aceptada:** los filtros de visibilidad y de estado de los listados **paginados** (muro, retos, rutinas y apuntes de la comunidad, `findByOwner` por estado) se expresan en SQL estándar porque hay que filtrar antes de paginar. Replican la regla del dominio (`ContentVisibility`, `Challenge.isVisibleTo`, `Challenge.statusOf`), que sigue siendo la fuente de verdad, y los tests de integración fijan su comportamiento.
5. **Configuración por motor:** `DB_VENDOR` (por defecto `postgresql`) elige la URL por defecto y la carpeta de migraciones `db/migration/<DB_VENDOR>`. El driver y el dialecto de Hibernate se deducen de la URL.
6. **Verificación automática:** `ArchitectureTest.coreIsDatabaseAgnostic` impide que el dominio o los casos de uso dependan de `java.sql`, `javax.sql`, Hibernate, Flyway o drivers.

## Consecuencias
* **Positivas:** las reglas se prueban sin base de datos y no pueden divergir entre SQL y Java; pasar a MySQL afecta solo a infraestructura (adaptadores de persistencia, entidades con tipos especiales, migraciones y configuración); el progreso de los retos del inicio vuelve a coincidir con el de la pantalla de retos.
* **Negativas:** algunas agregaciones traen más filas a la aplicación (historial de carga física de un usuario, actividad diaria del panel en el periodo elegido); con los volúmenes actuales es despreciable, pero si crecen habrá que paginar o cachear. Los filtros paginados de visibilidad siguen duplicados en SQL (punto 4).
