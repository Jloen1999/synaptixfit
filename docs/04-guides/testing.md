# Tests

| Qué | Dónde | Cómo |
|---|---|---|
| Regla de dependencia (backend) | `backend/src/test/.../architecture/ArchitectureTest.java` | ArchUnit, en cada `./mvnw test` |
| Dominio y servicios (backend) | `backend/src/test/.../domain`, `.../application` | JUnit 5 + AssertJ; servicios con `new` y dobles de los puertos, sin Spring |
| Integración (backend) | `*IT.java` | App completa sobre PostgreSQL embebido (zonky, sin Docker) con MockMvc: valida Flyway, mapeo JPA, seguridad y contrato de errores. `./mvnw test -Pintegration` |
| Regla de dependencia (cliente) | `frontend/test/architecture/dependency_rule_test.dart` | Revisa los imports de cada capa |
| Traducción de errores (cliente) | `frontend/test/data/errors/` | Unitarios del `ErrorMapper` |
| Blocs (cliente) | `frontend/test/presentation/` | `bloc_test` + `mocktail` sobre los contratos de los casos de uso |

Criterios:

- Cada servicio del backend tiene su test unitario con las reglas de negocio, la propiedad de los recursos (404 si es ajeno), el XP y los eventos publicados.
- Cada módulo del backend tiene al menos un `*IT` con su flujo principal.
- Los tests no llaman a servicios reales (DeepSeek, R2, Google): esos puertos se sustituyen por dobles.
