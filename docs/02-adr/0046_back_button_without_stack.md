# ADR 0046 — Flecha «Volver» con padre: ninguna pantalla sin salida

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

`AppBar` solo pinta la flecha si go_router tiene a dónde volver. Una pantalla completa de primer nivel abierta sin pila (un aviso del móvil con `RemindersHost`, un enlace `/training/shared/<token>`, una redirección como `/challenges`, recargar en web) se quedaba sin flecha, y los `context.pop()` de sus salidas (guardar, borrar, descartar) fallaban con «There is nothing to pop». Las rutas anidadas (`/profile/*`, `/admin/*`, las hijas de `/training`) no lo sufren: go_router monta el padre debajo también en frío.

## Decisión

- Un solo widget, `AppBackButton(fallback:)` (`presentation/widgets/`), como `leading` de toda pantalla que no es pestaña. Hace `Navigator.maybePop` (respeta `PopScope`: cambios sin guardar, «Pausar y salir…») y, si nadie lo retiene y no hay pila, `go(fallback)`.
- `fallback` es la pantalla de la que cuelga: una pestaña o una pantalla completa cuya flecha acaba en una pestaña (detalle de sesión → historial, reto → Progreso › Retos, sala → «Con amigos» → Progreso › Retos, asignatura → Académico).
- Es la única excepción a «nada de `go` hacia una pantalla completa» (`frontend/CLAUDE.md`): sin pila el armazón de pestañas ya no está montado y `go` no destruye nada.
- Las salidas tras guardar, borrar o descartar usan `context.popOrGo(padre, resultado)`.
- Sin flecha a propósito: las 5 pestañas, la aceptación legal, el onboarding (su flecha va al paso anterior), los permisos iniciales y la sesión terminada, cada una con su botón para seguir. El editor de rutina y los editores de la generación llevan «Cerrar».
- La misma flecha de Material (`AppIcons.back`) en todas las plataformas, también en iOS.

## Consecuencias

- **Positivas:** ninguna pantalla se queda sin salida; un solo sitio decide cómo se vuelve; `back_button_routes_test.dart` recorre la tabla de rutas entera (cada barra de cada página lleva la flecha) y abre en frío los casos principales.
- **Negativas:** el padre se escribe a mano en cada pantalla. El «atrás» del sistema de Android sin pila sigue cerrando la app. El detalle de una sesión abierto sin pila oculta «Corregir / Reabrir / Eliminar», porque esas acciones las ejecuta el historial al volver. Las dos cosas se resolvieron en el ADR 0047 (sección 4).
