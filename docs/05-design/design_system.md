# Sistema de diseño

**Fuente única:** `tokens.json` (formato DTCG). `frontend/tool/generate_tokens.dart` genera `lib/presentation/theme/tokens.g.dart`; el tema (`app_theme.dart`) y la paleta semántica (`AppPalette`) se construyen a partir de ahí. Ningún color, espaciado, radio ni ancho máximo se escribe a mano en las pantallas.

Comprobación automática: `test/presentation/theme/contrast_test.dart` verifica el contraste AA de todas las parejas de color en los dos temas (texto, iconos y el patrón «pastilla»).

## Dirección visual: «B · Deportivo oscuro»

La app **arranca en oscuro** (`themeMode: ThemeMode.dark` en `SynaptixFitApp`); el tema claro mantiene la misma identidad y queda listo para un futuro selector. Lienzo casi negro, tarjetas planas con borde fino, un verde lima enérgico para la acción y un color por dominio: **mente en violeta, cuerpo en lima, logro en naranja**. Todo sale de los tokens y del tema: las pantallas no cambian.

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
| `success` · `warning` · `error` | Estados (siempre con icono o texto, nunca solo color) |

Superficies: `background` para el lienzo, `surface` para tarjetas y `surfaceContainer*` para rellenos. Todos los colores de texto superan 4,5:1 sobre `surface`, `background` y `surfaceContainerHigh`, también tintados al 12 %. En oscuro, el texto secundario `#9CA3AF` da 6,9:1 sobre la tarjeta y 7,7:1 sobre el lienzo; el lima da 15:1 con su texto oscuro.

Barra de navegación: icono y etiqueta siempre visibles; el destino activo va en `primary` con icono relleno, etiqueta en negrita y un indicador casi invisible (`primary` al 12 %). El borde del botón secundario es decorativo (el texto identifica el botón); los campos de texto sí llevan `outline` (≥ 3:1 contra su relleno y el lienzo).

`outline` es solo para bordes, iconos y gráficos (3:1): **nunca como color de texto**. Los estados neutros con texto (bloqueado, sin evaluar, archivada, abandonado, inactivo) usan `onSurfaceVariant`.

## Tipografía

Manrope para títulos y cifras (pesos 700–800; `display*`, `headline*` en 800, interletrado ligeramente negativo; se sube el peso y no el tamaño para no romper las maquetas con el texto al 200 %) y DM Sans para texto y etiquetas (interlineado 1,4–1,5). Van **empaquetadas** en `frontend/assets/google_fonts/` (pesos 400–800, con su licencia OFL al lado, registrada en `LicenseRegistry`) y `google_fonts` las toma por nombre de archivo (`Manrope-Bold.ttf`, `DMSans-SemiBold.ttf`…). `main.dart` desactiva la descarga en tiempo de ejecución: ni salto de tipografía al cargar ni letra del sistema sin conexión. Para añadir un peso, descarga el TTF estático de Google Fonts con ese mismo patrón de nombre. Los estilos siempre salen de `context.textStyles`.

## Espaciado, forma y maquetación

- Espaciado en múltiplos de 4: `TokensSpacing.xxs (2) · xs (4) · s (8) · sm (12) · m (16) · ml (20) · l (24) · xl (32) · xxl (48)`.
- Radios: 8 (chips pequeños), 12 (campos y listas), 20 (tarjetas), 28 (hojas y diálogos), pastilla (botones).
- Anchos (`TokensLayout`): `contentMaxWidth` (960) para páginas y pestañas (todas, Progreso incluido), `readingMaxWidth` (720) para formularios y lectura, `wideMaxWidth` (1120) para paneles de varias columnas (Inicio, administración) y `formMaxWidth` (420) para acceso y registro. Ninguna pantalla escribe un ancho a mano.
- **La barra y el contenido usan el mismo ancho:** `AppPageBar` + `AppContentWidth` (o el envoltorio del módulo), `AppPageBar.reading` + `.reading`, `AppPageBar.wide` + `.wide`.
- Cortes: `railBreakpoint` (840, la barra inferior pasa a riel lateral), `twoColumnBreakpoint` (880, Inicio en dos columnas) y `compactHeight` (560: con menos alto se ocultan los paneles decorativos, como el de marca del acceso). `minTouchTarget` (48) para todo lo pulsable.
- Tamaños (`TokensSize`): `controlHeight` (52, botones), `toolbarHeight` (64), `navBarHeight` (72), `railWidth` (88), `progressBar` (8: grosor único de las barras de progreso, vía `progressIndicatorTheme`; no se pasa `minHeight`), iconos `iconXs` 16 · `iconS` 20 · `iconM` 24 · `iconL` 36 · `iconXl` 48, `emptyBadge` (72) / `emptyBadgeCompact` (48), `medallion` (88) y `thumbnailS` (48, miniatura pequeña de ejercicio).
- Duraciones (`TokensDuration`): `fast` 150 · `normal` 250 · `slow` 400 · `emphasized` 900 · `tooltipWait` 600. Siempre a través de `context.motion(...)`.
- **Nada de valores visuales sueltos en `screens/`:** ni `size: 18`, ni `minTileHeight: 56`, ni `withValues(alpha: 0.14)`, ni `TextStyle(...)`; se usan `TokensSize.*`, `AppPill.tintAlpha` y `context.textStyles.*.copyWith(...)`. El trinquete `test/presentation/theme/hardcoded_values_test.dart` cuenta los que quedan y falla si suben; cuando arregles alguno, baja su máximo en el mismo cambio.

