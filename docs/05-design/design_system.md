# Sistema de diseño

**Fuente única:** `tokens.json` (formato DTCG). `frontend/tool/generate_tokens.dart` genera `lib/presentation/theme/tokens.g.dart`; el tema (`app_theme.dart`) y la paleta semántica (`AppPalette`) se construyen a partir de ahí. Ningún color, espaciado, radio ni ancho máximo se escribe a mano en las pantallas.

Comprobación automática: `test/presentation/theme/contrast_test.dart` verifica el contraste AA de todas las parejas de color en los dos temas (texto, iconos y el patrón «pastilla»).

## Dirección visual: «B · Deportivo oscuro»

La app **arranca en oscuro** por defecto; en Ajustes → Apariencia se elige Oscuro, Claro o «Como el sistema» (`AppearanceBloc` en la raíz, guardado en el dispositivo y leído antes de `runApp` para que no haya destello). El cambio de tema se anima `TokensDuration.normal`, o al instante si se pide reducir el movimiento. El tema claro mantiene la misma identidad. Lienzo casi negro, tarjetas planas con borde fino, un verde lima enérgico para la acción y un color por dominio: **mente en violeta, cuerpo en lima, logro en naranja**. Todo sale de los tokens y del tema: las pantallas no cambian.

| Pieza | Oscuro (por defecto) | Claro |
|---|---|---|
| Lienzo (`background`) | `#0B0D12` | `#F5F6F8` |
| Tarjeta (`surface` + borde `outlineVariant`, radio 20) | `#161A23` / `#222734` | `#FFFFFF` / `#E2E5EA` |
| Superficie elevada y campos (`surfaceContainerLow`) | `#1C212C` | `#F3F4F7` |
| Barra inferior y riel (`navigationBar`) | `#11141B`, línea superior `#222734` | `#FFFFFF` |
| Texto / secundario | `#F3F4F6` / `#9CA3AF` | `#0B0D12` / `#4B5563` |
| `primary` (acción, destino activo) | lima `#C6F432`, texto encima `#0B0D12` | lima oscuro `#3F6212`, texto blanco |
| Botón secundario (`buttonOutline`) | contorno `#2A303C`, texto claro | contorno `#D1D5DB`, texto oscuro |

## Color

| Rol | Uso |
|---|---|
| `primary` (lima de marca) | Acciones principales, destino activo de la navegación, foco, enlaces |
| `secondary` · `sessions` (lima) | Cuerpo: entrenamiento y salud |
| `tertiary` · `study` (violeta `#A78BFA` / `#6D28D9`) | Mente: estudio, repaso e IA |
| `accent` · `streak` (naranja `#FB923C`–`#FDBA74` / `#B03A0A`) | XP, niveles, rachas, insignias — vía `context.palette.accent`. Sobre `accentContainer`, el texto va en `onAccentContainer` |
| `calories` (rosa) | Energía gastada en las métricas |
| `cycle` · `cycleContainer` (magenta `#A21CAF` / `#E879F9`) | «Mi ciclo»: días de regla y su leyenda — vía `context.palette.cycle`. No es el `error`: la regla no es un fallo. Sobre `cycleContainer`, el texto va en `onCycleContainer` |
| `success` · `warning` · `error` | Estados (siempre con icono o texto, nunca solo color) |

Superficies: `background` para el lienzo, `surface` para tarjetas y `surfaceContainer*` para rellenos. Todos los colores de texto superan 4,5:1 sobre `surface`, `background` y `surfaceContainerHigh`, también tintados al 12 %. En oscuro, el texto secundario `#9CA3AF` da 6,9:1 sobre la tarjeta y 7,7:1 sobre el lienzo; el lima da 15:1 con su texto oscuro.

Barra de navegación: icono y etiqueta siempre visibles; el destino activo va en `primary` con icono relleno, etiqueta en negrita y un indicador casi invisible (`primary` al 12 %). El borde del botón secundario es decorativo (el texto identifica el botón); los campos de texto sí llevan `outline` (≥ 3:1 contra su relleno y el lienzo).

