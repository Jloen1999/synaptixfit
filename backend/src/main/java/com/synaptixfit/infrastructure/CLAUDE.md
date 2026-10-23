# Capa infrastructure (Spring)

Rol: adaptadores de entrada y salida, composición y traducción de errores HTTP.

- Aquí sí se permiten Spring, JPA y librerías externas.
- `adapter/input/rest/<feature>/` → controllers y DTOs (`record`). El controller llama al puerto de entrada y mapea dominio → DTO. Sin lógica de negocio.
- `adapter/input/rest/error/GlobalExceptionHandler` → `DomainException` → `ProblemDetail` con `code`. El estado HTTP de cada `code` va en `STATUS_BY_CODE`.
- `adapter/output/persistence/` → `entity/`, `repository/`, `mapper/`, `adapter/`. Las `@Entity` nunca salen de aquí.
- SQL de los adaptadores: solo trae datos, sin reglas (fórmulas, umbrales, estados, agrupaciones con significado van al dominio; los valores de una regla llegan como parámetros, p. ej. `ActivityType.codesWhere`). SQL estándar: `SUM(CASE …)` en vez de `FILTER`, `SqlLike` en vez de `ILIKE`, fechas restadas o truncadas en Java. Lo inevitablemente propio de PostgreSQL se lista en `docs/06-ops/database_portability.md` (ADR 0012).
- `adapter/output/external/` → clientes de otros servicios. Traducen sus errores a excepciones de dominio.
- `config/BeanConfiguration` → raíz de composición: registra cada caso de uso contra su contrato.
- Respuestas de éxito con DTO directo. Nada de `ApiResponse<T>`.
