# ADR 0065 — Jerarquía de botones, nodos propios para el lector y pendientes de la revisión UX

- **Fecha:** 2026-11-25
- **Estado:** aceptado (plan UX del 19 nov 2026, tanda 6 «Botones que parecen botones»; referencia visual: fila de
  botones al final de la maqueta `inicio-calendario.html`). Revisado el mismo día tras la revisión de arquitectura y
  diseño (contraste del borde, botones rojos a mano, filas que no cabían a 320 px, «Ir a la clase»).
- **Completa:** ADR 0059 (una sola acción principal en Inicio), ADR 0060 (ficha del evento), ADR 0061 (tarjetitas de
  «Tú» y del perfil) y ADR 0064 (`Semantics` con `onTap`).

## Contexto

La revisión del 19 nov encontró acciones que eran texto de color suelto («Sin temario: importa la guía», «Ver N más»,
«Añadir detalles», «Descartar sesión», «Hoy»…): un principiante no las reconoce como botones. Borrar, descartar y
bloquear eran a veces texto rojo pegado a otras acciones. Además salió dos veces la misma clase de fallo para el lector
de pantalla: un `Semantics(button: true, excludeSemantics: true)` sin `onTap` (anuncia un botón que no se puede pulsar)
y elementos de una tira o lista con `Semantics(label: …)` sin `container: true` (el primero se fundía con su padre:
«Esta semana», las insignias del perfil público).

## Decisión

### Cuatro formas de botón (cliente)

| Papel | Forma | Widget |
|---|---|---|
| **Principal** (una por pantalla u hoja) | Relleno, color de marca | `AppPrimaryButton` / `FilledButton` |
| **Secundario** | Tonal (`primaryContainer`) | `AppSecondaryButton` / `FilledButton.tonal` |
| **Otra opción** | Fondo `surface`, borde `buttonOutline` (3:1), texto `onSurface` | `OutlinedButton` y **también `TextButton`** (tema) |
| **Eliminar** (borrar, descartar, bloquear, quitar datos) | Borde y texto rojos, aparte de las demás | `AppDangerButton` |

- **«Otra opción» se ve como botón en cualquier fondo.** Como `.btn-o` de la maqueta, `outlinedButtonTheme` y
  `textButtonTheme` llevan fondo `surface` y el borde `buttonOutline`, que sube a `#767D8A` (claro) y `#7C8496`
  (oscuro): al menos 3:1 frente a la superficie, el fondo y todos los `*Container` (WCAG 1.4.11). Con el borde de
  antes (`#D1D5DB`, ≈1,5:1) un botón sobre una tarjeta tintada se leía como texto en negrita suelto («Terminar» en el
  panel de descanso, «Ver las N» en las solicitudes). El token también afecta al borde de los chips sin elegir, que
  gana contraste.
- **`TextButton` = «Otra opción» compacta** (161 en la app): mismo aspecto que el botón con borde, relleno lateral
  corto y 48 dp de alto, sin tocar cada pantalla. Con el foco de teclado, el anillo común (`onSurface`, 2 px, por
  fuera) sustituye al borde.
- **Forma:** rectángulo con el radio de media altura de una línea (`controlHeight / 2`; los compactos,
  `minTouchTarget / 2`) en vez de `StadiumBorder`: con una línea es la misma píldora y, si el texto se parte (200 %,
  poco ancho), queda un rectángulo redondeado y no un óvalo. Las opciones de dos líneas de la hoja «¿Salir sin
  terminar?» usan `TokensRadius.m`.
- **`AppDangerButton`** (`widgets/app_danger_button.dart`): `OutlinedButton` con texto y borde `error`, papelera por
  defecto (`icon: null` para solo texto), anillo de foco como el resto. El verbo va escrito: el rojo nunca es la única
  señal. Va en su propia línea o al final, separado de la acción principal; en un diálogo, al final. `styleOf` da el
  mismo estilo a un botón con otro contenido (el del panel de administración, con su indicador de carga).
