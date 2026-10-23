# Capa application (Spring)

Rol: casos de uso (puertos de entrada) y su orquestación.

- Solo depende de `domain`. Prohibido Spring, JPA e `infrastructure`. `ArchitectureTest` lo comprueba.
- Sin anotaciones (`@Service`, `@Component`, `@Transactional`…). El registro se hace en `infrastructure/config/BeanConfiguration`.
- `port/input/<feature>/` → un contrato por intención (`GetProductsUseCase`).
- `service/<feature>/` → implementaciones. Un servicio puede implementar varios contratos de la misma feature.
- Dependencias por constructor, siempre contra puertos.
- Cada servicio se prueba con `new` y mocks de los puertos, sin contexto de Spring.