`outline` es solo para bordes, iconos y gráficos (3:1): **nunca como color de texto**. Los estados neutros con texto (bloqueado, sin evaluar, archivada, abandonado, inactivo) usan `onSurfaceVariant`.

## Tipografía

Manrope para títulos y cifras (pesos 700–800; `display*`, `headline*` en 800, interletrado ligeramente negativo; se sube el peso y no el tamaño para no romper las maquetas con el texto al 200 %) y DM Sans para texto y etiquetas (interlineado 1,4–1,5). Van **empaquetadas** en `frontend/assets/google_fonts/` (pesos 400–800, con su licencia OFL al lado, registrada en `LicenseRegistry`) y `google_fonts` las toma por nombre de archivo (`Manrope-Bold.ttf`, `DMSans-SemiBold.ttf`…). `main.dart` desactiva la descarga en tiempo de ejecución: ni salto de tipografía al cargar ni letra del sistema sin conexión. Para añadir un peso, descarga el TTF estático de Google Fonts con ese mismo patrón de nombre. Los estilos siempre salen de `context.textStyles`.

## Espaciado, forma y maquetación

- Espaciado en múltiplos de 4: `TokensSpacing.xxs (2) · xs (4) · s (8) · sm (12) · m (16) · ml (20) · l (24) · xl (32) · xxl (48)`.
- Radios: 8 (chips pequeños), 12 (campos y listas), 20 (tarjetas), 28 (hojas y diálogos), pastilla (botones).
- Anchos (`TokensLayout`): `contentMaxWidth` (960) para páginas y pestañas (todas, «Tú» incluida), `readingMaxWidth` (720) para formularios y lectura, `wideMaxWidth` (1120) para paneles de varias columnas (Inicio, administración) y `formMaxWidth` (420) para acceso y registro. Ninguna pantalla escribe un ancho a mano.
- **La barra y el contenido usan el mismo ancho:** `AppPageBar` + `AppContentWidth` (o el envoltorio del módulo), `AppPageBar.reading` + `.reading`, `AppPageBar.wide` + `.wide`.
- Cortes: `railBreakpoint` (840, la barra inferior pasa a riel lateral), `twoColumnBreakpoint` (880, Inicio en dos columnas) y `compactHeight` (560: con menos alto se ocultan los paneles decorativos, como el de marca del acceso). `minTouchTarget` (48) para todo lo pulsable.
- Tamaños (`TokensSize`): `controlHeight` (52, botones), `toolbarHeight` (64), `navBarHeight` (72), `railWidth` (88), `progressBar` (8: grosor único de las barras de progreso, vía `progressIndicatorTheme`; no se pasa `minHeight`), iconos `iconXs` 16 · `iconS` 20 · `iconM` 24 · `iconL` 36 · `iconXl` 48, `emptyBadge` (72) / `emptyBadgeCompact` (48), `medallion` (88), `thumbnailS` (48, miniatura pequeña de ejercicio), `postImageMaxHeight` (360, imagen de una publicación), `subjectCardHeight` (184) / `subjectCardMaxWidth` (260) y `reviewCardWidth` (220) / `reviewCardHeight` (104), que crecen con el texto (`context.scaled`); desde el ADR 0057 Académico es una lista de una columna y un aviso «N repasos para hoy», y estos cuatro ya no se usan allí. Cortes de tarjeta (`TokensLayout`): `cardSideBySideMin` (280, bloque de fecha al lado) y `cardActionsInlineMin` (336, acciones de una fila de usuario a la derecha).
- Duraciones (`TokensDuration`): `fast` 150 · `normal` 250 · `slow` 400 · `emphasized` 900 · `tooltipWait` 600. Siempre a través de `context.motion(...)`.
- **Nada de valores visuales sueltos en `screens/`:** ni `size: 18`, ni `minTileHeight: 56`, ni `withValues(alpha: 0.14)`, ni `TextStyle(...)`; se usan `TokensSize.*`, `AppPill.tintAlpha` y `context.textStyles.*.copyWith(...)`. El trinquete `test/presentation/theme/hardcoded_values_test.dart` cuenta los que quedan y falla si suben; cuando arregles alguno, baja su máximo en el mismo cambio.

## Componentes base (`presentation/widgets/`)

