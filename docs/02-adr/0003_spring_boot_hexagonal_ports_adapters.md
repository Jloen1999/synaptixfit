# 0003. Usar Spring Boot hexagonal (puertos y adaptadores) en el backend

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
Se sustituye Supabase por un backend propio (ADR 0004) y hace falta un stack con perfil aprobado.

## Decisión
Backend en `backend/` con el perfil `backend-spring-hexagonal`: Java 21, Spring Boot 4.1 (Web MVC, Data JPA, Security resource server), PostgreSQL 17 con Flyway, springdoc-openapi para generar la especificación y ArchUnit para la regla de dependencia. `domain` y `application` sin anotaciones de Spring; la composición vive en `infrastructure/config/*BeanConfiguration` y las transacciones se aplican envolviendo cada caso de uso (`TransactionalUseCaseFactory`), de modo que la capa de aplicación no conoce Spring.

## Consecuencias
* **Positivas:** lógica de negocio en Java puro probada sin contexto de Spring; OpenAPI generado; seguridad y errores centralizados.
* **Negativas:** hay que operar un servicio y una base de datos propios.
