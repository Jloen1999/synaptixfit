# 0005. Comunicar módulos del backend con eventos de dominio síncronos

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
En Supabase, varios triggers modificaban tablas de otros módulos (completar una entrega completaba el reto vinculado y viceversa; completar una sesión insertaba carga física). Llevar esas dependencias a llamadas directas entre servicios crearía ciclos (planificador ⇄ gamificación).

## Decisión
Los módulos publican eventos de dominio (`domain/event/`) con `DomainEventPublisherPort`; los oyentes son adaptadores de entrada (`infrastructure/adapter/input/event/<feature>/`) que llaman a un caso de uso de su módulo. Se publican de forma síncrona dentro de la misma transacción y los oyentes son idempotentes. Catálogo en `docs/01-architecture/events.md`. Cada tabla tiene un único módulo propietario; las lecturas de tablas ajenas se hacen con `JdbcClient` en el adaptador.

## Consecuencias
* **Positivas:** sin ciclos de dependencias; consistencia transaccional como con los triggers; reglas visibles y testeables.
* **Negativas:** el flujo completo de una acción se reparte entre varios módulos; hay que mantener el catálogo de eventos.
