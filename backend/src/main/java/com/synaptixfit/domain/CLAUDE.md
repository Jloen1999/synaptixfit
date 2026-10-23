# Capa domain (Spring)

Rol: modelos de dominio, errores de dominio y puertos de salida. Es el centro.

- Java puro. Prohibido importar `org.springframework.*`, `jakarta.persistence.*`, `application` o `infrastructure`. `ArchitectureTest` lo comprueba.
- Las reglas de negocio viven en los modelos (validación en el constructor).
- Los errores son subclases de `DomainException` con un `code` del catálogo `docs/03-api/errors.md`. Nunca `IllegalArgumentException` ni excepciones genéricas.
- El dominio no conoce HTTP: el estado de cada `code` se decide en `infrastructure`.
- Puertos de salida en `port/output/`, con el sufijo `Port`.
