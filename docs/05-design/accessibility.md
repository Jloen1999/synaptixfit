# Accesibilidad (WCAG 2.2 AA)

Lo marcado está resuelto en los componentes base o el tema y comprobado por tests; lo no marcado se revisa pantalla a pantalla.

- [x] Contraste ≥ 4,5:1 para texto y ≥ 3:1 para iconos, bordes de campos y gráficos, en los temas claro y oscuro. Test: `test/presentation/theme/contrast_test.dart`.
- [x] Objetivos táctiles de al menos 48×48 dp en todas las plataformas (`materialTapTargetSize: padded`, `TokensLayout.minTouchTarget`).
- [x] Todos los botones de icono tienen `tooltip`; el de mostrar/ocultar contraseña también.
- [x] El color nunca es la única señal: estados con icono o texto; preguntas respondidas del simulacro anunciadas como «respondida».
- [x] Encabezados reales: `AppSectionHeader` marca `Semantics(header: true)`; también el título de acceso y registro (`AuthHeader`) y el saludo de Inicio.
- [x] `outline` nunca como color de texto (no llega a 4,5:1). El test de contraste lista todos los colores que se usan como texto de `AppPill`.
- [x] Texto al 200 %: alturas fijas con texto usan `context.scaled(...)`; cabeceras y barras ceden espacio en lugar de desbordar. «Tu estado» de Inicio apila mente y cuerpo en móvil y el valor baja de línea si no cabe; la fila de ejercicio del editor pone sus acciones debajo del nombre; los accesos rápidos pasan a filas de dos (`AppTileGrid`).
- [x] «Reducir movimiento» (`context.reduceMotion`, `context.motion(duración)`): transiciones de página, tarjetas plegables (calentamiento de la sesión en vivo), esqueletos, tarjetas de repaso, gráficas y desplazamientos. Los vídeos de ejercicios no arrancan solos si se pide reducir el movimiento y siempre tienen botón de pausa (2.2.2).
- [x] Formularios: etiqueta visible (sin campos con solo texto de ejemplo), error en texto junto al campo y `autofillHints` en acceso y registro.
- [x] Cargas anunciadas: `AppLoadingView`, los botones en carga (`AppPrimaryButton` con región viva: la carga la pide la persona al pulsar) y los esqueletos (`AppSkeletonGroup` / `AppSkeletonList`, una sola vez) dicen «Cargando». Lo que se refresca solo en segundo plano no lleva `liveRegion` (el aviso de Inicio se volvería a leer con cada cambio de datos).
- [x] Contenido plegable con su estado anunciado (`Semantics(expanded:)`): «Ver detalle» de las sugerencias de Rutinas y «Ver todas / Ver menos» (`AppSectionHeader.actionExpanded`). Test: `test/presentation/screens/training/training_home_view_test.dart`.
- [x] Gráficas de progreso y bienestar con resumen textual (`semanticsSummary`); las filas de «Tu estado» con etiqueta, valor y nivel en palabras.
- [x] Mover ejercicios con «Subir»/«Bajar» (2.5.7): el foco sigue al ejercicio (claves estables), pasa al botón contrario al llegar al extremo y se anuncia la nueva posición (4.1.3).
- [x] Chips elegidos con marca y borde primario además del relleno (1.4.1, 1.4.11).
- [x] «Deshacer» al borrar (`context.showUndoSnack`): el elemento desaparece y el borrado se confirma al cerrarse el aviso sin deshacer (no con un temporizador aparte), así con lector de pantalla, donde el aviso no se cierra solo, nunca se borra antes de tiempo (2.2.1). Ventana de `TokensDuration.undoWindow` (10 s), Ctrl/Cmd+Z con `AppUndoShortcut` (2.1.1) y el foco pasa al elemento siguiente al borrar (2.4.3). Al salir de la pantalla lo pendiente se borra; si la app se cierra antes, no se borra nada.
- [x] Selector − / + (`AppStepperField`): botones con el nombre del valor («Reducir Semanas»), el valor se anuncia al cambiar (región viva) y en el extremo el foco pasa al botón contrario (2.4.3, 4.1.3).
- [x] Secciones opcionales que se despliegan («Más opciones» del onboarding): `Semantics(expanded:)` y lo nuevo aparece debajo del botón que lo abre.
- [x] Gráficas del panel de administración (tendencia de KPIs y actividad semanal del usuario) con resumen textual (`AppChartSummary`): periodo y, por serie, último valor, máximo y media. Las series no dependen del color: líneas continua, discontinua y punteada; barras rellenas frente a barras con borde (1.4.1). Test: `test/presentation/screens/admin/admin_charts_semantics_test.dart`.
- [x] Orden de foco lógico y navegación completa con teclado en web y escritorio (2.1.1, 2.4.3, 2.4.7, 2.4.11). Ver «Teclado y foco» abajo.

