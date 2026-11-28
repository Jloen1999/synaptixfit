# ADR 0066 — «Tú» sin el resumen de Inicio al entrar, «Ahora no» que dura y detalle de plantilla

- **Fecha:** 2026-11-28
- **Estado:** aceptado
- **Completa:** ADR 0038 («Tu equilibrio» en Tú), ADR 0041 («Ver más cifras»), ADR 0043 (plantillas) y el mapa de
  `DataChangeInterceptor` (datos al día entre pantallas).

## Contexto

1. **«Tú» tardaba al entrar.** Tú › Resumen lanzaba 9 peticiones a la vez: las 8 de `GetProgressOverviewUseCase` y el
   resumen entero de Inicio (`GET /dashboard`) solo para la tarjeta «Tu equilibrio», que además va plegada en «Ver más
   cifras». Medido con un IT temporal (PostgreSQL embebido, consultas contadas en el `DataSource`): el resumen de Inicio
   hace **59 de las 99 consultas** de entrar (60 %) y es la petición más lenta (293 ms en frío, 59-72 ms en caliente,
   frente a 6-29 ms de las demás). Las otras pestañas de «Tú» no se construyen hasta que se abren (`TabBarView`).
2. **«Ahora no» no escondía «Termina de preparar tu app».** El plazo se guarda en el teléfono por cuenta, pero Inicio
   mandaba `started(userId: '')` mientras la política legal estaba sin comprobar (arranque en frío, recarga en la web):
   el «Ahora no» se escribía o leía con la clave de una cuenta vacía y, al recargar, la de la cuenta real no lo tenía.
   Además, una recarga que leyó antes de pulsarlo devolvía el aviso sin plazo.
3. **Plantillas sin detalle.** Solo se podía usar una plantilla a ciegas.

## Decisión

- **«Tu equilibrio» se pide al desplegar «Ver más cifras»** (`ProgressOverviewEvent.balanceRequested`,
  `ProgressOverviewLoaded.loadingToday`); desde entonces las recargas también lo leen. Entrar en «Tú» baja de 9 a 8
  peticiones y de 99 a 40 consultas. Sin endpoint nuevo: se reutiliza `GetHomeDashboardUseCase`.
- **El «Ahora no» sigue en el teléfono y por cuenta** (es una preferencia de este aviso en este dispositivo, no una
  regla de negocio), pero Inicio manda siempre la cuenta de la sesión (`HomeDashboardEvent.started(userId,
  checkOnboarding)`): lo que espera a la política es solo la comprobación del onboarding. Al recargar se conserva el
  plazo más reciente (`_withLatestSnooze`).
- **Prefijos que faltaban en `DataChangeInterceptor`:** `/api/v1/exercises` («Tu nota», `training`),
  `/api/v1/admin/social` (moderar el muro, `social`) y `/api/v1/admin/exercises` (catálogo, `training`).
- **Detalle de plantilla:** `GET /api/v1/training/templates/{id}` (`GetRoutineTemplateUseCase`,
  `RoutineTemplateDetailService`): la tarjeta (`summary`), cada día con sus ejercicios (nombre, foto, series,
  repeticiones o rango, aguante y descanso de una semana de carga) y los días de carrera con su entreno. Una plantilla
  retirada, vacía o inexistente es 404 `ROUTINE_TEMPLATE_NOT_FOUND` (el mismo que al usarla). En el cliente,
  `/training/templates/:id` (pantalla completa, `RoutineTemplateDetailPage`): toda la tarjeta de la lista lo abre y
  «Usar esta plantilla» sigue también en la lista; el aviso tras usarla es uno solo (`announceTemplateUsed`).

## Consecuencias

- Quien despliega «Ver más cifras» espera un momento a «Tu equilibrio» (esqueleto en su sitio).
- El «Ahora no» no viaja a otros dispositivos: si hiciera falta, iría a la cuenta en el servidor.