- **Diálogos:** la opción segura o la que confirma es rellena; «Cancelar» sigue siendo `TextButton` (con borde, como
  cualquier «Otra opción»). Los diálogos con tres salidas (retirar el permiso de salud, desactivar «Mi ciclo») van en
  el mismo orden: Cancelar (borde) · Conservar (relleno) · Borrar (`AppDangerButton`).
- **Excepción: confirmar un borrado en un diálogo.** Cuando el diálogo pregunta «¿Eliminar…?», su acción principal es
  borrar: va **rellena en rojo** (`AppDangerButton.confirmStyleOf`, un solo sitio: `showConfirmDialog(destructive:)`,
  diálogos de social, administración, retos, grados, cuenta y académico) y el foco inicial va a «Cancelar». Fuera de un
  diálogo, borrar nunca es relleno (el «Retirar contenido» del panel de reportes pasa a `AppDangerButton.styleOf`).
- **Una sola rellena por pantalla:** en Asignatura › Resumen, con repasos para hoy «Repasar» es la principal y
  «Concentrarme» pasa a tonal; sin repasos, «Concentrarme» es la principal. «Hecho» del editor de resúmenes de la IA,
  única acción de su pantalla, pasa a relleno (como «Guardar» del editor de apuntes). «Acciones» de cada fila de
  material pasa de tonal a con borde (una lista llena de tonales competía con la acción principal).

Cambiados a mano (además del tema): a `AppDangerButton`, «Eliminar» de la ficha del calendario (se borra su
`_DeleteButton`), «Quitar» de «Ayer quedó sin marcar», «Descartar» de «Sin terminar», «Eliminar sesión» del detalle,
«Eliminar entrega», «Bloquear» del perfil público, «Borrar todo» y «Borrar historial» de «Mi ciclo», «Borrar nota» del
ejercicio, «Descartar sesión» (hoja de salir y tarjeta de sesión abierta), «Eliminar entreno» de Correr, «Eliminar
plan» semanal y «Borrar registros» del permiso de salud (14), y el botón destructivo del detalle de usuario del panel
(`styleOf`); a tonal, «Sin temario: importa la guía» y «Estudiar con amigos» del Pomodoro; a relleno, «Guardar» al
cambiar una respuesta revisada, «Conservar» en los dos diálogos de tres salidas y «Hecho» del editor. «Ver las N»
solicitudes deja su estilo propio y usa el del tema.

### Filas texto + botón (320 px y texto al 200 %)

`AppTextWithAction` (`widgets/`) pone el botón al lado del texto solo si al texto le queda al menos lo que ocupa el
botón (medido con `context.buttonWidth` y el estilo real); si no, el botón baja a su línea, alineado al final. Lo usan
la asignatura de la ficha del calendario («Abrir asignatura»), «Lo próximo» de la asignatura («Calendario») y la barra
de la sesión libre («Terminar»).

### Excepciones (siguen siendo texto)

- **La acción de un aviso** (`SnackBarAction`: «Deshacer», «Ver», «Reintentar»): Flutter le pone su propio
  `TextButtonTheme` dentro del `SnackBar`, sin contorno y en el color de acción del aviso. Es el patrón que se reconoce
  en Android e iOS y el aviso ya se distingue del contenido. Lo comprueba `button_hierarchy_test.dart`.
- **Enlaces dentro de una frase**: no hay ninguno hoy como `TextButton`; si aparece, va como texto enlazado de la frase,
  no como botón.

### Que no vuelva (tests)

- `test/presentation/widgets/button_hierarchy_test.dart`: el tema de `TextButton` tiene contorno visible en claro y
  oscuro (y el anillo de foco es más grueso), «Otra opción» lleva fondo `surface` y texto `onSurface`, los botones del
  tema no son `StadiumBorder`, la acción de un aviso no hereda el contorno, `AppDangerButton` es rojo y se pulsa, las
  tarjetitas y los chips de día son nodos propios y el cuadradito usa los colores de contenedor.
