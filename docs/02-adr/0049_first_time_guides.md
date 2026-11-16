# ADR 0049 — Guías la primera vez

- **Fecha:** 2026-11-16
- **Estado:** aceptado (plan de la Fase 2B aprobado por el propietario)

## Contexto

Fase 2B del plan de mejoras. Las pantallas con más partes (sesión en vivo, Inicio, Calendario, Gimnasio,
Concentrarme, Académico y la ficha de asignatura) se entienden mejor si alguien te dice, una sola vez, dónde está lo
importante. Hasta ahora había ayudas opcionales («?», `AppHelpToggle`) que hay que descubrir, y textos largos que el
propietario quiere evitar. Un principiante (estudiante que abre la app por primera vez) no debería tener que adivinar
que la foto del ejercicio abre «Cómo se hace» o que un día de «Tu semana» abre el calendario.

## Decisión

### Qué ve la persona

- **`AppGuideTour`** (`presentation/widgets/app_guide_tour.dart`, `showAppGuideTour`): oscurece todo menos la parte
  señalada (velo `TokensOpacity.guideScrim` con un aro del color principal alrededor del hueco) y, junto a ella, una
  tarjeta con **título + una frase**, **«Saltar guía»** (nunca «Saltar» a secas, `vocabulario.md`) y **«Siguiente (n
  de N)»**; en el último paso, **«Entendido»** (sin «Saltar guía»). Es la única excepción a «nada de diálogos de cómo
  funciona» (`vocabulario.md`). 2 a 4 pasos. La tarjeta va debajo de la parte si cabe, si no encima y, si tampoco (letra al 200 % o parte
  muy alta), abajo del todo; nunca más ancha que un formulario (`TokensLayout.formMaxWidth`) y con su contenido
  desplazable. Con letra grande, los botones van uno debajo del otro.
- **Accesibilidad:** va en el navegador raíz como un diálogo (la barrera bloquea la semántica de debajo); la tarjeta
  se nombra «Guía, paso 1 de 3: Tu día» (`scopesRoute`, `namesRoute`), el foco va a su botón principal en cada paso y
  cada paso nuevo se anuncia entero. Se cierra también con «atrás» o Escape. Sin animaciones con «reducir
  movimiento» (aparición y desplazamiento instantáneos). Tocar fuera no la cierra (se perdería sin querer).
- **Cuándo sale:** la primera vez que se entra en la pantalla, cuando ya tiene su contenido (no cargando ni con error)
  y no tiene nada encima (otra pantalla, hoja o diálogo; también la celebración de insignias). Si la visita la abrió
  **un aviso del móvil** (`RemindersHost`) o la propia app al abrir la sala o el entreno en marcha
  (`TogetherLiveHost`), **espera a la próxima vez**. El Calendario también espera si se abrió para enseñar un evento o
  añadir uno (`?block=`, `?new=`). Cerrarla de cualquier forma (terminada, «Saltar guía», «atrás») cuenta como vista.
- **Ajustes › Ayuda › «Ver las guías otra vez»**: las olvida para la cuenta; vuelven a salir al entrar en cada
  pantalla.

### Pasos

| Pantalla (`GuideId`) | Pasos |
|---|---|
| Sesión en vivo (`liveSession`, solo con rutina) | Empezar serie · Cómo se hace (la foto) · Tiempo haciendo series (⏱) · Cambiar cifras (fila que toca) |
| Inicio (`home`) | Tu día · Tu semana (toca un día) |
| Calendario (`calendar`) | Añadir al calendario · Marcar como hecho (el lienzo) · Entregas y exámenes |
| Gimnasio (`gym`) | Tu próximo entreno · Mis rutinas (y «Nueva rutina») · Plantillas listas; sin rutinas, «Tu entreno de hoy» y la tarjeta con los botones para crear la primera |
| Concentrarme (`focus`, antes de empezar) | Empezar a concentrarme · Qué estudias (si hay selector) · Cuántos minutos · Estudiar con amigos |
| Académico (`academic`) | Añadir (también preguntas y tarjetas con IA) · Repasos pendientes · Buscar |
| Asignatura (`subject`) | Progreso · Apuntes y archivos · Practicar (simulacro) |

Un paso cuya parte no está pintada (p. ej. sin repasos pendientes o sin «Tu semana») se salta y no cuenta en «n de N».

Ajustes respecto al plan: Inicio **no tiene buscador** (el único buscador es el de Académico, ADR 0036), así que su
guía tiene dos pasos; «Generar con IA» de Académico no tiene botón propio (está dentro de «Añadir»), así que va en la
frase de «Añadir» en vez de repetir el mismo hueco dos veces.

### Arquitectura

- **Dominio:** `GuideId` (enum; su nombre se guarda: no se renombra un valor publicado), contrato
  `GuideProgressRepositoryContract` (`seen`, `markSeen`, `reset` por cuenta) y tres casos de uso:
  `ShouldShowGuideUseCase` (sin cuenta, no), `MarkGuideSeenUseCase` y `ResetGuidesUseCase`.
- **Datos:** en el teléfono, por cuenta (`GuideProgressStorage`, `shared_preferences`, clave
  `sfx_guides_seen_<cuenta>` con los nombres vistos), como «Permisos» (ADR 0034) o el «Ahora no» de Inicio. Por qué
  no en el servidor: es una comodidad del dispositivo; verla otra vez en un móvil nuevo no hace daño y evita tabla,
  migración, endpoint y exportación de datos. Si no se puede leer, no se enseña (no es imprescindible); si no se
  puede guardar, saldrá otra vez.
- **Presentación:** `GuideTourBloc` (uno por pantalla: `requested` → `showing`/`done`; `closed` → `saving` → `done`;
  `abandoned` si no hay nada que señalar) y el anfitrión **`FirstTimeGuide`** (`screens/shell/widgets/`), que envuelve
  la pantalla con `guide`, `ready` y sus pasos. Lo común lo da **`GuideCoordinator`**, puesto con `GuideScope` sobre
  el navegador en la app raíz: crea el bloc, cuenta diálogos y hojas del navegador raíz (observador que se pasa a
  `GoRouter`) y recuerda si una pantalla se abre desde fuera (`markExternalArrival`; cuenta lo que se abre en los
  5 s siguientes). La pantalla visible se sabe por `TickerMode` (pestaña activa) y `ModalRoute.isCurrent`. Sin
  `GuideScope` (tests de pantalla) no sale ninguna guía.
- **Claves, no posiciones:** cada paso señala su parte por una `GlobalKey` que la pantalla pone en esa parte. Gimnasio
  se rediseñará en la fase 3: basta con mover cada clave (`_GymGuideKeys`) con su parte.

## Consecuencias

- Una pantalla nueva con guía: valor en `GuideId`, claves en sus partes, `FirstTimeGuide` en la página (montado desde
  el principio, para saber cómo se llegó) y sus textos `guide<Pantalla>…Title/Body` en los cuatro idiomas.
- Si se borra o se mueve una parte, su paso se salta solo; `guides_wiring_test.dart` comprueba que cada pantalla
  monta su guía y que los avisos la aplazan.
- Los textos dicen lo que hay de verdad en ese momento: con la pantalla vacía (sin rutinas, semana sin eventos) el
  paso describe lo que saldrá ahí, no un botón que aún no existe.
- Pruebas: casos de uso y repositorio, `GuideTourBloc`, `AppGuideTour` (pasos, «Saltar guía», «atrás», foco, lector,
  letra al 200 %) y `FirstTimeGuide` (una vez, espera a cargar, a que se cierre un diálogo y a la siguiente visita si
  vino de un aviso).