## Teclado y foco

El orden de Flutter (`ReadingOrderTraversalPolicy`) es geométrico: va por filas, de arriba abajo y de izquierda a derecha, usando la posición real de cada control. Reglas:

1. **Maquetas de varias columnas:** cada columna va en su propio `AppFocusGroup`. Así el Tabulador recorre la columna izquierda entera y después la derecha (Inicio a partir de 880 px). Lo mismo para la navegación: el riel o la barra inferior y el contenido son grupos separados (`MainShellPage`).
2. **Zonas desplazables:** `AppScrollBehavior` (registrado en `MaterialApp`) convierte cada zona desplazable en un grupo del tamaño de lo que se ve. Sin él, lo desplazado por encima contaba como «antes» de la barra superior y el botón de un pie fijo se colaba entre cada campo y el siguiente. No hace falta hacer nada en cada pantalla.
3. **Foco siempre visible:** `AppFocusGroup` (también en la raíz de la app) desplaza la pantalla en los dos sentidos para que el elemento enfocado se vea; la política por defecto solo desplaza hacia abajo al avanzar. Los botones del tema llevan un anillo de foco exterior (`onSurface`, 2 px), los chips y botones segmentados engrosan su borde con el mismo color y `AppCard` pulsable cambia su borde igual. Los destinos de la barra inferior y del riel llevan `AppNavFocusRing`: un óvalo `onSurface` del tamaño del indicador (el velo de Material sobre `navigationBar` no se veía; contraste en `contrast_test.dart`, test en `nav_focus_ring_test.dart`). Todo `InkWell` propio y todo `ListTile`, `SwitchListTile`, `CheckboxListTile` o `RadioListTile` pulsable va dentro de un `AppFocusOutline` (radio por defecto: el de las filas de lista).
4. **Una parada por destino:** si una sección ya lleva a un sitio, sus partes no repiten el mismo destino con otra parada del Tabulador (el resumen semanal de Inicio no es pulsable; las cifras de Retos solo informan y el filtro está en los chips).
5. **Controles propios:** nada de `GestureDetector` para tocar; `InkWell` o botones (enfocables, con Intro/Espacio y resaltado). Si la etiqueta accesible tapa el control, se excluye solo su contenido (`ExcludeSemantics` dentro del `InkWell`), no el `InkWell`: si no, en la web pierde la acción y el foco. Arrastrar siempre tiene alternativa (los bloques del calendario se mueven desde su editor; 2.5.7).
6. **Orden propio cuando la geometría no sirve:** el lienzo del calendario usa `OrderedTraversalPolicy` para ir bloque a bloque en orden cronológico.
7. **Diálogos:** foco inicial en la acción principal (`autofocus`); si la acción es destructiva, en «Cancelar» para que un Intro accidental no borre. En diálogos de un solo campo, Intro confirma (`textInputAction: done` + `onSubmitted`).

Tests: `test/presentation/widgets/app_focus_group_test.dart` (orden por columnas, foco revelado hacia arriba, lista entre barra y pie fijo).

### Cómo probar la navegación con teclado

1. `cd frontend && flutter build web --dart-define=API_BASE_URL=http://localhost:8080` y servir `build/web` (p. ej. `python -m http.server 5173 -d build/web`).
2. En el navegador, activar el árbol semántico: `document.querySelector('flt-semantics-placeholder')?.click()` (sin él no hay elementos DOM enfocables que inspeccionar).
3. Pulsar Tab y Mayús+Tab en cada pantalla y comprobar: el orden sigue la lectura (barra superior → contenido, columna a columna → pie fijo o botón flotante → navegación), todo lo pulsable se alcanza, el foco siempre se ve y nunca queda fuera de la pantalla. `document.activeElement` (su `aria-label` o texto) dice qué control tiene el foco.
4. Automatizado con Playwright (navegador visible): recorrer con `page.keyboard.press('Tab')`, leer `document.activeElement` tras cada pulsación (esperar unos 400 ms si el foco provoca desplazamiento: el DOM semántico se actualiza un fotograma después) y comparar con los controles visibles.

Comportamiento normal de la web, no es un fallo: tras el último control el foco sale de la app hacia el navegador y el siguiente Tab vuelve a entrar.

## Tests automáticos de accesibilidad

`test/presentation/screens/home/home_dashboard_view_test.dart` (grupo «accesibilidad») comprueba en Inicio `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` y que con el texto al 200 % no hay desbordes. Lo mismo hacen `training/training_home_view_test.dart` (Rutinas, con sugerencias desplegadas) y `challenges/challenges_page_view_test.dart` (Retos y su hoja de filtros), en tema claro y oscuro. Para una pantalla nueva, copia ese grupo (la página crea su bloc con `getIt`: registra un `MockBloc` en `setUp` y quítalo en `tearDown`).