## Componentes base (`presentation/widgets/`)

| Componente | Para qué |
|---|---|
| `AppPageBar` | Barra superior alineada con el ancho del contenido (`.reading` para formularios, `.wide` para paneles); su alto sale del tema |
| `AppContentWidth` | Centra y limita el ancho del contenido (`.reading`, `.wide`) |
| `AppPill` | **Única** pastilla de estado o dato: texto (e icono opcional) de un color sobre ese color al 12 % fundido con `surface`, en `labelMedium`. Los módulos solo eligen etiqueta, icono y color (o envuelven un enum, como `BalanceStateChip`). Los colores admitidos como texto son los de la lista «pastillas tintadas» del test de contraste |
| `AppTileGrid` | Accesos rápidos en una fila, o en filas de la mitad si no caben (texto al 200 %) |
| `AppCard` | Tarjeta plana con borde suave y toque opcional |
| `AppMetricTile` | Cifra con icono, etiqueta y desglose; se anuncia como una sola frase. `bare: true` dentro de otra tarjeta (nada de tarjeta dentro de tarjeta) |
| `AppSectionHeader` | Título de sección (encabezado accesible) con acción; `actionExpanded` si la acción despliega o pliega («Ver todas» / «Ver menos») |
| `AppPrimaryButton` · `AppSecondaryButton` | Botones con estado de carga anunciado |
| `AppTextField` | Campo con etiqueta visible, ayuda y contraseña con botón etiquetado |
| `AppEmptyState` (`.compact` dentro de tarjetas) · `AppErrorView` (reintento como botón secundario) · `AppLoadingView` | Estados vacío, error y carga |
| `AppSkeleton` · `AppSkeletonGroup` · `AppSkeletonList` | Carga con la forma del contenido. Cada bloque es mudo; el grupo (o la lista) se anuncia una vez como «Cargando» (región viva). Todo estado de carga con esqueletos va en un `AppSkeletonGroup` o es un `AppSkeletonList`. Sin brillo si se reduce el movimiento |
| `XpProgressBar` · `AppAvatar` · `AppBrandMark` | Nivel, avatar y marca (monograma plano en `primary` con una chispa naranja; sin degradados) |
| `AppChartSummary` | Resumen textual de una gráfica para lectores de pantalla (excluye los trazos) |
| `AppFocusGroup` · `AppScrollBehavior` · `AppFocusOutline` · `AppNavFocusRing` | Orden y visibilidad del foco con teclado (ver `accessibility.md`, «Teclado y foco»). Todo `InkWell` propio y todo `ListTile` pulsable de `screens/` va dentro de un `AppFocusOutline`; los iconos de la barra inferior y del riel, dentro de un `AppNavFocusRing` |

Antes de crear un widget nuevo, busca en el barrel `widgets.dart`. Los envoltorios de ancho de cada módulo (`AcademicBody`, `TrainingContent`…) delegan en `AppContentWidth`.

## Estructura de la app

- **Navegación:** hasta 5 pestañas (Inicio, Académico, Rutinas, Retos, Progreso); con un solo enfoque de uso se oculta Académico o Rutinas (ADR 0014). Barra inferior en móvil, riel lateral con la marca en pantallas anchas (`MainShellPage`).
- **Inicio pone primero lo que hay que hacer:** saludo → aviso solo si es urgente → agenda → (aviso informativo) → próximo entreno → «Tu equilibrio» compacto (una fila con barra para la mente y otra para el cuerpo, nivel en palabras, sin cifras técnicas como el ACWR) → retos y semana. En pantallas anchas se reparte en dos columnas: lo de hoy y el estado a la izquierda; retos y semana a la derecha. Todas las tarjetas llevan a su pantalla.
- **Logros globales:** la subida de nivel y las insignias nuevas se celebran una sola vez en un diálogo común (`AchievementsHost`), estés en la pestaña que estés.
- **Datos siempre al día:** cualquier escritura en la API avisa por `DataChangeInterceptor` → `WatchDataChangesUseCase`, y el bloc de cada pestaña que muestra esos datos (con `DataChangeRefreshMixin`) se refresca en segundo plano. Una acción nueva no tiene que avisar a mano: basta con que su ruta esté en el mapa de `DataChangeInterceptor`.

## Principios

1. Superficies planas con borde suave y sin degradados; sombra solo en elementos flotantes (botón flotante).
2. Un color de acento por dominio (mente violeta, cuerpo lima, logro naranja); el lima de `primary` es para acciones.
3. Estados vacíos, de carga y de error en todas las listas.
4. Cada cifra o tarjeta lleva a donde se puede actuar sobre ella.
5. Textos siempre desde el `.arb`.