| Componente | Para qué |
|---|---|
| `AppPageBar` | Barra superior alineada con el ancho del contenido (`.reading` para formularios, `.wide` para paneles); su alto sale del tema |
| `AppBackButton` | Flecha «Volver» (`AppIcons.back`, `tooltip` «Volver» para el lector, 48 dp) de toda pantalla que no es pestaña, como `leading` de `AppPageBar`. Con pantalla debajo vuelve (respeta `PopScope`); abierta sin pila (aviso, enlace, redirección, recarga en web) va a su `fallback`, la pantalla de la que cuelga. Va centrado en el hueco de la barra (si no, `AppBar` lo estira). Sin flecha: las pestañas, los pasos de entrada (aceptación legal, permisos iniciales; el onboarding usa su flecha para el paso anterior) y la sesión terminada, cada uno con su botón para seguir. Los editores a pantalla completa (rutina, generación) llevan «Cerrar». La misma flecha de Material en todas las plataformas, también en iOS (la app es Material de principio a fin). Salir solo tras guardar o descartar: `context.popOrGo` |
| `AppContentWidth` | Centra y limita el ancho del contenido (`.reading`, `.wide`) |
| `AppPill` | **Única** pastilla de estado o dato: texto (e icono opcional) de un color sobre ese color al 12 % fundido con `surface`, en `labelMedium`. Los módulos solo eligen etiqueta, icono y color (o envuelven un enum, como `BalanceStateChip`). Los colores admitidos como texto son los de la lista «pastillas tintadas» del test de contraste |
| `AppDayChip` | Chip de un día (día de la semana corto u «Hoy», número y marca opcional debajo). Elegido: relleno del color de marca y `selected` para el lector; hoy sin elegir: borde de marca. Etiqueta para el lector completa («Lunes 16», «Hoy, miércoles 15»). Lo usan la agenda de Inicio y la tira de días del calendario (ADR 0050); alto mínimo de 48 dp |
| `AppTileGrid` | Accesos rápidos en una fila, o en filas de la mitad si no caben (texto al 200 %) |
| `AppCard` | Tarjeta plana con borde suave y toque opcional; si es pulsable se anuncia como botón. Solo pulsable entera si no lleva más acciones dentro |
| `AppInlineMessage` | Aviso junto a lo que lo provoca (un campo, una hoja, un formulario de acceso), en tono error, aviso o éxito, con el color al 12 %. No se cierra solo como un SnackBar; su texto es región viva |
| `AppMetricTile` | Cifra con icono, etiqueta y desglose; se anuncia como una sola frase. `bare: true` dentro de otra tarjeta (nada de tarjeta dentro de tarjeta) |
| `AppSectionHeader` | Título de sección (encabezado accesible) con acción; `actionExpanded` si la acción despliega o pliega («Ver todas» / «Ver menos») |
| `AppPrimaryButton` · `AppSecondaryButton` | Botones con estado de carga anunciado |
| `AppTextField` | Campo con etiqueta visible, ayuda y contraseña con botón etiquetado |
| `AppNumberCell` | Celda numérica de una tabla (series, reps, kg, segundos): aspecto de campo del tema, teclado numérico, confirma al salir o con Intro (no a cada tecla), borde rojo y aviso hablado fuera de rango; el lector oye «Serie 2, repeticiones». Mínimo 48 dp de alto |
| `AppCoverCard` · `AppCoverPill` | Tarjeta con foto. Con texto normal, la foto se ve tal cual en el lado final de la cabecera (`TokensLayout.coverPhotoShare` del ancho), fundida con la superficie (`coverPhotoFade`), y el texto va en la zona lisa: AA con cualquier foto. Lo que necesita el ancho entero (botón principal, progreso del ciclo, lista de ejercicios, acciones) va en `footer`, debajo y sin foto. Con el texto por encima del 130 % o sin foto, fondo a dos tonos (de la superficie a `coverTintLight`/`coverTintDark` de `primary`, lo oscuro de la foto al extremo más oscuro) con velo en el lado del texto; sin foto, un degradado del mismo tono (`contrast_test.dart`). Las pastillas encima van con `AppCoverPill` (base opaca). Foto y velo con `Ink`: la onda del toque se ve. Dos variantes (`layout`): `AppCoverLayout.side` (la descrita, para las tarjetas de rutina de Gimnasio y Comunidad) y `AppCoverLayout.bottom` (ADR 0042, tarjetas de sesión: historial, sesión abierta, próximo entreno de Inicio y Gimnasio, cabecera del detalle): la foto, con sus colores, va en una franja de `TokensSize.coverBanner` arriba, cuya parte baja (desde `coverBannerFadeMid`) se funde con la superficie, y el texto va debajo sobre la superficie lisa: AA con cualquier foto. Debajo de la foto va siempre el color de reserva (también mientras carga o si falla). Estado en `AppCoverPill` y tres datos como mucho |
| `AppStepBadge` | Círculo numerado de un paso (`TokensSize.stepBadge`, crece con la letra): activo en `primaryContainer`, bloqueado en neutro (`surfaceContainerHigh`) y hecho con una marca sobre `success`. Decorativo: el título del paso lo dice. Repaso en dos pasos |
| `AppHelpToggle` | Un «?» opcional (`AppIcons.help`, con su descripción «Qué es «…»») al lado de un contenido que abre y cierra la explicación debajo, como región viva. Para la ayuda que no debe interrumpir (vocabulario, sección 4): «Hasta no poder más», series de calentamiento, porqué de la propuesta de carga |
| `AppGuideTour` (`showAppGuideTour`) | Guía la primera vez de una pantalla (ADR 0049): velo `TokensOpacity.guideScrim` sobre todo menos la parte señalada (con un aro de `primary`) y una tarjeta junto a ella con **título + una frase**, «Saltar guía» y «Siguiente (n de N)»; en el último paso, «Entendido». Borde `outlineVariant` para separarla del velo en oscuro; botones apilados con letra grande o menos de `cardActionsInlineMin` de ancho. 2 a 4 pasos, cada uno señala su parte por una `GlobalKey` (los que no están pintados se saltan). Va en el navegador raíz como un diálogo: el lector la nombra «Guía, paso 1 de 3: …», el foco va al botón principal en cada paso, se cierra con «atrás» o Escape y no se anima con «reducir movimiento». La tarjeta se coloca debajo, encima o abajo del todo según quepa, nunca más ancha que `formMaxWidth`, y con letra grande apila los botones. No se usa suelta: la pone `FirstTimeGuide` (armazón), que decide cuándo sale |
| `AppWorkingView` | «Trabajando…» mientras la IA o la lectura de fotos tardan: icono (`TokensSize.iconXl`), barra de ancho `TokensSize.progressInline`, título y pista; es región viva, así que el lector lo anuncia una vez. Escaneo de apuntes, centro de generación y documento de IA |
| `AppBadgeEmblem` | Círculo de una insignia (`TokensSize.emblem`, borde `emblemBorder` del color de su rareza, tinte `AppPill.tintAlpha`); el emoji no crece con la letra (es decorativo: la etiqueta ya nombra la insignia). Lista de insignias y perfil público |
| `AppCycleProgress` | Barra de avance con su texto al lado («6/12 días»), que es también lo que oye el lector. `color` opcional para el acento del dominio (Retos); el texto al lado debe ser corto (con el texto al 200 % una etiqueta larga deja la barra sin sitio) |
| `AppDateBlock` · `AppDueDates` | Bloque de fecha a la izquierda de una tarjeta, con la forma del chip de día de la agenda: etiqueta arriba («Hoy», «Mañana», «lun», «Venció»), la cifra del día siempre en grande («3»; una palabra como «Aujourd'hui» no cabría) y el mes, tintado del color que se le pase. `AppDateBlock.due` lo arma desde una fecha; `overdue: true` (estado del servidor) fuerza «Venció» aunque la fecha sea de hoy. Es decorativo: la tarjeta dice lo mismo en una frase (`AppDueDates.text`: «Vence en 3 días», «Venció el 2 nov»); en un reto hecho o vencido la frase no se pinta (no repite el estado) y solo la anuncia el lector. `AppDateBlock.sideBySide` decide si cabe al lado (`TokensLayout.cardSideBySideMin`, 280); con el texto por encima del 130 % (`context.largeText`, token `TokensLayout.largeTextScale`) o poco ancho, `compact` lo convierte en una franja de una línea encima («Mañana · 3 · nov»). Color: aviso si vence hoy o mañana (`AppDueDates.isSoon`), error si venció sin hacerse (entregas), éxito si está hecho y el acento del dominio si no. Lo usan Retos, Entregas e Inicio |
| `AppCardTapArea` | Zona pulsable dentro de una tarjeta que tiene más acciones: la tarjeta deja de ser pulsable entera y cada zona (autor, cuerpo, enlace, botones) es hermana de las demás, **sin toques anidados**. Se lee como un botón con todo su contenido (o con `semanticLabel`; `semanticHint` dice qué hace el toque si el contenido no lo dice: «Abrir la publicación», «Editar entrega»), mide al menos 48 dp de alto y lleva el anillo de foco. Publicaciones, apuntes compartidos, filas de usuario, entregas y retos de Inicio |
| `ChallengeDateBlock` · `ChallengeCard` (Retos) | La tarjeta de reto (bloque de fecha = `AppDateBlock` con los textos de Retos) se lee en este orden: **cuándo** (bloque de fecha a la izquierda con la forma del chip de día de la agenda: «Hoy · 3 · nov», «lun · 10 · nov», «Empieza · 10 · nov», «Venció · 2 · nov»; tinte de aviso si vence hoy o mañana, gris si venció o aún no empieza, de éxito si está hecho y del acento del tipo si no). Un reto ajeno (Comunidad) no es pulsable entero: abrirlo y «Añadir a mis retos» son botones hermanos y la frase «Vence en 3 días» en `labelLarge`; **qué** (título); **cuánto** (`AppCycleProgress` en el acento del tipo, solo con el %); **qué toca** (siguiente paso). Tipo y tareas o sesiones, en pastillas. «Mis retos» se agrupa por cuándo toca (Vencen hoy · Próximos 7 días · Más adelante · Por empezar · Vencidos · Completados); el color de aviso es solo para lo que vence hoy o mañana (lo vencido ya no urge). Con el texto al 200 % o poco ancho, el bloque de fecha pasa a ser una franja de una línea encima del contenido. Las tareas pendientes llevan una franja del acento del tipo (`TokensSize.blockStripe`, como los bloques del calendario) y una pastilla con cuándo vence su reto |
| `AppIcons` (`theme/app_icons.dart`) | Mapa central de iconos: la misma acción lleva el mismo icono en toda la app (papelera = eliminar o descartar, `remove` = quitar una fila de una lista que se edita, lápiz = editar, más = añadir, `copyToMine` = «Añadir a mis rutinas/retos», `duplicate` = duplicar lo tuyo, `report` = reportar —nunca la bandera, que es Retos—, `proposal` = lo que propone la app). Todo botón solo con icono lleva `tooltip`. Un menú de tres puntos con una o dos acciones se sustituye por las acciones a la vista (con texto si el icono no se entiende solo) |
| `AppSegmentedChoice` | Elegir una opción corta sin icono (prioridad, dificultad, tipo de clase): botones segmentados con sitio y chips que bajan de fila con el texto grande o poco ancho; `allowEmpty` permite quitar la elección. Con icono y explicación, `AppAdaptiveChoice`. `spokenLabelOf` da otra frase al lector cuando el texto corto no se entiende oído («25 + 5 min» → «25 minutos de estudio y 5 de descanso») |
| `AppEmptyState` (`.compact` dentro de tarjetas) · `AppErrorView` (reintento como botón secundario) · `AppLoadingView` | Estados vacío, error y carga |
| `AppSkeleton` · `AppSkeletonGroup` · `AppSkeletonList` | Carga con la forma del contenido. Cada bloque es mudo; el grupo (o la lista) se anuncia una vez como «Cargando» (región viva). Todo estado de carga con esqueletos va en un `AppSkeletonGroup` o es un `AppSkeletonList`. Sin brillo si se reduce el movimiento |
| `XpProgressBar` · `AppAvatar` · `AppBrandMark` | Nivel, avatar y marca: el logo de `assets/images/logo.png` recortado en círculo (`TokensSize.brandLogo` en acceso y carga; `decorative: true` cuando el nombre ya va al lado). Los iconos de la app salen del mismo archivo con `tools/brand/generate_icons.py` |
| `FocusTimerBar` (armazón) | El Pomodoro en marcha en una franja fina sobre la navegación (o arriba del contenido con el riel): fase, tiempo y pausar o reanudar; tocarla vuelve al temporizador. Sin fase en curso no ocupa nada |
| `SetupChecklistCard` (Inicio) | Configuración pendiente: título, «N de M listo», barra de progreso y una fila por tarea con su enlace; «Ahora no» la oculta 7 días. Va tras el próximo entreno (no tapa lo de hoy) y desaparece al completarlo todo |
| `AppChartSummary` | Resumen textual de una gráfica para lectores de pantalla (excluye los trazos) |
| `AppFocusGroup` · `AppScrollBehavior` · `AppFocusOutline` · `AppNavFocusRing` | Orden y visibilidad del foco con teclado (ver `accessibility.md`, «Teclado y foco»). Todo `InkWell` propio y todo `ListTile` pulsable de `screens/` va dentro de un `AppFocusOutline`; los iconos de la barra inferior y del riel, dentro de un `AppNavFocusRing` |

Antes de crear un widget nuevo, busca en el barrel `widgets.dart`. Los envoltorios de ancho de cada módulo (`AcademicBody`, `TrainingContent`…) delegan en `AppContentWidth`.

## Estructura de la app

- **Navegación:** 5 pestañas en este orden: **Inicio · Calendario · Académico · Entreno · Tú** (ADR 0038 y 0061); con un solo enfoque de uso se oculta Académico o Entreno (Calendario se ve siempre). Barra inferior en móvil, riel lateral con la marca en pantallas anchas (`MainShellPage`). Entreno tiene los apartados «Gimnasio» y «Correr» (`TrainingSectionBar`, ADR 0037); «Tú», tu foto y tu nombre (abren el Perfil) y «Resumen · Retos · Insignias · Comunidad», cada uno con su icono (ADR 0061). Accesos en tarjetitas (Tú › Retos, Tú › Comunidad, Perfil): `AppShortcutTile` dentro de `AppTileGrid` (icono en un cuadrado de color, nombre, detalle y globo opcional; con el texto al 200 % pasan a filas de la mitad).
- **Guías la primera vez (ADR 0049):** sesión en vivo, Inicio, Calendario, Gimnasio, Concentrarme, Académico y la ficha de asignatura enseñan dónde está lo importante una sola vez por cuenta y teléfono (`FirstTimeGuide` + `AppGuideTour`), con la pantalla ya cargada y nada encima; si se llega desde un aviso, esperan a la próxima vez. Ajustes › Ayuda › «Ver las guías otra vez».
- **Inicio pone primero lo que hay que hacer:** saludo → aviso solo si es urgente (entregas vencidas, sobrecarga física o mucha fatiga) → «Tu día» (anillo de lo hecho hoy —eventos con seguimiento sin las clases y entregas de hoy, lo cuenta el servidor (ADR 0050)—, lo que toca ahora con su botón y tres cifras; la única acción principal visible al abrir) → agenda → próximo entreno → configuración pendiente → (resto de avisos) → «Tu equilibrio» compacto (una fila con barra para la mente y otra para el cuerpo, nivel en palabras, sin cifras técnicas como el ACWR; sin botón propio para no repetir el de «Tu día») → retos y semana. «Tu día» es plana con el tinte de marca al 12 %, sin degradado. En «Tu semana» lo planificado es una barra hueca con borde y lo hecho, una barra rellena encima (verde si el día está completo), con su leyenda. En pantallas anchas se reparte en dos columnas: lo de hoy y el estado a la izquierda; retos y semana a la derecha. Todas las tarjetas llevan a su pantalla.
- **Logros globales:** la subida de nivel y las insignias nuevas se celebran una sola vez en un diálogo común (`AchievementsHost`), estés en la pestaña que estés.
- **Datos siempre al día:** cualquier escritura en la API avisa por `DataChangeInterceptor` → `WatchDataChangesUseCase`, y el bloc de cada pestaña que muestra esos datos (con `DataChangeRefreshMixin`) se refresca en segundo plano. Una acción nueva no tiene que avisar a mano: basta con que su ruta esté en el mapa de `DataChangeInterceptor`.

## Tarjetas: lo que hace actuar, primero

Antes de maquetar una tarjeta se decide qué necesita la persona para actuar (cuándo es, qué falta, qué sigue, quién) y eso se lleva la jerarquía principal: posición (arriba o a la izquierda), tamaño (`labelLarge` o más) y color; lo secundario va más pequeño y en `onSurfaceVariant`. Nada monótono: cada tarjeta lleva el acento de su dominio (estudio `tertiary`, entrenamiento `secondary`, logro `palette.accent`) en un icono, una franja (`TokensSize.blockStripe`), un panel tintado al 12 % o una pastilla, y una imagen solo donde aporta.

| Tarjeta | Lo primero | Después |
|---|---|---|
| Publicación (Comunidad) | Quién y qué: avatar con insignia del tipo en su acento, nombre (botón al perfil) y «Reto completado · hace 3 h» | Texto e imagen (abren el detalle), lo enlazado en un panel del acento (reto, insignia, rutina) y «me gusta» / comentarios (≥ 48 dp) |
| Cabecera del muro | «¿Qué quieres compartir hoy?» con tu avatar y atajos «Un logro» / «Un entreno» (icono en su acento) | Filtro por periodo |
| Fila de usuario (amigos, búsqueda) | Nombre y nivel (pastilla de logro); una solicitud recibida lleva franja `primary` y «Quiere ser tu amigo» | Acciones a la derecha, o debajo con el texto grande |
| Entrega / examen (Planificador) | Bloque de fecha y «Vence mañana · 23:59» (aviso hoy/mañana, error y «Venció el…» si el servidor la da por vencida; «Hecha» si lo está) | Título, pastillas de tipo, asignatura, dificultad; marcar como hecha y borrar, aparte |
| Reto activo (Inicio) | Bloque de fecha y «Termina mañana» | Título y barra con el % en el acento del tipo |
| Asignatura (Académico, ADR 0057) | Nombre, «6 ECTS · 2.º curso · 1.er cuatri» y la barra «Temas 4 de 10» (o «Sin temario: importa la guía», botón aparte); franja en su color | «3 repasos hoy» (pastilla de estudio, solo si hay) y lo próximo en una franja suave (icono de aviso si es hoy o mañana). Profesor y apuntes, en el detalle |
| Apunte compartido | Autor (botón al perfil) y fecha; la asignatura en violeta | Título, extracto y visibilidad |

### Asignatura en pestañas (ADR 0057)

Resumen · Temario · Evaluación · Apuntes · Guía, con la barra de pestañas desplazable. Piezas de `subject_detail/page/`:
`SubjectTabBody` (carga, error, avisos y «tirar para recargar» comunes), `GuideMissingView` (vacío útil sin guía docente,
con «Importar guía docente»), `YourGradeCard` («Tu nota»: puntos grandes, «de N puntos» y una frase en un panel tintado
con icono: aprobado en `success`, no se llega en `warning`, lo que falta en `primary`) y `ProfessorCard` (iniciales,
papel en pastilla, despacho, tutorías y «Escribir» solo con email). Las ayudas opcionales («Lo que dominas», «Cómo te
evalúan») usan `AppHelpToggle`.

## Principios

1. Superficies planas con borde suave y sin degradados; sombra solo en elementos flotantes (botón flotante).
2. Un color de acento por dominio (mente violeta, cuerpo lima, logro naranja); el lima de `primary` es para acciones.
3. Estados vacíos, de carga y de error en todas las listas.
4. Cada cifra o tarjeta lleva a donde se puede actuar sobre ella. Si una tarjeta tiene varias acciones, no es pulsable entera: cada acción es su propio botón (`AppCardTapArea`).
5. Textos siempre desde el `.arb`.
6. Lo que hace actuar, primero (ver «Tarjetas»).
