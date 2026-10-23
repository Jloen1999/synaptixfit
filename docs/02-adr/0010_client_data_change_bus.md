# 0010. Refrescar las pantallas del cliente con un bus de cambios de datos

* **Estado:** Aprobado
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
Las acciones del usuario no son independientes: terminar un entrenamiento cambia la XP, el nivel, la racha, los retos de fitness, las insignias y la carga física; completar un bloque de estudio cambia la carga cognitiva y los retos vinculados. En el backend esto se resuelve con eventos de dominio (ADR 0005), pero en el cliente las 5 pestañas viven a la vez (`StatefulShellRoute`) y cada bloc solo cargaba al crearse o al volver de una pantalla abierta con `await context.push`. Ese refresco fallaba con `pushReplacement` y `go`, y Inicio y Progreso competían por celebrar las mismas insignias.

## Decisión
- `DataChangeInterceptor` (capa data, Dio) traduce cada escritura correcta (POST, PUT, PATCH, DELETE) a las áreas (`DataTopic`) que toca, según el prefijo de su ruta, y agrupa las ráfagas en un aviso.
- El dominio lo expone con `DataChangeRepositoryContract` y `WatchDataChangesUseCase`.
- El bloc de cada pestaña (Inicio, Académico, Rutinas, Mis retos y Comunidad, Progreso) recibe `WatchDataChangesUseCaseContract` por inyección, se suscribe en `started` a los temas que muestra (`DataChangeRefreshMixin`) y, ante un cambio, se envía su propio `refreshed` (recarga silenciosa). La suscripción se cancela en `close()`: la gestiona el coordinador de estado, no un widget que resuelva dependencias de la raíz de composición.
- `AchievementsBloc`, en el armazón de pestañas, escucha `DataTopic.gamification`: recarga la cuenta, detecta subidas de nivel y celebra una sola vez las insignias no celebradas (`GET /badges/unnotified`). Las otorga el servidor al procesar cada acción; el cliente nunca llama a `/badges/evaluate`.

## Consecuencias
* **Positivas:** ninguna acción nueva se olvida de avisar (basta con que su ruta esté en el mapa); los blocs no cambian; las pestañas en segundo plano están siempre al día; una sola celebración de logros.
* **Negativas:** alguna recarga de más (una pestaña puede refrescarse por un cambio que no le afecta del todo); el mapa ruta → áreas hay que mantenerlo al añadir prefijos de API; las escrituras que se hacen al refrescarse (`POST /badges/notified`) deben quedar excluidas para no crear bucles (`/badges/evaluate` sigue excluida por seguridad).