- `test/presentation/theme/text_button_style_test.dart` (lee el código de `lib/presentation`):
  - ningún `*.styleFrom(` ni `OutlinedButton(` usa el color de error (`colors.error`, `colorScheme.error`, una
    variable `error`) fuera del tema y de `app_danger_button.dart`;
  - ningún `TextButton` quita su borde (`BorderSide.none`), ningún `TextButton.styleFrom` lleva `side:` (salvo
    `null`, que no toca el tema) y no hay `TextButtonTheme(` locales;
  - todo `Semantics(button: true, excludeSemantics: true)` lleva `onTap:`.
- `test/presentation/theme/contrast_test.dart`: el borde de botón a 3:1 sobre `surface`, `background`,
  `surfaceContainerLow/High` y los cinco `*Container`, en claro y oscuro; el cuadradito de las tarjetitas a 3:1.
- `test/presentation/widgets/app_text_with_action_test.dart`: el botón va al lado con sitio y baja a 320 px y 200 %.

### Nodos propios para el lector (cliente)

- Todo `Semantics(button: true, excludeSemantics: true)` lleva `onTap:` con la misma acción que su botón o `InkWell`
  (si no, TalkBack/VoiceOver anuncian un botón que no responde). Corregidos: «Mover» de la bandeja de Académico, fechas
  de la importación de la guía, tira de ejercicios de la sesión en vivo, selector de semanas, barra de sesión abierta,
  series de calentamiento e insignias de «Tú».
- Todo elemento de una tira, lista o fila de hermanos con su propia etiqueta lleva `container: true`: `AppDayChip`,
  `AppShortcutTile`, días de «Tu semana» (`PlanWeekBar`), insignias del perfil público, chips de semana, pasos de los
  asistentes, preguntas del navegador del simulacro, filas de material, botones con nombre de Inicio, Gimnasio y
  Académico, avatares de «Con amigos», tramos de una carrera, medidores de «Tu equilibrio», filas por asignatura y el
  avatar de cada comentario. «No leída» de una notificación pasa dentro de la tarjeta (su nodo), donde se lee con ella.
- No se añade `container` a lo que debe leerse junto con su tarjeta pulsable (píldoras, cifras, textos de apoyo): ahí
  fundirse es lo correcto.

### Calendario › ficha de una clase (cierra el pendiente del ADR 0060)

- El enlace sale del dominio: `CalendarBlock.onlineLink` (getter puro, sin Flutter) toma el primer `https://…` de
  «Lugar» sin la puntuación que lo cierra en la frase (`[.,;:)\]>]+` al final: «(https://meet…/abc).»), y
  `CalendarBlock.locationShown` enseña «Lugar» con el enlace cambiado por su dominio («Teams:
  teams.microsoft.com»): la dirección entera no se entiende leída ni dicha.
- `BlockDetails.primaryAt` → **«Entrar a la clase en línea»** (`BlockDetailsAction.goToClass`) solo si la clase no ha
  acabado, es **hoy o empieza en ±15 min**, y tiene enlace. El lector oye «Entrar a la clase en línea. Se abre fuera
  de la app» (`AppPrimaryButton.semanticsLabel`). `launchUrl` va en `try/catch` (sin app que lo abra lanza
  `PlatformException`) y si no se abre, aviso «No hemos podido abrir el enlace de la clase.».
- Otro día, sin enlace (un aula se lee en la ficha, no se abre: no hay mapa del campus) o ya pasada, la principal es
  «Abrir asignatura» (apuntes y entregas antes y después de clase) y la fila de la asignatura no repite su botón. Sin
  asignatura ni enlace, no hay principal. Los `switch` de texto e icono de la ficha cubren todas las acciones (sin
  `_ =>`).

### Iconos (`AppIcons`)

- Iconos del menú ⋮ del calendario y de las pantallas de las tandas 2-5 (calendario, Tú, Comunidad, perfil, sesión en
  vivo, registro diario, Académico e Inicio) desde `AppIcons` cuando el icono es una acción o un estado con nombre. Los
  que solo ilustran un contenido (categoría de insignia, tipo de evento, caras del registro diario, tipo de archivo)
  siguen con `Icons.*`: no son acciones y no se repiten con otro significado.
- Una acción, un icono, y dos acciones que salen juntas no comparten dibujo: `exam` (examen, simulacro) y `practice`
  (practicar, `model_training`) se separan; `goal` (objetivo, una diana) deja la bandera de `challenge`; `invitation`
  (sobre sin leer) se separa de `email` (escribir); `enrollment` (matrícula) de `upload` (subir un archivo);
  `importGuide` (añadir la guía) de `noteDocument` (un apunte). `menu` (⋮, menú desplegable de la barra) y
  `moreActions` (…, botón «Acciones» que abre una hoja) quedan comentados con cuándo va cada uno.
- Nuevos: `checkIn` (registro diario), `move` (mover un apunte de la bandeja), `newNote` (crear o guardar como
  apunte), `reviewAll` (repasar todo seguido), `scan` (escanear horario o apuntes), `pause`, `swap`, `finish`, `menu`,
  `pastStudy`, `calendarSync`. En la agenda de Inicio, «Con retraso» usa `overdue` y «Ahora», `inProgress`.

### Tarjetitas (`AppShortcutTile` / `AppTintedIcon`)

- Como la maqueta: el cuadradito tintado es el **contenedor** del color con el icono en su `on*Container`
  (`primaryContainer`/`onPrimaryContainer`…) y el neutro, `surfaceContainerLow` con el icono `onSurface`. Tonos
  (`AppTileTone`: primario, secundario, terciario, **acento**, neutro): lima (secundario) para el cuerpo (Físico,
  Plantillas de retos), violeta (terciario) para la mente y lo social del perfil (Académico, Amigos, Muro, «Con
  amigos»), neutro para lo que no es de un dominio (Ajustes, «Cómo me ven», «De otros» y las tarjetitas de Tú ›
  Comunidad). «Nuevo» va relleno (`emphasized`).
- Filas de «Con amigos ahora», como la maqueta: invitaciones y sala de estudio en violeta, entrenar en lima, retos y
  rachas en naranja (`accent`). El tinte es decorativo: el nombre dice qué es.

### Perfil

- Un dato que falta dice **«Sin indicar»** (`profileNotSet`) y toda la fila (`ProfileInfoRow(onEdit:)`) es un botón
  que abre «Editar» para ponerlo (lápiz y pista «Editar» para el lector). En las cifras (IMC, peso, altura) la palabra
  no cabe: se ve «—» (`profileMissingValue`) y el lector oye «Sin indicar». En la evolución del objetivo, «fecha sin
  indicar».
- Las fichas Físico y Académico arrancan `ProfileBloc` con `ProfileEvent.started(friendRequests: false)`: no piden las
  solicitudes de amistad para enseñar una ficha. La elección vive en el estado (`ProfileState.countsFriendRequests`,
  la fija `started` y la sigue `refreshed`), no en un campo mutable del bloc.

### Estado compartido de una zona (`screens/<zona>/feedback/`)

- Lo que comparten los blocs de una zona (enums de carga, avisos de una vez) va en `feedback/`, sin interfaz:
  `social/feedback/social_feedback.dart` (lo pinta `social/widgets/show_social_feedback.dart`) y
  `admin/feedback/admin_status.dart` (antes en `admin/widgets/`, lo importaban siete blocs). Lo recoge el perfil
  `frontend-flutter-bloc.md` y `dependency_rule_test.dart` comprueba que ningún bloc importa `widgets/`.

## Consecuencias

- Toda acción se ve como botón en cualquier fondo; diálogos con la misma jerarquía que las pantallas. Sin cambios de
  servidor ni de API.
- Un `TextButton` nuevo sale ya con borde y fondo; para algo destructivo hay que usar `AppDangerButton` (el test lo
  exige).
- La acción principal de una clase depende de lo que el estudiante escriba en «Lugar»: pegar el enlace de la
  videollamada basta para que, el día de la clase, la ficha lleve a ella.
