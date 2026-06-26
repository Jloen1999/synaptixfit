# 14 - Historial de Cambios (Changelog)

**Proyecto:** SynaptixFit
**Formato:** [Versionado Semántico](https://semver.org/lang/es/)

---

## [7.3.0] — 27-06-2026

### Sistema de Cálculo Calórico MET (Compendio Adultos 2024)

- **Nuevo servicio:** `CalorieCalculatorService` en `app/lib/features/bienestar/infrastructure/calorie_calculator_service.dart` (116 líneas). Implementa la fórmula científica estándar: `(valorMet × pesoUsuarioKg × duracionSegundos / 3600)` con fallback 70 kg si el peso no está disponible (sin bloquear la UI).
- **5 métodos estáticos:**
  - `calcular()` — calorías para un bloque de ejercicio.
  - `calcularDescanso()` — calorías quemadas en descanso (MET 1.5).
  - `calcularTotal()` — gasto calórico de una lista de bloques con descansos.
  - `derivarMet()` — obtiene el MET desde el campo `valorMet` del catálogo o lo deriva de la modalidad (fuerza=6.0, movilidad=2.3, metabólica=8.0, aeróbica=8.3).
  - `redondear()` — convierte a entero para UI.
- **Nuevo campo `valorMet`** (`DOUBLE PRECISION`, default 6.0) en `EjercicioDb` (modelo `db_models.dart`). Se expone en la vista `v_ejercicios_completos`.
- **`dataset_final.json` actualizado** con 909 ejercicios con `valor_met` asignado por categoría programática:
  - MET 2.3 → 99 ejercicios (movilidad/flexibilidad)
  - MET 3.0 → 186 (fuerza moderada/accesorios)
  - MET 4.5 → 59 (fuerza resistencia)
  - MET 6.0 → 248 (fuerza vigorosa/cargas libres)
  - MET 8.0 → 317 (calistenia + circuitos + metabólico)
- **Scripts de seeding:** `supabase/add_valor_met.py` (asigna MET desde JSON) y `supabase/sync_valor_met.py` (siembra en BD).

### Dualidad Planificación vs Ejecución Real

- **`SeleccionEjercicioDb`:**
  - Campo `duracionSegundos` renombrado a `duracionObjetivoSegundos` (duracción planificada).
  - Nuevo campo `duracionRealSegundos` (`int?`) que captura la duración real medida durante la sesión en vivo.
- **`EjercicioInput`** (`rutina_provider.dart`): mismos cambios (`duracionObjetivoSegundos` + `duracionRealSegundos`).
- **Migración `20260626000021_duracion_real.sql`:** `RENAME duracion_segundos → duracion_objetivo_segundos` + `ADD duracion_real_segundos INTEGER` en `seleccion_de_ejercicios`.

### Sistema de Laps por Timestamp en Entrenamiento Activo

- **`sesion_en_vivo_screen.dart`:**
  - Nuevos maps: `_lapStartTimes` (`Map<String, DateTime>`) y `_duracionRealMap` (`Map<String, int>`).
  - `_capturarLap(seleccionId)`: captura delta con `DateTime.now().difference()`, inmune a backgrounding de la app.
  - Los laps se capturan automáticamente al marcar series completadas y al finalizar la sesión (todos los laps abiertos se cierran).
  - `finalizarSesion()` ahora acepta `Map<String, int> duracionRealPorEjercicio` y persiste `duracion_real_segundos` en `seleccion_de_ejercicios`.
- **`_buildTimerBar()`:** muestra "Objetivo: HH:MM:SS" en gris tenue debajo del cronómetro principal, calculando la suma de `duracionObjetivoSegundos` de todos los ejercicios del día.
- **Cálculo MET en sesión:** usa `duracionRealSegundos` cuando existe (dato real), fallback a `duracionObjetivoSegundos` (proyección).

### Chips de Calorías Clean UI

- **`SemantiCalorieChip`** en `exercise_metrics.dart`: chip con icono de fuego (`Icons.local_fire_department`) y texto "N kcal". Dos modos visuales:
  - **Naranja sólido** (15% opacidad): calorías reales.
  - **Gris tenue** (12% opacidad) con sufijo `(est.)`: calorías estimadas/proyectadas.
- **`buildCalorieChip()`:** función helper que acepta `valorMet`, `pesoUsuarioKg`, `duracionSegundos`, `duracionRealSegundos` opcional, `modalidad` y `esCircuito`. Usa `CalorieCalculatorService.derivarMet()` y `calcular()`. Delega en `SemantiCalorieChip`.
- **`ExerciseMetricsRow` ya NO muestra duración/distancia/isométrico:** estas métricas se movieron a chips independientes junto al chip de calorías.
- **Aplicado en:** `rutina_detalle_screen.dart`, `sesion_en_vivo_screen.dart`, `detalle_reto_screen.dart`, `rutinas_comunidad_screen.dart`.

### Gamificación Transaccional en Retos Fitness

- **`completarReto()` en `retos_provider.dart`:** para retos de tipo `fitness`, calcula las calorías MET de los hitos (o del reto completo si no tiene hitos) usando `CalorieCalculatorService` e inserta una fila en `sesiones_registradas` con `id = retoId`, `tipo = 'reto'` y `calorias_quemadas` calculadas.
- **`descompletarReto()`:** borra la sesión correspondiente → `caloriasAcumuladas` del perfil de actividad se revierte exactamente.
- **`_obtenerPesoUsuario()`:** consulta `perfil_bienestar_usuario` (tabla correcta). Antes consultaba `perfil_bienestar` (tabla inexistente), causando fallback a 70 kg siempre. **Bug corregido.**
- **`_FilaCaloriasEstimadas`** en `detalle_reto_screen.dart`: chip de calorías proyectadas visible en el detalle del reto, incluso antes de completarlo.

### Corrección de bug: `_obtenerPesoUsuario`

- **`rutina_provider.dart` (línea 1825) y `retos_provider.dart` (línea 561):** `_obtenerPesoUsuarioSesion()` / `_obtenerPesoUsuario()` consultaban `perfil_bienestar` (tabla inexistente) → corregido a `perfil_bienestar_usuario`. El fallback 70 kg seguía funcionando, pero ahora los usuarios con peso registrado obtienen cálculos calóricos personalizados.

### Migraciones de BD

- **`20260626000020_valor_met_ejercicios.sql`:** `ALTER TABLE ejercicios ADD COLUMN valor_met DOUBLE PRECISION NOT NULL DEFAULT 6.0` + recrea `v_ejercicios_completos` incluyendo `valor_met` (56 líneas). Aplicada en local y remoto vía `supabase db push`.
- **`20260626000021_duracion_real.sql`:** `RENAME duracion_segundos → duracion_objetivo_segundos` + `ADD duracion_real_segundos INTEGER` en `seleccion_de_ejercicios` (15 líneas). Aplicada en local y remoto.
- **Total migraciones:** 45 → 47.

### Documentación actualizada

- `AGENTS.md`: migraciones 45→47, añadidas entradas `20260626000020` y `20260626000021`, añadido `CalorieCalculatorService` a bienestar/infrastructure, actualizadas descripciones de `EjercicioDb` (valorMet), `SeleccionEjercicioDb` (campos renombrados), `EjercicioInput` (duracionObjetivo/Real), `exercise_metrics.dart` (SemantiCalorieChip, buildCalorieChip), `rutina_provider.dart` (~1912 líneas), `retos_provider.dart` (calorías transaccionales, bug fix peso).
- `docs/14-changelog.md`: Esta entrada.
- `docs/03-architecture.md`: añadido `CalorieCalculatorService` al árbol de bienestar/infrastructure, actualizado `exercise_metrics.dart` (calorie chips), actualizado `db_models.dart` (valorMet, campos renombrados), migraciones 47.
- `docs/04-data-model.md`: `valor_met` en tabla `ejercicios` y ER, campos renombrados en `seleccion_de_ejercicios`, tipo `'reto'` en `sesiones_registradas`, migraciones 0020 y 0021.
- `docs/06-frontend.md`: añadida sección de chips de calorías, actualizada sección de sesión en vivo con laps/timer bar, actualizado `exercise_metrics.dart`.
- `docs/07-backend.md`: migraciones 38→47, añadidas entradas 0020 y 0021 al historial.

---

## [7.2.0] — 23-06-2026

### Localización (i18n) — Español global en widgets Material

- **Nueva dependencia:** `flutter_localizations` (`sdk: flutter`) en `pubspec.yaml`.
- **`main.dart`:** `MaterialApp.router` ahora incluye `localizationsDelegates` (`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`) y `supportedLocales` (`es_ES`, `es`, `en`).
- **Causa raíz documentada:** Antes solo estaba `initializeDateFormatting('es')` + `locale`, pero sin delegates los widgets Material (`showDatePicker`, `showTimePicker`) caían a inglés. Ahora **todos** los `showDatePicker` de la app salen en español.
- **`canvas_screen.dart`:** `DateFormat('d MMM')` → `DateFormat('d MMM', 'es')` en el banner de fechas.

### Eliminación de `gestion_asignaturas_screen.dart`

- **Eliminado:** `app/lib/features/academico/presentation/gestion_asignaturas_screen.dart` (estaba huérfana, sin ruta registrada en GoRouter).
- **`EscanearHorarioBoton` movido** a `app/lib/features/perfil/presentation/perfil_screen.dart`, dentro de la tarjeta "Mis asignaturas" (Perfil > pestaña Académico).
- **Eliminadas** todas las referencias a `GestionAsignaturasScreen` de `docs/` y `AGENTS.md`.

### Escaneo de horarios con IA — Documentado como feature completa

- **`AiScheduleParserService`** (`ai_schedule_parser_service.dart`): Gemini `gemini-2.5-flash` multimodal con `inline_data` base64, prompt determinista que inyecta las asignaturas activas y extrae SOLO el patrón semanal (temperatura 0, topK 1). Saneamiento de Markdown y ensamblaje del paquete `{fecha_inicio_clases, fecha_fin_clases, horarios:[...]}`. Cross-platform con `Uint8List`+`mimeType`. `AiParsingException` para errores.
- **`escanear_horario_provider.dart`:** `guardarFechasSemestre()` + `generarHorariosDesdePaquete()` idempotente vía `ics_uid` sintético.
- **`escanear_horario_boton.dart`:** Flujo Clean UI: verifica fechas de semestre en el perfil → Rama A (pide fechas en BottomSheet y guarda) / Rama B (fricción cero) → `file_picker` con `withData:true` → `LinearProgressIndicator`/`CircularProgressIndicator` → SnackBar «Horario sincronizado con éxito».
- **Integrado en** `perfil_screen.dart` (tarjeta "Mis asignaturas" → pestaña Académico). `PerfilAcademicoDb` con `fechaInicioClases`/`fechaFinClases` + getter `tieneFechasSemestre`.
- **Nuevo diagrama Mermaid** en `docs/03-architecture.md` §6.4 documentando el flujo completo.

### Lienzo Time-Blocking — Arrastre libre de bloques

- **Todos los bloques ahora son arrastrables** (incluidas clases/exámenes). En `canvas_screen.dart` se eliminó la rama no-arrastrable de `_DraggableBlock`. El campo `esHitoInamovible` ya no impide el movimiento.
- **`moveBlock` sin restricciones:** En `calendar_grid_provider.dart`, ya no rechaza por bloque inamovible ni por solapamiento (movimiento libre). Los solapamientos se reportan como avisos en la metadata, no bloquean. **Corregido bug de acarreo** en el cálculo de la hora de fin (ahora usa minutos totales).
- **`resizeBlock` solo impide bajar de 30 min** (permite solapes). También permite redimensionar clases/exámenes.
- **`TimeBlockWidget` sin candado:** Eliminado el icono de candado (`Icons.lock_rounded`) y el parámetro `isLocked` de `_headerRow` (y sus 5 llamadas). `_puedeRedimensionar` ahora es `!esFijo` (las clases/exámenes también se redimensionan).

### Lienzo Time-Blocking — Arrastre entre semanas

- **Chevrons ‹ › como `DragTarget<TimeBlock>`:** En `canvas_screen.dart`, los chevrons de la barra de navegación semanal aceptan bloques soltados sobre ellos. Al soltar, `_moverBloqueASemana(block, delta, state)` mueve el bloque a la semana anterior/siguiente (mismo día y hora) y `navegarSemana(delta)` navega allí.
- **SnackBar** de confirmación («Movido a semana anterior» / «Movido a semana siguiente»).
- **Resaltado visual al pasar por encima** (`onWillAcceptWithDetails`/`onLeave`).
- **Zonas de soltado agrandadas** (`padding` h26/v12) para acertar con facilidad.
- **Nuevo helper** `_moverBloqueASemana(block, delta, state)` + integración con `moveBlock`.
- **Nuevo diagrama Mermaid** en `docs/03-architecture.md` §6.5 documentando el flujo de arrastre.

### Fix de overflow al arrastrar (RenderFlex right overflow)

- **`feedback` del `LongPressDraggable`:** Antes usaba `Transform.scale(1.05)` (agrandaba 5% y sobresalía del grid). Ahora se renderiza al tamaño exacto del bloque dentro de un `Material` transparente.
- **`time_block_widget.dart` `_buildClaseLayout`:** El `Row` de la hora (icono ⏰ + "HH:MM") desbordaba ~1.6px en columnas estrechas. Se envolvió el `Text` en `Flexible` con `TextOverflow.ellipsis`.

### Widget de métricas de ejercicio (`exercise_metrics.dart`)

- **Nuevo archivo:** `app/lib/shared/widgets/exercise_metrics.dart`
- **`SemanticMicroChip`:** Chip semántico de métrica con icono, etiqueta y color contextual.
- **`ExerciseMetricsRow`:** Fila de chips semánticos que visualiza métricas de un ejercicio.
- **`ExerciseMetricCategoria`:** Enum con factory `desdeModalidad()` y `desdeFinalidad()` para clasificar métricas.
- **Aplicado en:** `nueva_rutina_screen.dart`, `rutina_detalle_screen.dart`, `sesion_en_vivo_screen.dart`, `rutinas_comunidad_screen.dart`.

### Mejoras en sesión en vivo (`sesion_en_vivo_screen.dart`)

- **Etiquetas "Serie N"/"Ronda N"** para ejercicios de fuerza/cardio.
- **Feedback visual de ejercicio completado:** Borde verde + badge "Completado" en ejercicios finalizados.
- **Encabezado de columnas Peso/Reps** con icono de mancuerna.

### Mejoras en nueva rutina (`nueva_rutina_screen.dart`)

- **Días vacíos sin ejercicios se omiten al guardar.**
- **Botón "Guardar" en el AppBar.**
- **Aviso de cambios sin guardar** al retroceder (confirmación antes de perder datos).

### Limpieza de código deprecado

- **Eliminados archivos:**
  - `app/lib/features/academico/presentation/crear_plan_semanal_screen.dart`
  - `app/lib/features/academico/application/wizard_plan_provider.dart`
- **Eliminada ruta** `/plan-semanal/crear` e import de `app_router.dart`.
- **Limpieza de lints:**
  - Import sin usar `retos_core.dart` en `rutina_provider.dart`.
  - `prefer_const_declarations` en `timeblock_ia_service.dart` (línea 220).
  - `unnecessary_cast` en `rutina_provider.dart` (líneas 371 y 385).
  - `unused_element_parameter` del parámetro `enabled` en `sesion_en_vivo_screen.dart`.
- **`flutter analyze`: 0 issues.**

### Documentación actualizada

- `AGENTS.md`: migraciones 38 (añadidas `social_publicaciones_v2` y `procedencia_clones`), corrección `integrado en perfil_screen.dart`, eliminadas referencias a `wizard_plan_provider.dart`/`crear_plan_semanal_screen.dart`/`gestion_asignaturas_screen.dart`, añadidos `exercise_metrics.dart` y sección de Localización (i18n).
- `docs/03-architecture.md`: árbol de carpetas actualizado (academico con AI schedule parser, canvas con DragTarget, exercise_metrics), migraciones 38, stack con `flutter_localizations`, nuevos diagramas Mermaid §6.4 (Escaneo IA) y §6.5 (Arrastre Lienzo).
- `docs/06-frontend.md`: ruta `/academico/asignaturas` eliminada, añadida §2.0 Localización (i18n) con causa raíz documentada.
- `docs/07-backend.md`: migraciones 38, tabla completa con 12 nuevas entradas.
- `docs/14-changelog.md`: Esta entrada.
- `docs/20-plan-verificacion-qa.md`: Issues de deprecación marcadas como resueltas, `flutter analyze` actualizado a 0 issues.
- `docs/ESTADO-DOCUMENTACION-DEFINITIVO.md`: `gestion_asignaturas_screen` marcada como eliminada, `flutter analyze` actualizado.
- `docs/00-plan-maestro.md`: `gestion_asignaturas_screen` marcada como eliminada.

---

## [7.1.0] — 18-06-2026

### Refactor Lienzo Continuo v2 — Fases 0, 1 y 2

#### Fase 3 — Integración de distribución de rutina + eliminación botón Rutina

**Eliminación del botón Rutina independiente del canvas:**
- `canvas_screen.dart`: Eliminado el import de `rutina_config_sheet.dart`, el método `_showRutinaConfigSheet()`, y el `OutlinedButton.icon` "Rutina" del bottom bar del canvas.
- El bottom bar ahora solo tiene "← Volver" y "Guardar plan".

**Integración de distribución de rutina en pestaña Deporte de AcademicBlockSheet:**
- `academic_block_sheet.dart`: La pestaña "Deporte" del `SegmentedButton` ahora integra la funcionalidad completa de distribución de rutina:
  - Al seleccionar una rutina, consulta `dias_rutina` reales de la BD (usando columna `semana_id`, NO `semana_rutina_id`).
  - Switch "Distribuir rutina completa" que muestra: selector de días (FilterChips L-D), fecha de inicio (DatePicker), y resumen con total de bloques.
  - Botón cambia entre "Crear sesión de deporte" (bloque individual) y "Distribuir X bloques" (distribución completa vía `placeRutinaDistribuida`).
  - Import de `supabase_flutter` añadido.
  - Variables de estado: `_distribuirRutina`, `_diasDistribucion`, `_fechaInicioDistribucion`, `_totalDiasRutina`, `_cargandoDias`, `_duracionSemanasRutina`.
  - Métodos nuevos: `_cargarTotalDias()`, `_buildDistribucionSection()`, `_buildFechaInicioPicker()`, `_buildDistribucionResumen()`.

**`RutinaConfigSheet` conservado pero ya no usado desde canvas:**
- `rutina_config_sheet.dart` sigue existiendo como widget pero ya no se importa ni usa desde `canvas_screen.dart`. Toda la funcionalidad de distribución está ahora en `academic_block_sheet.dart`. El sheet solo es invocado por `placeRutinaDistribuida` desde `calendar_grid_provider.dart`.

**Edición de nombres de semanas y días en nueva_rutina_screen.dart:**
- Ahora permite al usuario editar los nombres de semanas y días:
  - Maps `_nombresSemanas` y `_nombresDias` para almacenar nombres personalizados.
  - Icono de lápiz (edit) junto a cada chip de semana y cada card de día para editar el nombre vía dialog con TextField.
  - Métodos nuevos: `_editarNombreSemana(int semana)`, `_editarNombreDia(int semana, int dia)`.
  - Los nombres se pasan a `crearRutinaCompleta()` que ya aceptaba `nombresSemanas` y `nombresDias` pero nunca recibía datos.
  - `_eliminarSemana` y `_eliminarDia` ahora limpian los maps de nombres.
  - `_DiaEditorCard` ahora acepta `nombre` y `onEditNombre` como parámetros.

**Indicador visual de rutina en TimeBlockWidget:**
- `time_block_widget.dart`: Bloques de deporte distribuidos desde una rutina (`diaRutinaId != null`) ahora muestran:
  - Barra vertical blanca semitransparente a la izquierda como indicador visual de pertenencia a rutina.
  - Header muestra el nombre del día de la rutina (ej: "Torso", "Día 1").
  - Subtitle muestra el nombre de la rutina en texto tenue (ej: "Push Pull Legs").

**Bug fix: columna `semana_id` en queries de `dias_rutina`:**
- `calendar_grid_provider.dart`: En `placeRutinaDistribuida`, corregidas 3 referencias de `semana_rutina_id` → `semana_id` (select, inFilter, acceso al map). La columna real en `dias_rutina` es `semana_id`, no `semana_rutina_id` (que existe en `horarios_academicos`).
- `rutina_config_sheet.dart`: Misma corrección + consulta async al seleccionar rutina para mostrar el total real en el UI.
- Código deprecado: `inyectarRutinaCascada` mantiene el tag `@Deprecated` por usar columnas inexistentes (`dia_semana`, `enfoque`) en `dias_rutina`.

### Documentación actualizada
- `AGENTS.md`: migraciones 24→26, actualizadas descripciones de `canvas_screen.dart` (sin botón Rutina), `academic_block_sheet.dart` (distribución rutina integrada), `nueva_rutina_screen.dart` (nombres editables), `time_block_widget.dart` (indicador visual rutina), `rutina_config_sheet.dart` (deprecado de canvas).
- `docs/06-frontend.md` → v7.1: §21.6.2 actualizado con eliminación de botón Rutina; §21.6.3 enriquecido con indicador visual de rutina; nueva §21.6.5 documentando `AcademicBlockSheet` con pestaña Deporte.
- `docs/14-changelog.md`: Esta entrada.

---
#### Fase 0 — Coherencia del Ecosistema

**`toggleBloqueCompletado()` activado en `plan_semanal_screen.dart`:**
- Los bloques de estudio/deporte ahora muestran un checkbox para marcarlos como completados directamente en la vista de Plan Semanal.
- Al marcar un bloque: actualiza `horarios_academicos.completado = true`, otorga XP (`ceil(mins/30) × 10`), emite evento `bloqueEstudioCompletado` al SyncHub.

**SyncHub — 4 eventos nuevos activados:**
- `sesionCompletada` → emitido en `finalizarSesion()` (`rutina_provider.dart`). Invalida `dashboardProvider`, `timelineHoyProvider`, `perfilActividadProvider`.
- `checkInRealizado` → emitido en `guardarEstadoDiario()` (`rutina_provider.dart`). Invalida `estadoDiarioHoyProvider`, `estadoEnergeticoProvider`.
- `entregaCompletada` → emitido en `toggleEntregaCompletada()` (`entregas_examenes_provider.dart`). Invalida `contextoAcademicoProvider`, `timelineHoyProvider`.
- `retoCompletado` → emitido en `completarReto()` (`retos_provider.dart`). Invalida `dashboardProvider`, `retosActivosProvider`, `timelineHoyProvider`.

**`BalanceSemanalDto` corregido:**
- Ahora usa datos reales de `completado` desde `horarios_academicos` y `carga_academica_semanal` en vez de multiplicadores hardcodeados (0.9/0.85).
- El cálculo de adherencia refleja el progreso real del usuario, no estimaciones.

**`InsigniaEngine` — nuevo criterio `semanas_plan_adherencia`:**
- Insignia "Planificador Maestro": 4 semanas consecutivas con ≥80% de adherencia al plan semanal.
- Nueva métrica consulta `carga_academica_semanal` para calcular semanas consecutivas con `horas_reales / horas_planeadas ≥ 0.8`.
- El engine ahora evalúa 13 criterios (antes 12).

#### Fase 1 — Infraestructura de Datos

**Nueva migración `20260618000022_lienzo_continuo.sql`:**
- Amplía CHECK de `tipo_actividad` en `horarios_academicos` (8 valores: estudio, deporte, clase, descanso, comida, sueno, examen, entrega).
- Nueva FK `entrega_examen_id` → `entregas_examenes(id)` para vincular bloques de estudio con exámenes/entregas.
- Nuevas columnas en `entregas_examenes`: `descripcion TEXT`, `hora_inicio_str TEXT`.
- Amplía CHECK de `tipo` en `entregas_examenes` (6 valores: entrega, examen, proyecto, quiz, presentacion, otro).
- Nuevo índice `idx_horarios_fecha_inicio` para navegación semanal.

**Nueva migración `20260618000023_lienzo_continuo_v2.sql`:**
- Nueva columna `es_hito_inamovible BOOLEAN NOT NULL DEFAULT false` en `horarios_academicos`. Protege bloques de exámenes y entregas contra arrastre accidental.
- Nuevo índice `idx_horarios_fecha_rango ON horarios_academicos(usuario_id, hora_inicio)` para consultas por rango de fechas.

**Modelo `HorarioAcademicoDb`:**
- Nuevo campo `esHitoInamovible` (`bool`, default `false`). Serializado en `fromMap()`/`toMap()`.

**DTO `TimeBlock`:**
- Nuevos campos: `fecha` (`DateTime?`), `esHitoInamovible` (`bool`).
- Nuevo getter `diaSemanaEfectivo`: calcula el día de la semana real desde `fecha` si está presente; fallback al `diaSemana` almacenado.

**DTO `CalendarGridState`:**
- Nuevos campos: `semanaOffset` (`int`, default `0`), `fechaInicioPantalla` (`DateTime`, default `DateTime.now()`).
- Nuevo getter `fechaFinPantalla`: `fechaInicioPantalla + 6 días`.

**`GridMath` — 5 nuevos métodos para navegación por fecha:**
- `fechaToColumnIndex(DateTime fecha, DateTime fechaBase)` → `int` — convierte una fecha al índice de columna (0-6) en el grid.
- `columnIndexToFecha(int columna, DateTime fechaBase)` → `DateTime` — convierte un índice de columna a la fecha correspondiente.
- `fechaToOffsetX(DateTime fecha, DateTime fechaBase)` → `double` — posición X en píxeles para una fecha dada.
- `offsetXToColumnIndex(double offsetX)` → `int` — índice de columna desde una posición X en píxeles.
- `dayHeaderLabel(DateTime fecha)` → `String` — etiqueta legible para el header de día (ej: "Lun 15").

**Nueva migración `20260618000019_fix_duplicate_fk_rutina.sql`:**
- Elimina FK duplicada `horarios_academicos_rutina_id_fkey` que causaba error PostgREST PGRST201.

#### Fase 2 — Navegación Temporal Infinita + Limpieza IA

**Eliminación de botones IA del flujo Time-Blocking:**
- **Eliminado:** Botón "Autocompletar con IA" (`AutocompleteFab` en `canvas_helpers.dart`). La generación IA ahora ocurre automáticamente al inicializar el canvas, no como acción explícita del usuario.
- **Eliminado:** Botón "Generar mi semana" del `InboxScreen`. Reemplazado por botón "Ir al Canvas" que navega directamente al lienzo.

**Canvas refactorizado — Lienzo Continuo:**
- **Primera columna = Hoy:** La columna izquierda del grid siempre corresponde al día actual, facilitando orientación inmediata.
- **Navegación semanal infinita:** Botones `< Anterior` y `Siguiente >` permiten navegar semanas hacia adelante y atrás sin límite. El `CalendarGridState` mantiene `semanaOffset` y `fechaInicioPantalla` para controlar la semana visible.
- **Barra de navegación:** Muestra el rango de fechas de la semana actual (ej: "Sem 15-21 Jun 2026") con botón `Hoy` para retorno rápido a la semana actual.
- **Fondo oscuro:** `#1A1A2E` (dark navy) aplicado al canvas completo. Reduce fatiga visual en sesiones largas de planificación y mejora el contraste de los bloques coloreados.
- **Eje horario inline:** Las etiquetas de hora (07:00, 08:00...) flotan sobre las líneas del grid en la columna izquierda, eliminando la necesidad de una columna de etiquetas separada.
- **Barra inferior simplificada:** Solo 2 botones: `Volver` (navega al inbox) y `Guardar` (persiste la semana en `horarios_academicos`).

#### Documentación actualizada
- `AGENTS.md`: migraciones 21→24, actualizadas descripciones de `insignia_engine.dart` (13 criterios), `calendar_dtos.dart` (nuevos campos), `GridMath` (5 nuevos métodos), lista de migraciones con 0019, 0022, 0023.
- `docs/04-data-model.md` → v5.6: columna `es_hito_inamovible` en `horarios_academicos`, índice `idx_horarios_fecha_rango`, migración 0023 documentada.
- `docs/06-frontend.md` → v7.0: §21 reescrita con Lienzo Continuo, navegación infinita, fondo oscuro, checkbox de completado, eliminación de `AutocompleteFab` y "Generar mi semana".
- `docs/14-changelog.md`: Esta entrada.

---

## [7.0.0] — 17-06-2026

### Sprint Time-Blocking — Planificación Semanal con IA (Custom Grid Nativo)

#### Decisión de Arquitectura: Syncfusion DESCARTADO
- **Syncfusion Flutter Calendar:** Descartado por licencia de pago (~$995/año), +15MB APK, configuración acoplada a SfCalendar, sobreingeniería para el caso de uso.
- **Custom Grid Nativo (SELECCIONADO):** `Stack` + `Positioned` + `Draggable` + `DragTarget`. 0 dependencias nuevas. Control total del renderizado. Matemática hora↔píxel explícita.

#### Nueva migración `20260617000011_timeblocking.sql` (PLANIFICADA)
- **Nuevas columnas en `horarios_academicos`:** `es_fijo BOOLEAN DEFAULT true` (distingue horarios fijos de bloques generados por IA), `dia_semana INT CHECK (1-7)` (anclaje a día semanal).
- **Nuevo índice:** `idx_horarios_dia_semana` para consultas rápidas por día.

#### Nuevo módulo `academico/`
- **Rutas:** `/academico/planificar` (Inbox), `/academico/planificar/canvas` (Canvas semanal)
- **Providers (3):** `inboxConfigProvider`, `horariosFijosProvider`, `calendarGridProvider`
- **Servicio IA:** `TimeblockIaService` (clase, no Riverpod) — Gemini Flash con reglas N1-N10, validación post-IA, fallback determinista
- **Widgets (6):** `InboxScreen`, `CanvasScreen`, `TimeGridPainter`, `TimeBlockWidget`, `ProgressGamificationBar`, `SuggestedBlockWidget`
- **Servicio IA:** `TimeBlockIaService` — Gemini Flash con reglas N1-N10, validación post-IA, fallback determinista
- **Matemática del grid:** `horaToY()`, `yToHora()`, `duracionToHeight()`, `diaToX()` con constantes `PIXELS_PER_HOUR=80`, `HOUR_START=7`, `COLUMN_WIDTH=120`

#### Sistema de colores Flat Design (8 colores por tipo de bloque)
Azul acero (`#4A90D9`=clase), azul estudio (`#3B82F6`=estudio), naranja (`#FF8C42`=deporte), rojo (`#E74C3C`=entrega), verde (`#27AE60`=descanso), gris (`#95A5A6`=libre), amarillo (`#F1C40F`=examen), teal (`#1ABC9C`=pomodoro).

#### Gamificación integrada
- Barra de progreso semanal (adherencia al plan)
- XP de estudio (150 XP al cumplir ≥80% del plan semanal)
- Insignia "Planificador Maestro" (4 semanas consecutivas con ≥80%)

#### Documentación actualizada (10 archivos)
- `docs/04-data-model.md`: Columnas `es_fijo`, `dia_semana` en `horarios_academicos`
- `docs/06-frontend.md`: §21 Time-Blocking con Custom Grid nativo, matemática, widgets
- `docs/07-backend.md`: §12 `TimeBlockIaService` con reglas N1-N10, prompt, fallback
- `docs/12-user-guide.md`: §4.5 reescrito con flujo "Generar mi semana" (5 subsecciones)
- `docs/15-ia-recomendacion-sistema.md`: §19 IA para Time-Blocking Académico
- `docs/02-requirements.md`: CU-36/37/38, HU-69-72, CA-42-44, Fase 4 en §16
- `docs/00-plan-maestro.md`: Sprint Time-Blocking documentado, Syncfusion descarte explicado
- `docs/03-architecture.md`: Módulo `academico/` en árbol de carpetas
- `docs/14-changelog.md`: Esta entrada
- `AGENTS.md`: Conteo de migraciones 17→21, nuevas carpetas

#### 0 dependencias nuevas
Sin cambios en `pubspec.yaml`. Todo el time-blocking usa widgets nativos de Flutter. `fl_chart` ya estaba instalado (Sprint 7B).

---

#### Nueva migración `20260616000010_admin_delete_user.sql`
- **Nueva RPC `delete_user(p_usuario_id)`:** eliminación hard de usuario desde el panel de administración. Elimina 28+ tablas de historial + perfiles + `auth.users`. Solo admin, no puede auto-eliminarse.

#### Mejoras en el panel de administración

**Delete User (hard delete):**
- RPC `delete_user(p_usuario_id)` con eliminación en cascada FK-safe de 28+ tablas, incluyendo `auth.users`
- Botón "Eliminar usuario" en la lista de usuarios (`AdminPanelScreen`) y en el detalle (`AdminUsuarioDetalle`)
- Diálogo de confirmación con advertencia "Esta acción es irreversible"
- Registro automático en `admin_auditoria` con `accion = 'delete_user'`

**Dashboard KPIs — Gráfico de tendencia 30 días:**
- `AdminKpiDashboard` ahora incluye un gráfico `LineChart` de `fl_chart` bajo el grid de KPIs
- Muestra la tendencia de registros diarios de los últimos 30 días desde `adminRegistrosDiariosProvider`
- Tooltips con fecha y valor exacto

**Filtros y ordenamiento en lista de usuarios:**
- `AdminPanelScreen` con filtros por email, nombre y rol
- Ordenamiento por fecha de registro, nivel o XP
- Debounce de 300ms en campo de búsqueda

**Detalle de usuario enriquecido — Configuración:**
- `AdminUsuarioDetalle` ahora incluye sección de configuración de usuario:
  - Editar nombre (`actualizarNombre()`)
  - Editar email
  - Reset XP (setea `xp_total = 0`, registra en `admin_auditoria`)
  - Cambiar nivel manualmente
  - Botón "Eliminar usuario" (hard delete)
- Actividad reciente del usuario visible en la pestaña Timeline
- Conteos de retos, rutinas e insignias en la pestaña Perfil

**Fix de imágenes:**
- `errorBuilder` añadido a todos los `Image.network` en widgets admin (`AdminPanelScreen`, `AdminUsuarioDetalle`) para manejar avatares con URL inválida mostrando fallback con inicial

#### Archivos modificados (admin)
- `infrastructure/admin_repository.dart` — extendido con `deleteUser()` y consulta de detalle ampliada
- `application/admin_provider.dart` — añadido `eliminarUsuario()` + mutaciones de configuración
- `presentation/admin_panel_screen.dart` — filtros, ordenamiento, botón eliminar
- `presentation/admin_usuario_detalle.dart` — secciones nuevas (configuración, actividad reciente), botón eliminar
- `presentation/widgets/admin_kpi_dashboard.dart` — gráfico de tendencia 30 días con `fl_chart`

#### Documentación actualizada
- `AGENTS.md`: migraciones 12→13, módulo admin actualizado con nuevas funcionalidades
- `docs/00-plan-maestro.md`: añadidos módulos F (Delete User), G (Gráfico KPIs), H (Filtros), I (Configuración)
- `docs/04-data-model.md` → v5.5: RPC `delete_user` documentada con SQL completo, comparativa con `wipe_user_data`
- `docs/06-frontend.md` → §20: Panel de Administración actualizado con delete user, gráfico tendencia, filtros/ordenamiento, configuración
- `docs/07-backend.md`: migración 0010 añadida al historial
- `docs/18-implementacion-admin.md` → v1.1: Fase 3 documentada con delete user, configuración, gráfico KPIs
- `docs/14-changelog.md`: Esta entrada

---

## [6.7.0] — 15-06-2026

### Panel de Administración — Fase 1 MVP ✅ IMPLEMENTADO

Implementación del MVP del panel de administración v2: Hub con 3 tabs (KPIs, Usuarios, Auditoría), dashboard de métricas globales y trazabilidad de acciones administrativas.

#### Nueva migración `20260616000009_admin_panel_v2.sql`
- **Nueva tabla `admin_auditoria`:** trazabilidad de todas las acciones administrativas. Campos: `id`, `admin_id` (FK → usuarios), `target_usuario_id` (FK → usuarios), `accion` (CHECK: wipe/reset_xp/set_nivel/ocultar_ejercicio/moderar), `detalles` JSONB, `creado_en`. RLS: SELECT + INSERT solo admin. Índices en `admin_id`, `target_usuario_id`, `creado_en`.
- **Nueva vista `v_admin_metricas`:** 10 KPIs globales agregados: `total_usuarios`, `nuevos_esta_semana`, `usuarios_activos_semana`, `sesiones_esta_semana`, `retos_creados_semana`, `publicaciones_semana`, `publicaciones_reportadas`, `comentarios_reportados`, `insignias_otorgadas`, `nivel_promedio`.
- **Columnas de moderación en `actividades_sociales`:** `reportado` (BOOLEAN), `reportado_por` (UUID FK), `esta_eliminado` (BOOLEAN), `eliminado_por` (UUID FK), `eliminado_en` (TIMESTAMPTZ).
- **Columnas de moderación en `comentarios_feed`:** `reportado` (BOOLEAN), `reportado_por` (UUID FK).
- **Columna de catálogo en `ejercicios`:** `activo` (BOOLEAN DEFAULT true) con índice.
- **Nuevas políticas RLS admin:** UPDATE/DELETE en `actividades_sociales`, UPDATE en `comentarios_feed`, UPDATE en `ejercicios`.

#### Archivos implementados en `features/admin/` (14 nuevos + 5 modificados)

**Domain (3 DTOs nuevos):**
- `admin_kpi_dto.dart` — `AdminMetricasGlobales` con 10 campos y `fromMap`
- `admin_auditoria_dto.dart` — `AuditoriaRegistro` con enum `AccionAuditoria`
- `admin_contenido_dto.dart` — `ContenidoReportado`
- `admin_dto.dart` — `UsuarioAdmin` (existente, mantenido)

**Infrastructure (2 repositorios nuevos):**
- `admin_metricas_repository.dart` — `obtenerMetricasGlobales()`, `obtenerRegistrosDiarios()`
- `admin_auditoria_repository.dart` — `insertarAuditoria()`, `consultarLogs()`
- `admin_repository.dart` — `AdminRepository` (existente, extendido)

**Application (2 providers files nuevos + 1 extendido):**
- `admin_provider.dart` (extendido) — `esAdminProvider`, `adminUsuariosProvider`, `adminUsuarioDetalleProvider`, `resetXpUsuario()`, `setNivelUsuario()`
- `admin_metricas_provider.dart` — `adminMetricasProvider`, `adminRegistrosDiariosProvider`
- `admin_auditoria_provider.dart` — `adminAuditoriaProvider`, `registrarAuditoria()`

**Presentation (6 widgets + 2 pantallas refactorizadas):**
- `admin_hub_screen.dart` — **Nuevo.** `ConsumerStatefulWidget` con `TabBar` (3 tabs: KPIs, Usuarios, Auditoría)
- `admin_panel_screen.dart` — **Refactorizado.** Pestaña "Usuarios" con búsqueda y acciones (reset XP, set nivel, wipe)
- `admin_usuario_detalle.dart` — **Enriquecido.** 3 sub-pestañas (Perfil/Estadísticas/Timeline)
- `widgets/admin_kpi_dashboard.dart` — Grid 2×3 KPIs
- `widgets/admin_kpi_card.dart` — Card individual con icono, valor, tendencia (↑↓→)
- `widgets/admin_log_entry.dart` — Fila de log con badge por tipo de acción
- `widgets/admin_auditoria_list.dart` — Lista paginada de registros de auditoría
- `widgets/admin_paginacion_bar.dart` — Barra de paginación reutilizable
- `widgets/admin_wipe_dialog.dart` — Refactorizado con registro en `admin_auditoria`

#### Routing
- `app_router.dart`: ruta `/admin` → `AdminHubScreen` (reemplaza `AdminPanelScreen`)

#### Documentación actualizada
- `AGENTS.md`: migraciones 11→12, módulo admin extendido (7 DTOs, 6 repos, 6 provider files, 15 widgets/pantallas)
- `00-plan-maestro.md` → v1.5: Fase 2 marcada COMPLETADO, checkboxes actualizados con implementación real
- `18-implementacion-admin.md` → v1.0: Fase 1 MVP y Fase 2 marcadas COMPLETADO, tablas de archivos actualizadas con realidad vs plan
- `03-architecture.md`: árbol admin actualizado con archivos Fase 2 (34 archivos, 5 tabs)
- `06-frontend.md` → §20: Panel de Administración actualizado con 5 tabs reales y widgets completos
- `14-changelog.md`: Esta entrada actualizada con implementación real Fase 1 MVP + Fase 2

#### Fase 2 — Moderación, Ejercicios, Gráficos y Timeline ✅ COMPLETADO — 15/06/2026

**Archivos implementados en `features/admin/` (15 nuevos + 2 modificados):**

**Domain (3 DTOs nuevos):**
- `admin_ejercicio_dto.dart` — `AdminEjercicio` con campo `activo`
- `admin_usuario_estadisticas_dto.dart` — `AdminUsuarioEstadisticas` + `AdminDataPoint`
- `admin_timeline_dto.dart` — `AdminTimelineEntry` + enum `TimelineTipoAdmin`

**Infrastructure (3 repositorios nuevos):**
- `admin_contenido_repository.dart` — `listarContenidoReportado()`, `aprobarContenido()`, `eliminarContenido()`
- `admin_ejercicio_repository.dart` — `listarEjercicios()`, `toggleActivo()`
- `admin_usuario_stats_repository.dart` — `obtenerRpeSemanal()`, `obtenerVolumenSemanal()`, `obtenerTimeline()`

**Application (3 provider files nuevos):**
- `admin_contenido_provider.dart` — `adminContenidoReportadoProvider`, mutaciones `moderarPublicacion()`, `moderarComentario()`
- `admin_ejercicio_provider.dart` — `adminEjerciciosProvider`, `adminEjercicioToggleProvider`
- `admin_usuario_stats_provider.dart` — `adminUsuarioStatsProvider`, `adminUsuarioTimelineProvider`

**Presentation (6 widgets nuevos + 2 modificados):**
- `admin_contenido_card.dart` — Card de contenido reportado con botones aprobar/eliminar
- `admin_contenido_list.dart` — Lista paginada de publicaciones/comentarios reportados
- `admin_ejercicio_card.dart` — Card con `Switch` activo/inactivo + `AlertDialog` de confirmación
- `admin_ejercicio_list.dart` — Lista paginada de ejercicios con búsqueda por nombre/dificultad/grupo
- `admin_graficos_usuario.dart` — `LineChart` RPE semanal + `BarChart` volumen semanal con `fl_chart`
- `admin_timeline_usuario.dart` — Timeline vertical cronológica de actividad del usuario
- `admin_usuario_detalle.dart` — **Modificado.** Placeholders de estadísticas y timeline reemplazados por widgets reales
- `admin_hub_screen.dart` — **Modificado.** `TabController(length: 3)` → `TabController(length: 5)`; añadidos tabs Contenido y Ejercicios

#### Conteo final del panel admin (Fase 1 + Fase 2)
- **7 DTOs** en `domain/`
- **6 repositorios** en `infrastructure/`
- **6 provider files** en `application/` (10 providers individuales + 8 mutaciones)
- **15 widgets/pantallas** en `presentation/` (3 pantallas + 12 widgets)
- **Total:** 34 archivos en `features/admin/`

---

## [6.6.0] — 15-06-2026

### Plan de estudios en PerfilScreen + Asignaturas transversales

#### Fase 1 — Mapeo de transversales (BD)
- **Nueva migración `20260616000008_asignaturas_usuario_semestre.sql`:** tabla `asignaturas_usuario_semestre(id, usuario_id, asignatura_id, curso, semestre)` con RLS propietario + admin bypass y UNIQUE(usuario_id, asignatura_id). Permite a usuarios mapear asignaturas sin temporalidad fija (semestre=0) a un curso y semestre específicos.

#### Fase 2 — Modelo Dart y Providers
- **Nuevo modelo `AsignaturaUsuarioSemestreDb`** en `db_models.dart` (línea 1838): 6 campos (id, usuarioId, asignaturaId, curso, semestre, creadoEn) con `fromMap`/`toMap`.
- **Nuevo provider `carreraConAsignaturasProvider`:** carreras del usuario con asignaturas del catálogo. Busca por `usuario_carreras` (FK) primero; fallback a búsqueda por nombre.
- **Nuevo provider `asignaturasUsuarioSemestreProvider`:** lista de mapeos del usuario desde `asignaturas_usuario_semestre`.
- **Nuevo provider `asignaturasSinSemestreProvider`:** asignaturas del catálogo con `semestre=0` (optativas/transversales).
- **Nueva función helper `_getCarrerasUsuario()`:** devuelve `carrera_id` del usuario lógica compartida.

#### Fase 3 — UI: Stats + Plan de estudios
- **Header de stats:** Ahora muestra 4 stats en `Row` con `Expanded`: Sesiones, XP, Calorías, Retos (XP como 4ª stat entre Sesiones y Calorías).
- **Nueva sección "Plan de estudios":** cards de curso con contador de asignaturas en tiempo real, incluyendo transversales mapeadas (ej: "5+1 asig.").
- **Sección colapsable "Asignaturas transversales":** `ExpansionTile` con lista de optativas sin semestre. Botón **+** para mapear al curso/semestre actual. Botón **✕** para quitar el mapeo.
- **Curso** como línea editables (RadioGroup 1→maxCurso). **Semestre** editable con dropdown `RadioGroup<int>` de solo [1, 2] (1° o 2° semestre).
- **Créditos/Horas del semestre:** calculados desde `asignaturas_catalogo` + transversales mapeadas al curso/semestre actual.

#### Fase 4 — Seed fix
- **Eliminado duplicado** "FUNDAMENTOS DE REDES" (Curso 1) de la carrera ITT en `grados.json`. La asignatura ya existía en Curso 2 correctamente; se eliminó la entrada duplicada en Curso 1 que causaba conflictos.

#### Documentación
- `00-plan-maestro.md`: migraciones 10→11, añadida migración 0008
- `03-architecture.md`: migraciones 10→11, db_models 2004→2330 líneas, 40+→42+ modelos
- `04-data-model.md`: migraciones 10→11, nueva tabla `asignaturas_usuario_semestre` con SQL, RLS y modelo Dart
- `06-frontend.md`: stats actualizados (Row 4 columnas), nuevos providers, §7.7 Plan de estudios con cards de curso, transversales colapsable, edición curso/semestre
- `07-backend.md`: migraciones 10→11, entrada 0008 añadida al historial
- `08-installation.md`: migraciones 10→11
- `14-changelog.md`: Esta entrada

---

## [6.4.0] — 13-06-2026

### Sprint 9 — Pomodoro, Escanear, Social, Insignias y Refactor

#### Fase 9B — Refactor de capas y limpieza
- **Eliminadas 5 dependencias sin usar:** `reorderable_grid_view`, `lottie`, `cupertino_icons`, `url_launcher`, `image_picker`
- **Corregido typo** `EjericicioRecienteDto` → `EjercicioRecienteDto` (6 ocurrencias)
- **DTOs extraídos a domain/** en `bienestar/` (3 archivos: ejercicio_recomendado, recomendacion_result, historial_sesion)
- **Capas domain/ creadas** en `auth/`, `academico/`, `perfil/`
- **Capas infrastructure/ creadas** en `academico/`, `perfil/`
- **Esqueletos creados** en `social/` y `notificaciones/` (domain + infrastructure + application)

#### Fase 9A — QuickActions: Pomodoro y Escanear
- **Pomodoro:** nuevo feature `pomodoro/` con temporizador de estudio (25/5 min), StateNotifier con Timer.periodic, anillo CustomPainter, ruta `/pomodoro`
- **Escanear:** nuevo feature `escanear/` con abstracción ScannerService, pantalla dual Web/Mobile, guardado como apunte Markdown, ruta `/escanear`
- **QuickActionsRow:** placeholders reemplazados por navegación real a `/pomodoro` y `/escanear`

#### Fase 9C — Social Core: Comentarios y Feed
- **Nueva tabla** `comentarios_feed` con RLS (autor edita/elimina)
- **SocialRepository** con CRUD real: feed paginado con JOINs, likes persistentes, comentarios
- **6 providers Riverpod:** socialFeedProvider, socialCommentsProvider.family, likeStateProvider.family, toggleLike, publicarEnFeed, enviarComentario
- **Nuevos widgets:** FeedItemCard (comentarios expandibles), ComentarioCard, ComentarioInput
- **MuroSocialScreen** refactorizado a ConsumerStatefulWidget con FAB funcional
- **Retos → feed:** completar reto publica automáticamente en el feed social

#### Fase 9D — Insignias y Rachas Avanzadas
- **Nuevas tablas** `insignias` (catálogo público 15 insignias) + `usuario_insignias` (M:N)
- **InsigniaEngine:** evalúa 12 criterios (sesiones, RPE, retos, racha, bloom_estudio, apuntes, publicaciones, likes, checkins, insignias) y otorga automáticamente
- **RachaService:** cálculo de días consecutivos, detección de riesgo (<4h), hitos (7/30/100/365), mejor racha histórica
- **6 providers Riverpod:** catalogoInsigniasProvider, insigniasUsuarioProvider, rachaStateProvider, insigniasRecienObtenidasProvider, evaluarInsignias()
- **Nuevos widgets:** InsigniasScreen (grid + filtro 6 categorías), InsigniaCard (color por rareza), InsigniaToast (animación slide-up), RachaIndicator (barra progreso + alerta riesgo)
- **Integrado en:** dashboard (toast automático), perfil (sección insignias + racha), finalizarSesion() y completarReto() (evaluación automática)

#### Fase 9E (Fase B) — Correcciones de flujos y datos
- **fecha_inicio en rutinas:** campo `fecha_inicio` ahora se persiste correctamente al crear y clonar rutinas
- **Filtro retos expirados:** los retos con `fecha_fin < today` se excluyen de `retosActivosProvider` y no aparecen en timeline
- **Fix `logrosCountProvider`:** corregido conteo de logros que incluía datos de otros usuarios por falta de filtro `usuario_id`

#### Fase 9F (Fase C) — Corrección de horas fabricadas en TimelineItem
- **7 fixes en `TimelineItem`:**
  - `desdeHorario()`: corregida asignación de `horaInicio`/`horaFin` desde columnas reales de `horarios_academicos`
  - `desdeSesion()`: corregida `duracionMinutos` extraída de `sesiones_registradas` en lugar de valor fabricado
  - `desdeEntrega()`: corregida `fechaEntrega` desde `entregas_examenes.fecha_entrega` real
  - `desdeReto()`: corregida `fechaFin` desde `retos.fecha_fin` y cálculo de `diasRestantes`
  - `desdeDiaPendiente()`: corregida extracción de `diaId` y `rutinaId` desde el provider unificado
  - `ordenarPorHora()`: corregida comparación para evitar `null` en hora
  - `metadata`: corregidos parámetros inconsistentes entre factory constructors

#### Fase 9G (Fase D) — Hitos en timeline y KPIs movidos a SaludoCard
- **Hitos en timeline:** items de tipo `reto` ahora muestran hitos completados con badge (ej. "3/5 hitos")
- **KPIs movidos:** los indicadores de racha, nivel y XP se integran visualmente en `SaludoCard` en lugar de `StreakRow` independiente
- **SaludoCard unificado:** avatar + nombre + nivel + XP + racha + estado energético en un solo widget cohesivo

#### Fase 9H (Fase E) — DatePicker y TimePicker
- **DatePicker en `nueva_rutina_screen`:** selector de fecha para `fecha_inicio` usando `showDatePicker()` nativo de Flutter. Se persiste al crear la rutina y se muestra en `RutinaDetalleScreen`.
- **TimePicker en entregas:** `showTimePicker()` para hora de entrega en `crear_entrega_screen.dart` y `editar_entrega_screen.dart`. Reemplaza el campo de texto manual por un selector de hora nativo.
- **Formato 24h consistente:** ambos pickers usan `TimeOfDayFormat.HH_colon_mm` y se almacenan como `TIME` en BD.

#### Migración de Consolidación (0004) — 16-06-2026
- **3 tablas nuevas:** `planes_estudio` (planificación semanal), `apuntes` (notas Markdown), `sesiones_focus` (registro Pomodoro)
- **1 vista:** `v_ejercicios_completos` actualizada con `string_agg` y columnas nuevas (`url_preview`, `modalidad_entrenamiento`, `tipo_medicion`, `es_circuito`)
- **19 columnas añadidas** a 9 tablas existentes:
  - `rutinas`: `estado`, `objetivo`, `duracion_semanas`
  - `asignaturas`: `archivado`, `docente`
  - `horarios_academicos`: `plan_estudio_id`, `prioridad`, `tipo_actividad`, `rutina_id`, `temas`
  - `seleccion_de_ejercicios`: `dia_id`
  - `sesiones_registradas`: `dia_id`, `tipo`
  - `perfil_bienestar_usuario`: `ciudad`
  - `actividades_sociales`: `metadata`
  - `hitos_de_reto`: `estado`, `dependencias`, `tipo_condicion`, `condicion_n`
  - `retos`: `tiene_dependencias`
- **5 índices nuevos** para rendimiento (rutinas, horarios, sesiones, selección)
- **Constraint corregido:** `notificaciones.prioridad` ampliado para aceptar `'baja'`

#### Documentación
- `02-requirements.md`: CU-27→30, HU-51→56, CA-29→32 añadidos
- `06-frontend.md`: §§16-19 añadidas (Pomodoro, Escanear, Social, Insignias)
- `AGENTS.md`: migraciones actualizadas (7→8), añadida referencia a `0005_fechas_coherencia`
- `00-plan-maestro.md`: Sprint 9 COMPLETADO, migraciones 7→8
- `09-testing.md`: nuevos módulos documentados
- `04-data-model.md` → v5.2: nuevas tablas `planes_estudio`, `apuntes`, `sesiones_focus`; vista `v_ejercicios_completos` actualizada; columnas añadidas a 9 tablas existentes
- `03-architecture.md`: migraciones actualizadas (7→8), añadida migración 0005
- `07-backend.md`: migraciones actualizadas (7→8), entrada 0005 añadida al historial
- `08-installation.md`: migraciones actualizadas (7→8)
- `14-changelog.md`: Esta entrada + Fases 9E-9H añadidas

#### Corrección de Flujos (Fase 2)
- **Invalidaciones corregidas:** `crearRutinaCompleta()`, `guardarRutina()`, `finalizarSesion()` ahora invalidan `dashboardProvider` y `timelineHoyProvider` correctamente
- **Reactividad en timeline:** `timelineHoyProvider` usa `ref.watch(diaPendienteProvider)` para actualizarse automáticamente
- **Trigger de retos:** `toggleTareaCompletada()` ahora actualiza columna `estado` en `hitos_de_reto`, disparando `trg_hito_completado` correctamente
- **Métricas de insignias:** `planes_estudio`, `apuntes_creados` y `bloques_estudio` ahora consultan las tablas correctas

#### Panel de Administración — 14-06-2026
- **Nueva columna** `rol` en `usuarios` (TEXT, default 'usuario', CHECK usuario/admin)
- **Nueva función RPC** `wipe_user_data(p_usuario_id)` — elimina historial (24+ tablas) preservando perfil y reseteando nivel/XP/racha
- **Nueva función helper** `es_admin()` — verifica si el usuario autenticado es admin
- **Nuevo feature** `admin/` con: AdminPanelScreen, AdminUsuarioDetalle, AdminWipeDialog
- **Nuevo provider** `esAdminProvider` para verificar rol admin
- **Navegación:** ruta `/admin` protegida por rol, botón condicional en dashboard
- **RLS admin bypass:** políticas "Admin read all usuarios", "Admin update usuarios", "Admin read all sesiones" que usan `es_admin()` para bypassear RLS
- **Nueva migración:** `20260616000006_admin_rol.sql`

#### Documentación (actualización admin)
- `AGENTS.md`: migraciones actualizadas (8→9), añadido módulo `admin/` y referencia a `0006_admin_rol`
- `00-plan-maestro.md`: migraciones 8→9, añadida sección Panel de Administración
- `02-requirements.md`: CU-31, HU-57→60, CA-33→35 añadidos (wipe de datos)
- `03-architecture.md`: migraciones 8→9, añadido feature `admin/` en árbol de carpetas, migración 0006 en listado
- `04-data-model.md` → v5.3: columna `rol` en `usuarios`, función `wipe_user_data`, políticas admin RLS
- `07-backend.md`: migraciones 8→9, entrada 0006 añadida al historial
- `08-installation.md`: migraciones 8→9
- `11-security.md` → v1.3: sección 2.4 Rol de administrador con permisos, restricciones y políticas
- `14-changelog.md`: Esta entrada

---

## [6.1.0] — 11/06/2026

### Fase 0 — Limpieza de datos mock y archivos obsoletos

- **12 archivos eliminados:**
  - 4 seeds mock: `seed_usuarios.py`, `seed_demo_data.py`, `seed_asignaturas.py`, `seed_todo.py`
  - 2 seeds redundantes: `seed_completo.py`, `seed_catalogo.py`
  - 2 generadores/herramientas: `generate_migration_0042.py`, `fix_nombres_dataset.py`
  - 1 backup JSON: `dataset_final_backup2.json`
  - 2 SQL obsoletos: `repair_sync.sql`, `sql/schema.sql`
  - 1 texto mock: `splash_screen.dart` → "Tu compañero de estudio y bienestar universitario"
- **10 archivos conservados:** 4 JSONs (`dataset_final.json`, `musculos.json`, `partes_cuerpo.json`, `equipamientos.json`), 4 repair SQLs, `delete_user_careers.sql`, `grados.json`
- **AGENTS.md:** sección Data seeding actualizada → solo `seed_catalogo_v2.py`

### Fase 1 — Catálogo Académico v2
- **Migración consolidada:** 1 archivo (`202606060049_esquema_base.sql`, ~12K líneas) con schema completo + 909 ejercicios + catálogo v2
- **8 tablas nuevas:** `universidades`, `centros`, `carreras`, `asignaturas_catalogo`, `profesores_asignatura`, `prerrequisitos_asignatura`, `criterios_evaluacion`, `bibliografia_asignatura`
- **8 modelos Dart nuevos:** `UniversidadDb`, `CentroDb`, `CarreraDb`, `AsignaturaCatalogoDb`, `ProfesorAsignaturaDb`, `PrerrequisitoAsignaturaDb`, `CriterioEvaluacionDb`, `BibliografiaAsignaturaDb`
- **3 modelos eliminados:** `CatalogoUniversidadDb`, `CatalogoCarreraDb`, `CatalogoAsignaturaDb`
- **Seed `seed_catalogo_v2.py`:** poblado desde `grados.json` (remoto: 23 carreras, 367 asignaturas)
- **Columnas timeline:** `completado` + `asistencia_registrada_en` en `horarios_academicos`
- **RLS:** 8 tablas con lectura pública
- **Providers + pantallas:** `catalogo_provider.dart`, `usuario_carreras_provider.dart`, `gestion_asignaturas_screen.dart`, `perfil_screen.dart` actualizados

### Fase 2 — Línea de Tiempo Unificada
- **DTO `TimelineItem`:** enum `TimelineTipo` con 7 valores + factory constructors (`desdeHorario`, `desdeSesion`, `desdeEntrega`)
- **Provider `timelineHoyProvider`:** 3 queries en paralelo (horarios, sesiones, entregas) + merge cronológico
- **Widget `TimelineSection`:** ConsumerWidget con estados loading/empty/data + max 5 items
- **`BienestarCard` eliminado** del dashboard
- **BUG-01 arreglado:** `QuickAction` "Workout" ahora usa `obtenerDiaYRutinaParaQuickAction`

### Fase 3 — Consolidación de Migraciones
- 52 → 1 archivo de migración (`202606060049_esquema_base.sql`)
- `migraciones_pendientes.sql` eliminado por redundante
- `AGENTS.md` actualizado ("1 migration file", "18 docs")

### Fase A — Correcciones (13/06/2026)
- **Trigger `marcar_semana_completada`:** nueva migración. Al completar todos los días de una semana, se marca automáticamente como `completada`
- **Bug fix `sesionesRestantesSemana`:** de contar sesiones de HOY → contar sesiones de la SEMANA
- **Mejora `obtenerDiaYRutinaParaQuickAction`:** de iterar solo `semanas.first` → iterar TODAS las semanas

---

## [6.2.0] — 13/06/2026

### Fase B — Línea de Tiempo Enriquecida (3 Tabs)

- **`TimelineTipo` ampliado:** de 7 a 9 valores. Añadidos `reto` y `entrenamientoPendiente`. Nuevos factory constructors: `TimelineItem.desdeReto()` y `TimelineItem.desdeDiaPendiente()`.
- **`TimelineSection` con 3 tabs:**
  - **Tab "Hoy":** bloques académicos + sesiones completadas + entrenamiento pendiente destacado (max 5 items)
  - **Tab "Semana":** entregas de los próximos 7 días agrupadas cronológicamente (max 7)
  - **Tab "Retos":** retos activos con barra de progreso y días restantes (max 5)
- **`timelineHoyProvider`:** 5 queries en paralelo (horarios, sesiones, entregas 7d, retos activos, día pendiente)
- **Widget `_EntrenamientoPendienteCard`:** tarjeta destacada naranja con botón "Comenzar" que navega directo a sesión en vivo
- **Widget `_RetoCard`:** tarjeta con `LinearProgressIndicator` y badge de días restantes
- **Navegación:** `TabController` con 3 tabs en `TabBar` + `TabBarView`; nueva ruta `/plan-semanal` desde header de timeline
- **Archivos nuevos:**
  - `timeline_item.dart` (186 líneas) — enum `TimelineTipo` (9 valores) + clase `TimelineItem` con 5 factory constructors
  - `timeline_provider.dart` (91 líneas) — provider `timelineHoyProvider` con 5 queries
  - `timeline_section.dart` (454 líneas) — widget con tabs + sub-widgets de tarjetas

### Fase C — Provider de Día Pendiente Unificado

- **`diaPendienteProvider`:** nuevo provider que itera TODAS las semanas de la rutina activa para encontrar el primer día no completado. Retorna `{diaId, rutinaId}` o `null`.
- **`obtenerDiaYRutinaParaQuickAction()`:** refactorizado para delegar en `diaPendienteProvider` (lógica unificada)
- **Consumidores unificados:** `QuickAction` "Workout", `TimelineSection` (_TabHoy), y `RutinaDetalleScreen` usan el mismo provider

### Fase D — Integración y Documentación

- **TimelineSection integrada** en el dashboard (posición 8 del ListView)
- **Migración `0050`:** trigger `marcar_semana_completada` — al completar todos los días de una semana, se marca automáticamente como `completada`
- **Bug fix `sesionesRestantesSemana`:** de contar sesiones de HOY → contar sesiones de la SEMANA
- **Bug fix `obtenerDiaYRutinaParaQuickAction`:** de iterar solo `semanas.first` → iterar TODAS las semanas
- **`AGENTS.md` actualizado:** 2 archivos de migración, nuevos archivos clave documentados
- **`docs/02-requirements.md`:** CU-23, HU-42-44, CA-22-24 añadidos
- **`docs/06-frontend.md`:** §9 actualizado con `TimelineSection` de 3 tabs y providers nuevos
- **`docs/00-plan-maestro.md`:** Fases A, B, C, D marcadas como COMPLETADO

### Fase E — Documentación del Dashboard v6.2

- **`docs/14-changelog.md`:** entradas `[6.1.0]` y `[6.2.0]` creadas con detalle de todas las fases
- **`docs/02-requirements.md`:** CU-23, HU-42→44, CA-22→24 añadidos para timeline, quick actions y carga cognitiva
- **`docs/06-frontend.md` §9.1.1:** documentación de TimelineSection con 3 tabs, TimelineTipo (9 valores), providers y DTO
- **`AGENTS.md`:** actualizado con 2 migraciones consolidadas y archivos clave

### Fase F — Invalidación de Timeline (v6.2)

- **`timelineHoyProvider` se invalida automáticamente en 6 archivos:**
  - `retos_provider.dart` — `_invalidarRetos()` ahora invalida `timelineHoyProvider`
  - `entregas_examenes_provider.dart` — 4 mutaciones (`crearEntrega`, `actualizarEntrega`, `eliminarEntrega`, `toggleEntregaCompletada`) añaden `WidgetRef ref` e invalidan timeline
  - `planes_estudio_provider.dart` — 7 mutaciones (`crearPlanEstudio`, `eliminarPlanEstudio`, `crearBloqueEstudio`, `actualizarBloqueEstudio`, `eliminarBloqueEstudio`, `crearPlanCompleto`, `crearBloqueRapido`) añaden `WidgetRef ref` e invalidan timeline
  - `sesion_en_vivo_screen.dart` — invalida `timelineHoyProvider` tras `finalizarSesion()`
  - `nueva_rutina_screen.dart` — invalida `timelineHoyProvider` tras `syncCargaAcademicaSemanal()`
- **Callers actualizados:** `plan_semanal_screen.dart` + `crear_plan_semanal_screen.dart`
- **Dependencia circular evitada:** invalidación desde screens en lugar de providers para `rutina_provider ↔ timeline_provider`

### Fase G — Navegación en Timeline y Limpieza (v6.2)

- **`RutinasSection` eliminada** del dashboard: 9 → 8 secciones en `ListView`
- **`_TimelineTarjeta` convertida a `ConsumerWidget`** con navegación `onTap`:
  - `estudio`/`clase`/`deporte` → `/plan-semanal`
  - `reto` → `/retos/:id`
  - `entrega` → toggle completado + invalidate
- **Documentación sincronizada:** `docs/03-architecture.md` §15.2, `docs/06-frontend.md` §9.1, `docs/12-user-guide.md` §4.1

### Fase H — Verificación y Ajustes Finales (v6.2)

- **PlanWeekBar** y **RutinaDetalleScreen** verificados: progreso semanal y badge "Hoy" se actualizan automáticamente tras completar sesiones
- **`docs/00-plan-maestro.md`:** estadísticas de dashboard actualizadas (10→8 secciones, 263→119 líneas)
- **QA:** 0 errores, 0 warnings, 5 info (todos preexistentes)

---

## [6.3.0] — 12/06/2026

### Sprint 7 — Retos Complejos y Sincronización Offline

#### Fase A1 — Migración DB + DTOs
- **Migración `202606120050`:** nuevas columnas en `hitos_de_reto` (`estado`, `dependencias UUID[]`, `tipo_condicion`, `condicion_n`) y `retos` (`tiene_dependencias`)
- Trigger `trg_hito_completado` + función `desbloquear_hitos()` con soporte AND/OR/X_OF_Y
- DTOs: `GrafoReto`, `NodoHito`, `AristaDependencia`, `EstadoHito`, `TipoCondicion`

#### Fase A2 — Motor de Desbloqueo
- `reto_dependencia_service.dart`: construcción de grafo, detección de ciclos (DFS), validación de dependencias
- `grafoRetoProvider`: provider que construye el grafo desde `hitos_de_reto`

#### Fase A3 — UI Grafo de Dependencias
- `grafo_dependencias.dart`: widget con nodos coloreados por estado (bloqueado/disponible/en_progreso/completado) y leyenda
- `_NodoHitoCard`: tarjeta individual con icono de estado, condición de desbloqueo y barra de progreso
- Integrado en `DetalleRetoScreen` (visible solo si `tiene_dependencias = true`)

#### Fase C1 — Infraestructura Offline
- `connectivity_service.dart`: Stream de estado de conectividad (online/offline/syncing)
- `offline_queue_service.dart`: cola Hive para operaciones pendientes (INSERT/UPDATE/DELETE) con reintentos (max 3)
- `sync_provider.dart`: providers Riverpod para estado de red, cola offline y sincronización
- Nuevas dependencias: `connectivity_plus ^6.1.0`, `fl_chart ^0.70.0`

#### Fase A4 — Notificaciones de Desbloqueo de Hitos
- Notificaciones automáticas al desbloquear hitos (`notificaciones` table)
- Al completar un hito con dependencias satisfechas, se inserta notificación con tipo `hito_desbloqueado`
- Integración con el trigger `trg_hito_completado` para disparar notificaciones desde BD
- Provider `notificacionesHitoProvider` para consultar notificaciones de desbloqueo pendientes

#### Fase B1 — Infraestructura Analítica
- **Vista `v_analitica_semanal`:** agrega sesiones por semana (RPE promedio, volumen total, días entrenados, calorías) con JOIN a `sesiones_registradas` y `rutinas`
- **Migración `202606140001_v_analitica_semanal.sql`:** nueva migración para crear la vista analítica y aplicar en local y remoto
- **Tabla `insights_analitica`:** cachea insights generados (tipo, titulo, descripcion, datos JSONB, semana_inicio, semana_fin). RLS propietario.
- **DTO `MetricaSemanal`:** factory `fromMap` para datos de `v_analitica_semanal`
- **DTO `InsightCorrelacion`:** resultados de correlación Pearson (coeficiente, p-valor, interpretación)
- **Enum `PeriodoAnalitica`:** semanal/mensual/trimestral con getters `semanas` y `etiqueta`
- **`AnaliticaRepository`:** consulta `v_analitica_semanal` + `carga_academica_semanal`, calcula correlación Pearson (~220 líneas)
- **`InsightGenerator`:** generador estático de frases interpretativas en español (racha, consistencia, volumen, correlación)
- **`analitica_provider.dart`:** 6 providers Riverpod (`analiticaRepositoryProvider`, `analiticaSemanalProvider`, `tendenciaRpeProvider`, `volumenSemanalProvider`, `correlacionCargaProvider`, `periodoSeleccionadoProvider`)

#### Fase B2 — Charts de Analítica (fl_chart)
- **`TendenciaRpeChart`:** `LineChart` con RPE promedio semanal y línea de tendencia. Eje X: semanas, eje Y: RPE (1-10). Tooltips con fecha y valor exacto.
- **`VolumenBarChart`:** `BarChart` con volumen semanal (minutos entrenados). Barras con gradiente de color según intensidad.
- **`CorrelacionCargaScatter`:** `ScatterChart` con correlación entre carga académica (horas estudio) y RPE de entrenamiento. Línea de regresión y coeficiente Pearson.
- Dependencia `fl_chart ^0.70.0` integrada en el módulo `analitica/`

#### Fase B3 — Pantalla AnaliticaScreen
- **`AnaliticaScreen`:** nueva pantalla con `SegmentedButton` para selector de periodo (Semanal | Mensual | Trimestral)
- Consume `analiticaSemanalProvider`, `tendenciaRpeProvider`, `volumenSemanalProvider`, `correlacionCargaProvider`
- Sección de métricas clave: RPE promedio, volumen total, días entrenados, consistencia (%)
- Sección de tendencia RPE con `TendenciaRpeChart`
- Sección de volumen con `VolumenBarChart`
- Sección de correlación académica con `CorrelacionCargaScatter` + frases interpretativas de `InsightGenerator`
- Ruta: `/analitica` integrada en la navegación principal

#### Fase C2 — Indicador Offline en Shell Route
- **`OfflineIndicator`:** widget banner persistente en `SynaptixShellRoute` que muestra estado de conectividad
- Consume `connectivityStateProvider` para mostrar banner "Sin conexión" (rojo) o "Sincronizando..." (ámbar)
- Animación de transición suave al cambiar de estado (fade + slide)
- La cola offline se procesa automáticamente al detectar reconexión (`syncProvider`)

### Migraciones aplicadas en local y remoto
- **Local:** `supabase db push` desplegó `202606120050_dependencias_retos.sql`, `202606130001_marcar_semana_completada.sql` y `202606140001_v_analitica_semanal.sql` en la BD local de Docker
- **Remoto:** `python supabase/apply_migrations.py` aplicó las mismas migraciones al proyecto Supabase en producción
- Seed `seed_catalogo_v2.py` verificado en ambos entornos

### Documentación actualizada
- `docs/00-plan-maestro.md`: Sprint 7 marcado COMPLETADO, Fases A1-A4, B1-B3 y C1-C2 marcadas COMPLETADO
- `docs/04-data-model.md` → v5.0: nuevas columnas en `hitos_de_reto` y `retos`, tabla `insights_analitica`, vista `v_analitica_semanal`, mapeo canónico actualizado al catálogo v2
- `docs/06-frontend.md` → v6.0: §13 Pantallas de Retos (DetalleRetoScreen, CrearRetoComplejoScreen, GrafoDependencias, _NodoHitoCard), §14 Sincronización Offline (arquitectura, servicios, providers, DTO)
- `docs/14-changelog.md`: Esta entrada

---

## [6.0.0] — 10/06/2026

### Rediseño del Dashboard

- **SmartBannerCard:** consejo IA generado por Gemini al cargar el dashboard, con cache Hive 1h y fallback determinista
- **QuickActionsRow:** 4 chips de acceso rápido (Pomodoro, Workout, Escanear, Nuevo reto)
- **PlanWeekBar:** "Semana X de Y" mostrando progreso semanal de la rutina activa
- **CognitiveLoadBar:** barra horizontal de carga cognitiva basada en FCT
- **StreakRow:** badges 🔥 (racha entrenamiento) y 🧠 (días estudio/semana)
- **cargaCognitivaProvider:** nuevo provider que expone el Factor de Carga Total públicamente
- **geminiServiceProvider:** instancia compartida de Gemini para evitar duplicación
- **consejoSmartProvider:** provider del Smart Banner con integración Gemini + Hive
- **Migración 0052:** columnas `racha_actual`, `mejor_racha`, `ultimo_dia_activo` en tabla `retos`
- **Hive:** inicializado en main.dart con boxes `smartcache` y `offline_dash`

### Cambiado
- DashboardScreen: 1445 → 355 líneas (-75%), 12 widgets extraídos a `widgets/`
- DashboardData: refactorizado a archivo independiente
- Dialog helpers: 8 funciones extraídas a `shared/widgets/dashboard_dialogs.dart`
- `_calcularFCT` renombrado a `calcularFCT` (público) en `RecomendacionContextoService`
- Navegación del dashboard usa `ListView` con cards responsivas
- Layout: 10 secciones verticales con widgets condicionales

### Corregido
- Import circular entre `dashboard_provider.dart` y `rutina_provider.dart` eliminado
- Documentación: tabs corregidos en `01-introduction.md` §4.5
- Documentación: providers del dashboard corregidos en `06-frontend.md` §3.4

---

## [5.2.0] — 09/06/2026

### Sistema de XP (Gamificación — Fase 1)

Implementación del sistema de experiencia conectado a PostgreSQL vía RPC `otorgar_xp()`:

- **DTO `XpResultado`** en `rutina_provider.dart`: retorna `{xpGanado, nuevoNivel, nuevaXp, subeNivel}` desde la respuesta de la función PostgreSQL.
- **`otorgarXp(client, usuarioId, cantidadXp)`**: función pública sin underscore, llamable desde `retos_provider.dart`. Delega en `client.rpc('otorgar_xp', params: {p_usuario_id, p_cantidad_xp})`. La función PostgreSQL maneja level-up con umbral `1000 × nivel`.
- **`finalizarSesion()`** ahora retorna `XpResultado?` en vez de `void`. Fórmula de XP: `50 + min(duraciónMin, 90) + (rpe × 5)` → rango típico 56–190 XP. Invalida `dashboardProvider`.
- **Feedback en `SesionEnVivoScreen`**: Tras `finalizarSesion()`, muestra SnackBar con:
  - `"+130 XP 🔥"` si no sube de nivel
  - `"¡Subiste a nivel 5! 🎉 +130 XP"` si `subeNivel == true`
- **Migración 0051**: `ALTER TABLE carga_academica_semanal ADD COLUMN xp_estudio_otorgado boolean DEFAULT false`
- **Modelo `CargaAcademicaSemanalDb`**: nuevo campo `xpEstudioOtorgado` (bool)

### Limpieza del Dashboard

- **KPIs eliminados:** KPI "Horas de estudio" y KPI "Racha actual" eliminados del dashboard.
- **Badge 🔥 eliminado** del `_SaludoCard` (el saludo ahora muestra solo nivel y XP con punto de energía).
- **KPI "Calorías hoy":** ahora se oculta cuando `calorias == 0` (antes siempre visible con valor 0).
- **Grid de KPIs dinámico:** `crossAxisCount` basado en `children.length.clamp(1, 2)` en vez de valor fijo. Cuando solo queda "Sesiones completadas", el grid muestra 1 columna.
- **`_buildKpiColumn` refactorizado** a método con cuerpo (deja de ser arrow function).

### XP por Retos y Metas de Estudio (Fase 3)

- **`completarReto()`** en `retos_provider.dart`: ahora otorga XP — 200 XP para reto simple, `100 × cantidadHitos + 300` para reto complejo (rango 400–1300). Invalida `dashboardProvider`.
- **`syncCargaAcademicaSemanal()`** en `rutina_provider.dart`: al finalizar, si `horasReales ≥ 0.8 × horasPlaneadas` y `xp_estudio_otorgado == false`, otorga 150 XP (único por semana) y marca el flag en BD.
- **`otorgarXp`** hecho público (sin underscore) para ser llamado desde `retos_provider.dart`.

### Timeout de IA ampliado

- **`recomendacion_ia_service.dart`**: `receiveTimeout` del cliente Dio de Gemini ampliado de 35s a 45s para dar más margen a respuestas largas del modelo.

### Fórmulas de XP

| Fuente | Fórmula | Rango típico |
|--------|---------|-------------|
| Sesión entrenamiento | `50 + min(duraciónMin, 90) + (RPE × 5)` | 56–190 XP |
| Reto simple | 200 XP | 200 XP |
| Reto complejo | `100 × hitos + 300` | 400–1300 XP |
| Meta estudio semanal | 150 XP (único por semana) | 150 XP |
| Nivel-up | `xpTotal ≥ 1000 × nivel` → nivel++ | — |

### Documentación actualizada
- `04-data-model.md` (v4.5): DTO `XpResultado`, campo `xp_estudio_otorgado`, fórmulas de XP y level-up
- `06-frontend.md` (v5.2): Feedback de XP en sesión en vivo, dashboard simplificado (KPIs eliminados, grid dinámico, `_buildKpiColumn` refactorizado)
- `12-user-guide.md` (v4.1): Nueva sección sobre cómo se gana XP (sesiones, retos, estudio) y explicación de level-up
- `14-changelog.md`: Esta entrada.
- `AGENTS.md`: Actualizados conteos de líneas y migraciones.

---

## [5.1.0] — 09/06/2026

### Pipeline Académico y Métricas Energéticas

- **Pipeline académico completo:**
  - Nuevo modelo `CargaAcademicaSemanalDb` mapea `carga_academica_semanal` (horas estudio, evaluaciones, estrés, sueño)
  - `cargaAcademicaSemanalProvider`: consulta semana actual con timeout 8s
  - `contextoAcademicoProvider`: combina carga semanal + exámenes próximos (consulta `entregas_examenes` para 7 días)
  - `syncCargaAcademicaSemanal()`: auto-popula `carga_academica_semanal` desde `horarios_academicos` (tipo='estudio') y `entregas_examenes`. Se ejecuta antes de cada recomendación.
- **Métricas académicas y energéticas:**
  - `adherenciaAcademicaProvider` (0-100): disciplina pura — `cumplimientoHoras(60%) + completitudTareas(30%) + rachaDias(10%)`. SIN biometrías.
  - `estadoEnergeticoProvider` (0-100): base lineal × 3 gates no lineales (sueño≤1→×0.40, dolor≥4→×0.60, energía≤1→×0.50)
  - `calcularAjustes()` extendido con reglas de estado energético (crítico<30→×0.40, bajo<50→×0.75)
  - `ContextoAcademico` extendido con `adherenciaAcademica` y `estadoEnergetico`
- **Dashboard rediseñado:**
  - Nueva sección "Estado Actual": 3 gauges radiales animados (Energético, Adherencia Académica, Estudio) entre KPIs y Bienestar
  - Nuevo widget `MetricGauge`: CustomPainter con arco animado 1200ms, punto brillante, color dinámico, alertas contextuales
  - Indicador de energía en `SaludoCard`: punto de color junto al nivel/XP

### Sistema de Recomendación IA (refinamientos)

- **Paralelización de providers:** `generarRutinaProvider` carga perfil, catálogo, historial y estado diario con `Future.wait` (24s → 12s)
- **Timeouts explícitos:** queries de perfil (8s), historial (10s) y ejercicios (12s)
- **Catálogo inteligente:** `_filtrarCatalogoParaIA()` filtra top 60 ejercicios por equipamiento, dificultad y score (1000+ ejercicios ~200KB → 60 ejercicios ~15KB)
- **JSON mode:** `_callGemini()` activa `response_mime_type: application/json` forzando salida JSON válida. Fallback a `_extraerJson()`.
- **Contexto unificado:** `_formatearContextoCompleto()` con 5 secciones: PERFIL FÍSICO, HISTORIAL DEPORTIVO, ESTADO DIARIO, CARGA ACADÉMICA, SEGURIDAD BIOMÉTRICA
- **3 prompts reescritos:** `refinarRutina`, `generarRecomendacionEjercicios`, `generarEstructuraCompleta` con estructura estándar ROL+CONTEXTO+CATÁLOGO+REGLAS+FORMATO
- **Parámetros por modalidad:** `_toInput()` calcula valores basados en perfil — peso según % corporal × tipo, duración aeróbica según min/sesión y nivel, tiempo isométrico escalado con nivel
- **Progresión isométrica:** `ProgresionEjercicio.nuevoTiempoIsometricoSegundos` con gates RPE (≤5→+10s, ≥9.5→-15%)
- **Validación extendida:** `_validarEjercicio()` valida duración (30-7200s), distancia (50-42195m), isométrico (5-300s), peso (0-300kg) con fallback a valores base
- **Preservación post-IA:** `_preservarParamsPreIa()` restaura duración, distancia e isométrico del pre-IA cuando IA los deja null
- **ContextoAcademico real:** el orquestador pasa `ContextoAcademico` completo a `refinarRutina`, no solo string "FCT 0.58"

### Gamificación (diagnosticado)

- `otorgar_xp()` en PostgreSQL existe con lógica de level-up pero NUNCA se llama desde Flutter (0 `.rpc()` calls)
- `racha_actual` nunca se actualiza (sin triggers)
- Pendiente de implementación: conectar `finalizarSesion()` → `client.rpc('otorgar_xp')`

> **Resuelto en v5.2.0:** `otorgarXp()` implementado en Flutter, conectado a `finalizarSesion()`, `completarReto()` y `syncCargaAcademicaSemanal()`. Ver entrada v5.2.0.

### Documentación sincronizada

- `01-introduction.md` → v1.5: métricas académicas/energéticas, gamificación, stack actualizado
- `03-architecture.md` → v4.1: nuevos archivos en árbol de directorios, conteos de líneas actualizados
- `04-data-model.md` → v4.4: modelo `CargaAcademicaSemanalDb`, DTO `ContextoAcademico`, relaciones al pipeline
- `06-frontend.md` → v5.1: `MetricGauge`, sección "Estado Actual", providers académicos/energéticos
- `15-ia-recomendacion-sistema.md` → v5.0: pipeline completo, JSON mode, catálogo inteligente, contexto unificado, validación extendida, fallback, diagramas Mermaid
- `AGENTS.md` actualizado con nuevos archivos y componentes

---

## [5.0.0] — 06-07/06/2026

### Motor de Recomendaciones Completo (Fases 0-10)

Implementación completa del motor de recomendaciones de SynaptixFit, compuesto por 11 fases que transforman la generación de rutinas de una llamada simple a Gemini en un pipeline determinista con refinamiento IA opcional.

#### Fase 0 — Unificación del Sistema de Objetivos

**`app/lib/shared/utils/string_utils.dart` (NUEVO, 63 líneas):** Fuente única de verdad para `finalidadesEstandar` (7 valores en español) y `sanitizarObjetivo()`. Eliminada la duplicación que existía entre `ejercicios_provider.dart` y `db_models.dart`.

**7 finalidades estándar:**
1. Hipertrofia Muscular
2. Fuerza Máxima
3. Potencia y Explosividad
4. Fuerza Resistencia
5. Movilidad y Flexibilidad
6. Estabilidad y Control Motor
7. Acondicionamiento Metabólico

**`sanitizarObjetivo()` implementa mapeo legacy:** `hipertrofia`→Hipertrofia Muscular, `fuerza`→Fuerza Máxima, `ganar_masa`→Hipertrofia Muscular, `perder_peso`→Acondicionamiento Metabólico, `resistencia`→Fuerza Resistencia, `movilidad`→Movilidad y Flexibilidad, `fitness_general`→Estabilidad y Control Motor, `mixto`→Hipertrofia Muscular, `cardio`→Acondicionamiento Metabólico, `flexibilidad`→Movilidad y Flexibilidad. Fallback: `Hipertrofia Muscular`.

**Archivos actualizados:**
- `ejercicios_provider.dart`: Eliminada definición duplicada de `finalidadesEstandar` y `sanitizarObjetivo`. Re-exporta desde `string_utils.dart` con `export ... show`.
- `db_models.dart`: Eliminado `sanitizarObjetivoLegacy()` duplicado. Añadido `import '../utils/string_utils.dart'`. Getter `PerfilBienestarDb.objetivoEstandar` simplificado a 1 línea: `sanitizarObjetivo(objetivoPrincipal)`. Corregido `finalidadPrincipal` fallback de `'fuerza'` a `'Hipertrofia Muscular'`.
- `recomendacion_ia_service.dart`: Los 4 prompts de Gemini ahora usan `finalidadesEstandar` (español) en vez de valores legacy (inglés). `_reglasPorObjetivo()` usa `sanitizarObjetivo()`.
- `rutina_detalle_screen.dart`: `_editarRutina()` sanitiza objetivo al cargar. `_ObjetivoBadge` usa `sanitizarObjetivo()` + `iconoFinalidad()`.
- `rutina_provider.dart`: `crearRutinaCompleta()` usa `sanitizarObjetivo()` al sanitizar el objetivo.
- `nueva_rutina_screen.dart`: Eliminado método privado `_sanitizarObjetivo()`. Usa función pública compartida.
- `perfil_fisico_screen.dart`: Usa `finalidadesEstandar` para los radio buttons del onboarding.
- `perfil_screen.dart`: Usa `finalidadesEstandar` para el selector de objetivo en perfil.

#### Fase 1 — Tabla de Parámetros por Objetivo

**`app/lib/features/bienestar/infrastructure/parametros_objetivo.dart` (NUEVO, 196 líneas):** Clase `ParametrosObjetivo` con tabla estática `tabla` de 7 entradas calibrada contra `dataset_final.json`. Cada entrada define: `seriesMin/Max`, `repsMin/Max`, `descansoMin/Max`, `rpeMin/Max`, `intensidadRelativa`, `ejerciciosPorDia`, `priorizarCompuestos`, `modalidades` (fuerza/aerobica/metabolica/movilidad), `finalidadesEjercicio`, `volumenSemanalObjetivo`, `admiteCircuito`. Factory `de(String objetivo)` usa `sanitizarObjetivo()` internamente con fallback seguro a Hipertrofia Muscular.

**Calibración de parámetros contra el dataset:**

| Objetivo | Series | Reps | Descanso | RPE | Intensidad | Ej/Día | Circuito |
|----------|--------|------|----------|-----|-----------|--------|----------|
| Hipertrofia Muscular | 3-4 | 6-15 | 60-120s | 7-9 | 70% | 5 | No |
| Fuerza Máxima | 3-5 | 1-6 | 120-300s | 8-9.5 | 85% | 3 | No |
| Potencia y Explosividad | 3-5 | 1-5 | 120-240s | 7-8.5 | 75% | 3 | Sí |
| Fuerza Resistencia | 2-3 | 12-25 | 30-60s | 5-7 | 55% | 6 | No |
| Movilidad y Flexibilidad | 2-3 | 8-15 | 30-60s | 3-5 | 30% | 7 | No |
| Estabilidad y Control Motor | 2-3 | 6-12 | 45-90s | 4-6 | 40% | 6 | No |
| Acondicionamiento Metabólico | 2-3 | 12-25 | 20-45s | 6-8 | 50% | 5 | Sí |

#### Fase 2 — Motor de Reglas: Selección SQL + Scoring

**`app/lib/features/bienestar/infrastructure/recomendacion_reglas_service.dart` (NUEVO, 429 líneas):**

- **`generarEstructura()`**: API pública que retorna `Map<int, Map<int, List<EjercicioInput>>>` (estructura semanal de rutina).
- **`determinarSplit()`**: Árbol de decisión para el split de entrenamiento: ≥5 días→Push/Pull/Legs, ≥4 días+nivel alto→Upper/Lower, resto→Full-Body.
- **`splitLabel()`**: Etiqueta legible del split ("Full-Body", "Upper/Lower", "Push/Pull/Legs"), compartida con el orquestador.
- **`_musculosPorDia()`**: Asigna músculos objetivo a cada día según split usando nombres reales del dataset.
- **`_aplicarFiltros()`**: 5 filtros encadenados (dificultad, equipamiento, modalidad, músculo, ejercicios recientes).
- **`_scoreEjercicioParaObjetivo()`**: 4 criterios ponderados (finalidad 40%, compuesto 25%, dificultad 20%, multi-finalidad 15%).
- **`_seleccionBalanceada()`**: Selecciona 60% compuestos + aislados, evita músculos primarios duplicados.

#### Fase 3 — Capa de Contexto: Academia + Fisiología + Gamificación

**`app/lib/features/bienestar/infrastructure/recomendacion_contexto_service.dart` (NUEVO, 216 líneas):**

**DTOs:** `ContextoAcademico` (horasEstudioReales, nivelEstres, evaluacionesSemana, horasSuenoPromedio, tieneExamenesProximos), `ContextoFisiologico` (pesoActual, pesoSemanaAnterior, rachaActual, nivelUsuario, modoExamenes, con tendenciaPesoSemanal), `AjusteContexto` (factorSeries, factorDescanso, restricciones, motivo).

**`calcularAjustes()`**: 6 reglas encadenadas:
1. **Modo exámenes**: Reduce series 20%, reduce descanso 15%
2. **FCT (Factor de Carga Total)**: Pondera horas estudio, estrés, evaluaciones, sueño (baseline 8h corregido de 3h), dolor muscular, energía → factor 0.5-1.0
3. **Racha**: ≥7 días → +10% series; ≥30 días → +15% series
4. **Tendencia peso**: Perdiendo peso + objetivo hipertrofia → restricción; ganando peso + objetivo pérdida → restricción
5. **Fatiga diaria**: >50 → reduce 30% series; >70 → reduce 50% series
6. **Listo para entrenar**: false → reduce 40% series

**`aplicarAjustes()`**: Clampa series/descanso respetando límites de `ParametrosObjetivo`.

#### Fase 4 — Calculadora de Sobrecarga Progresiva

**`app/lib/features/bienestar/infrastructure/progresion_calculator.dart` (NUEVO, 335 líneas):**

- **`calcular1RM()`**: Fórmula no lineal con guard para pesos <3kg (Epley simplificada, evita división por cero).
- **`generarPesosPorSerie()`**: Rampa 50%→75%→100% para ejercicios con peso.
- **`calcularProgresion()`**: Doble progresión por tipoMedicion con soporte para peso, tiempo y distancia.
- **`degradarPorInactividad()`**: >14 días→-20%, >21 días→-30% de carga.
- **`generarInicial()`**: Sin historial, genera pesos por serie con rampa.
- **`progresionarEstructura()`**: Batch que aplica progresión a toda la estructura generada.

**DTOs:** `SerieRealizadaDto` (numeroSerie, repeticionesRealizadas, pesoKg, completada, failedReps), `ProgresionEjercicio` (nuevasSeries, nuevasRepeticiones, nuevoDescanso, nuevoPeso, pesosPorSerie, nuevaDuracionSegundos, nuevaDistanciaMetros, log).

#### Fase 5 — Transición de Objetivos

**`app/lib/features/bienestar/infrastructure/transicion_objetivo_service.dart` (NUEVO, 155 líneas):**

**`calcularTransicion()`**: Interpola parámetros entre objetivo viejo y nuevo en 3 fases (factor 0.30→0.70→1.0) durante 3 semanas.

**`_interpolar()`**: `lerpInt`/`lerpDouble` con guard `min>max` en series/reps/descanso para evitar inversión de rangos.

**`aplicarTransicion()`**: Clampa ejercicios a rangos interpolados según fase.

**`FaseTransicion` enum**: `estable`, `temprana`, `media`, `completa`.

**Nueva migración 0046 (`202606060046_historial_objetivos.sql`):** Tabla `historial_objetivos` para trackear cambios de objetivo del usuario. Campos: `usuario_id`, `objetivo`, `objetivo_anterior`, `fecha_inicio`, `fecha_fin`, `rutina_ids`. RLS: propietario (SELECT, INSERT, UPDATE). Índice `(usuario_id, fecha_inicio DESC)`.

**Nuevo modelo `HistorialObjetivoDb`** en `db_models.dart`: con getter `semanasActivo` (corregido bug de `difference` invertido).

#### Fase 6 — Capa de Refinamiento IA (Gemini)

**`recomendacion_ia_service.dart` modificado:**

- **`refinarRutina()` (NUEVO):** Recibe estructura base generada por el motor de reglas y la refina con Gemini. El prompt pide: mejorar nombre, mejorar descripción, variar ejercicios (máx 1-2 por día), reordenar ejercicios. NO modifica series/reps/descanso (eso lo hace el motor de reglas).
- **`_validarYReparar()` (NUEVO):** Valida cada ejercicio post-IA contra 4 reglas (ID existe en catálogo, equipamiento compatible, dificultad válida, parámetros en rango). Si falla → revierte al ejercicio original del motor de reglas.
- **`_validarEjercicio()` (NUEVO):** Validación individual con `orElse` defensivo.
- **`_parseError()` corregido:** Bug de `substring(0,100)` con strings cortos → ahora usa `clamp`.
- **Guard contra catálogo vacío:** `refinarRutina()` retorna estructura base sin modificar si el catálogo está vacío.

#### Fase 7 — Motor de Feedback Post-Entrenamiento

**`app/lib/features/bienestar/infrastructure/feedback_engine.dart` (NUEVO, 130 líneas):**

- **`procesarSesion()`**: Lee `series_sesion`, calcula degradación dinámica basada en `failed_reps` (no 15% fijo). Cada repetición fallida descuenta 5%, clamp 70-95%.
- **`detectarInactividad()`**: `DateTime.tryParse` seguro sobre `completada_en`. Si >7 días de inactividad → genera recomendación de reenganche al 80%.
- **`generarAlertaFatiga()`**: Con try-catch defensivo, inserta alerta en tabla `notificaciones` si fatiga sostenida >50.

**Nueva migración 0047 (`202606060047_failed_reps.sql`):** Columna `failed_reps INT NOT NULL DEFAULT 0 CHECK (failed_reps >= 0)` en `series_sesion`.

**Nueva migración 0048 (`202606060048_recomendaciones_pendientes.sql`):** Tabla `recomendaciones_pendientes` con campos: `tipo` (progresion/degradacion/descarga/variante/academico), `titulo`, `descripcion`, `ejercicio_id`, `rutina_id`, `datos JSONB`, `aplicada BOOLEAN`. RLS: propietario (SELECT, INSERT, UPDATE). Índice `(usuario_id, creado_en DESC)`.

**Nuevo modelo `RecomendacionPendienteDb`** en `db_models.dart`.
**Actualizado `SerieSesionDb`** con campo `failedReps`.

#### Fase 8 — Orquestador

**`app/lib/features/bienestar/infrastructure/recomendacion_orquestador_service.dart` (NUEVO, 352 líneas):**

**`generarRutina()`**: Pipeline completo de 7 etapas:
1. `sanitizarObjetivo()` → normaliza el objetivo
2. `RecomendacionReglasService.generarEstructura()` → estructura base
3. Validación de estructura vacía (error temprano si no hay ejercicios)
4. `RecomendacionContextoService.aplicarAjustes()` → ajusta por academia/fisiología
5. `TransicionObjetivoService.aplicarTransicion()` → interpola si hay cambio de objetivo
6. `ProgresionCalculator.progresionarEstructura()` → aplica sobrecarga
7. `RecomendacionIaService.refinarRutina()` → refinamiento IA (opcional)

**`_buildTipoMedicionCache()`**: Construye mapa de `tipoMedicion` desde catálogo real (no mapa vacío).
**`_capturarPesosKg()` / `_preservarPesosKg()`**: Preserva pesos por serie en round-trip de IA.
**`_determinarSplitLabel()`**: Delega a `_reglas.splitLabel()` (principio DRY).

**DTOs:** `MetadatosGeneracion` (objetivo, split, motivoAjustes, factorCargaTotal, iaRefinada), `ResultadoGeneracion` (nombre, descripcion, objetivo, duracionSemanas, estructura, metadatos, tieneError).

#### Fase 9 — Integración UI

**`rutina_provider.dart` modificado:**
- Nuevos providers: `geminiApiKeyProvider` (lee GEMINI_API_KEY de EnvConfig), `recomendacionOrquestadorProvider` (instancia del orquestador), `generarRutinaProvider` (FutureProvider.family que ejecuta el pipeline completo).
- El provider `generarRutinaProvider` recibe `(usuarioId, usarIa)` y devuelve `ResultadoGeneracion`.

**`nueva_rutina_screen.dart` modificado:**
- **Botón "⚡ Generar rutina rápida"** (FilledButton, siempre visible): Ejecuta el pipeline determinista (Fases 0-8) sin IA. Resultado en <2 segundos.
- **Botón "✨ Recomendar rutina con IA"** (OutlinedButton, solo visible con API key configurada): Ejecuta el pipeline completo con refinamiento IA (Fase 6).
- **Eliminado:** Botón redundante "Recomendar ejercicios" (~140 líneas eliminadas).
- **Eliminado:** Método `_recomendarEjercicios()` (~140 líneas).
- **Eliminado:** `_llenarEstructuraDesdeRecomendacion()` (~30 líneas).
- **`_generarRutinaRapida()`**: Resuelve nombres de ejercicios desde catálogo, defaults por objetivo.
- **`_DiaEditorCard`**: Recibe `objetivo` para defaults al añadir ejercicios.

#### Fase 10 — Job Nocturno (pg_cron)

**Nueva migración 0049 (`20260606_0049_func_daily_recommendations.sql`):** Función `generar_recomendaciones_diarias()`:

1. **Usuarios inactivos 7-30 días**: Inserta recomendación de reenganche con factor de carga 0.80. Deduplica (no repite si ya hay una en últimos 7 días).
2. **Fatiga alta en últimos 3 días**: Calcula puntuación de fatiga promedio (misma fórmula que el cliente: `(6-sueño)×5 + (estrés-1)×5 + (6-energía)×4 + (dolor-1)×7`). Si promedio >50 → inserta recomendación de descarga. Deduplica (no repite en últimos 3 días).
3. **Retorno**: Devuelve las recomendaciones generadas en esta ejecución.

Configurable vía `pg_cron` para ejecución diaria a las 2 AM:
```sql
SELECT cron.schedule('recomendaciones-diarias', '0 2 * * *', 'SELECT generar_recomendaciones_diarias();');
```

### Correcciones de bugs encontrados en auditoría (12 bugs)

1. **FCT usaba umbral de sueño 3h** → corregido a 8h (baseline fisiológico correcto)
2. **`semanasActivo` getter con `difference` invertido** → corregido en `HistorialObjetivoDb`
3. **`pesosKg` se perdía en round-trip de IA** → preservación implementada en orquestador
4. **Split label no consideraba `nivelActividad`** → `determinarSplit()` ahora recibe nivel
5. **`_EjercicioPlan.nombre` se seteaba al UUID** → corregido resolviendo desde catálogo
6. **Tiempo/distancia escribía progresión en campo equivocado** → `nuevaDuracionSegundos`/`nuevaDistanciaMetros` en `ProgresionEjercicio`
7. **`_defaultTipoMedicion()` retornaba mapa vacío** → `_buildTipoMedicionCache()` construye desde catálogo real
8. **`_parseError` crasheaba con strings <100 chars** → usa `.clamp()` en vez de `substring(0,100)`
9. **`refinarRutina` crasheaba con catálogo vacío** → guard defensivo al inicio
10. **`DateTime.parse` sin `tryParse`** → `DateTime.tryParse` en feedback engine
11. **`peso corporal` vs `peso_corporal` inconsistencia** → normalizado en filtros de equipamiento
12. **Denominador de 1RM cercano a cero con pesos <3kg** → guard `if (peso < 3) return peso` en `calcular1RM()`

### Documentación actualizada
- `04-data-model.md` (v4.2): Nuevas tablas `historial_objetivos` y `recomendaciones_pendientes`. Columna `failed_reps` en `series_sesion`. ER actualizado.
- `06-frontend.md` (v5.0): Nuevas secciones del motor de recomendaciones, providers del orquestador, UI de generación rápida.
- `07-backend.md` (v3.0): Migraciones 0046-0049. Nuevos servicios de infraestructura. pg_cron.
- `10-deployment.md` (v2.0): Configuración de pg_cron para el job nocturno.
- `03-architecture.md` (v4.0): Nuevos servicios, providers, estructura de carpetas actualizada.
- `15-ia-recomendacion-sistema.md` (v4.0): Fase 0 (unificación objetivos), motor de reglas determinista, orquestador, refinamiento IA.
- `14-changelog.md`: Esta entrada.

---

## [4.0.0] — 06-06-2026

### Pesos por serie en rutinas (DB + Frontend)

**Nueva migración 0045 (`20260605_0045_pesos_por_serie.sql`):**
- Añade columna `pesos_kg jsonb` a `seleccion_de_ejercicios`.
- Permite asignar un peso diferente por cada serie del ejercicio.
- Si es `null`, todas las series usan el valor de `peso_kg`.

**Modelo Dart actualizado:**
- `SeleccionEjercicioDb.pesosKg` (`List<double>?`) añadido en `db_models.dart:327`.
- Serialización en `fromMap()` (línea 343-347) y `toMap()` (línea 371).
- `EjercicioInput.pesosKg` en `rutina_provider.dart:786` para flujo de creación.
- `crearRutinaCompleta()` serializa `pesos_kg` en el INSERT (línea 533).
- `actualizarEjercicioDia()` soporta `pesos_kg` en el patch desde `rutina_detalle_screen.dart:441`.

**UI — Editor de peso por serie:**
- `rutina_detalle_screen.dart`: Nueva sección inline con toggle "Mismo peso en todas las series". Cuando se desactiva, aparecen `N` campos de peso (uno por serie) con steppers ±.
- `nueva_rutina_screen.dart`: `_EjercicioCompacto` también incorpora el toggle y campos por serie.
- `sesion_en_vivo_screen.dart`: `_EjercicioLiveCard` prellena cada campo de peso desde `pesos_kg[i]` cuando existe, con fallback a `peso_kg`.

### Navegación post "Completar rutina"

- `_completarRutina()` en `rutina_detalle_screen.dart:345` ahora navega a `context.go('/bienestar')` después de actualizar el estado de la rutina a `'completado'`.
- Invalida `rutinasUsuarioProvider` + `semanasDeRutinaProvider` antes de navegar.

### Live Session: adaptación real con `seriesReducidas`

- La bandera `_seriesReducidas` ahora se consume efectivamente en `sesion_en_vivo_screen.dart`:
  - Se pasa como `seriesReducidas` a `_EjerciciosList` → `_EjercicioLiveCard`.
  - `_EjercicioLiveCard` calcula `seriesEfectivas` = `seriesReducidas ? (e.series - 1).clamp(1, 99) : e.series`.
  - El display de series muestra `(adaptado)` en naranja y el borde de la tarjeta se vuelve naranja con opacidad.
  - `List.generate` usa `seriesEfectivas` en lugar de `e.series`.
- Mejorado el texto del check-in overlay: "Tus respuestas adaptan el entrenamiento y mejoran las recomendaciones futuras."

### Rutina completada: UI read-only + reutilizar

- El botón "Completar rutina" solo se muestra cuando `!todasCompletadas` (quedan semanas pendientes).
- Cuando `todasCompletadas == true`:
  - Se oculta el icono de editar (`actions`).
  - Aparece un botón "Reutilizar rutina" con icono `refresh_rounded` en actions.
  - Aparece `_buildBotonReutilizarRutina()` en la parte inferior.
  - `_editarRutina()` tiene safety gate que retorna temprano si completada (línea 483).
- `_reutilizarRutina()` (línea 357) clona la jerarquía completa:
  - Crea nueva rutina con sufijo " (copia)", estado activo, visibilidad privada.
  - Itera semanas → días → ejercicios, copiando todos los parámetros (`peso_kg`, `pesos_kg`, `duracion_segundos`, `distancia_metros`, `tiempo_isometrico_segundos`).
  - Invalida `rutinasUsuarioProvider` y navega a `/bienestar/rutina/$nuevoId`.
- Se muestra `_CelebracionDialog` al detectar que todas las semanas están completadas.

### Documentación actualizada
- `06-frontend.md` (v4.4): Sección 5.7 — UI read-only y reutilizar. Sección 5.8 — Pesos por serie con toggle. Sección 6 actualizada con adaptación real y pesos prellenados. Sección 3.5 — `actualizarEjercicioDia` con pesos_kg.
- `07-backend.md` (v2.7): Migración 0045 añadida al historial.
- `04-data-model.md` (v3.9): Columna `pesos_kg jsonb` en `seleccion_de_ejercicios` y definición de `SeleccionEjercicioDb` con `pesosKg`.
- `14-changelog.md`: Esta entrada.

---

## [3.9.0] — 05-06-2026

### Flujo "Agregar a rutina" desde detalle de ejercicio + Resumen enriquecido + Dataset Lyfta

**Flujo "Agregar a rutina" contextual:**
- `detalle_ejercicio_screen.dart`: Nuevo parámetro `showAddButton` (default `true`). El botón "Agregar a rutina" ahora es contextual: se oculta cuando se navega desde el editor de rutina (`_EjercicioCompacto`) porque el ejercicio ya está añadido. Se muestra cuando se navega desde la cuadrícula de selección.
- `seleccion_ejercicios_screen.dart`: `_verDetalle` ahora usa `await Navigator.of(context).push<EjercicioDb>(MaterialPageRoute(...))` en lugar de `context.push` sin await. Al recibir el `EjercicioDb` de vuelta, se añade a la selección automáticamente.
- `app_router.dart`: La ruta `/bienestar/ejercicio/:id` acepta `extra: true` para ocultar el botón "Agregar a rutina".
- `nueva_rutina_screen.dart` (línea ~2371): Navegación desde `_EjercicioCompacto` usa `extra: true` para que el detalle oculte "Agregar a rutina".

**Pantalla de resumen (`_buildPaso3`) enriquecida:**
- Corrección de bug: Los `Row` con `_resumenFila` ahora envuelven hijos en `Expanded` para evitar `RenderFlex` con `BoxConstraints(unconstrained)`.
- Visualización de `descripcion` (campo `_descCtrl.text`) cuando no está vacío.
- Chips de `tipo_semana` (periodización): Adaptación (ámbar), Carga (naranja), Pico (rojo), Descarga (teal).
- `_buildExerciseSummaryRow` reescrito para mostrar chips por ejercicio:
  - Chip "Circuito" (púrpura) si `esCircuito == true`
  - Chip de `finalidad` (Hipertrofia/Fuerza/Cardio...) con color
  - Chip de `modalidadEntrenamiento` (Fuerza/Aeróbica/Metabólica/Movilidad) con color
- `_buildParametrosEjercicio` reescrito para usar `tipoMedicion` (array) en vez de `finalidad` (string). Muestra dinámicamente: series×reps para fuerza, series×tiempo para isométrico, duración/distancia para cardio, peso, descanso.
- `esCircuito = true` oculta series×reps y muestra solo duración.
- Nuevos helpers: `_calcularTipoSemana()`, `_buildTipoSemanaChip()`, `_finalidadBadge()`, `_circuitoChip()`, `_buildModalidadChip()`, `_colorFinalidad()`, `_fmtDistancia()`.
- Función top-level `fmtDuracion(int segundos)` extraída para compartir entre `_NuevaRutinaScreenState` y `_EjercicioCompactoState`.

**`_EjercicioCompacto` — `esCircuito` oculta contador de series:**
- En `_camposFuerza`, las pills de Series y Reps se ocultan cuando `esCircuito == true`, mostrando en su lugar un campo de Duración. Esta lógica ya existía y se verificó correcta.

**Nuevo dataset Lyfta documentado:**
- Pipeline completo de 8 etapas documentado en `docs/17-dataset-lyfta.md`: scraping con Playwright → limpieza de URLs → derivación de videos → descarga → generación de dataset → pulido de nombres (2 pasadas) → procesamiento de previsualizaciones.
- 682 ejercicios en español con videos MP4 y previsualizaciones.
- Formato `dataset_final.json` con: nombre, descripción, instrucciones (3 pasos), dificultad, finalidad, partes_cuerpo, musculos_objetivo/secundarios, equipamientos, url_video, url_preview.
- Videos y previsualizaciones alojados en Cloudflare R2.

**Documentación actualizada:**
- `06-frontend.md` (v4.3): Sección 2.1 — Flujo "Agregar a rutina" con diagrama Mermaid. Secciones 8.4-8.5 — Resumen enriquecido y modo circuito con tablas de colores, helpers y correcciones.
- `01-introduction.md`: Tabla de estructura ampliada a 17 documentos.
- `17-dataset-lyfta.md` (NUEVO): Documentación completa del dataset Lyfta (12 secciones, 8 etapas, formato JSON, mapeo BD, estadísticas).
- `14-changelog.md`: Esta entrada.
- `AGENTS.md`: Corrección de conteo de docs (15→17).

---

## [3.8.0] — 29-05-2026

### url_imagen para todos los músculos + exercise_db_id eliminado + catálogo limpiado

**musculos.json con url_imagen completo (51/51):**
- 12 músculos que faltaban ahora tienen `url_imagen` apuntando a R2.
- Corregido `deltoides posteriores` que apuntaba a `deltoides.png` → ahora `deltoide_posterior.png`.

**nuevos_ejercicios.json: 6 duplicados eliminados (95→89):**
- `Zancadas con mancuernas`, `Circuito de descompresión y movilidad espinal`, `Extensión torácica pasiva`, `Circuito de ejercicios abdominales`, `Elevaciones de deltoides con mancuernas`, `Remo sentado en polea`.
- 89 ejercicios únicos (56 demic + 21 exercisedb + 12 gym_workout).

**Flutter sincronizado con BD:**
- `MusculoDb`: añadido campo `urlImagen` + `copyWith`. `CatalogosEjercicios`: helper `urlImagenMusculo()`.
- `ejercicios_repository.dart`: `fetchCatalogos` ahora consulta `url_imagen`.
- Fix: `dashboard_screen.dart:277` — `tieneTareasReto` → `tieneHitosReto`.

**Migración 0028 corregida:**
- Orden: drop MV → drop view → drop column → recreate view (evita error de dependencia `exercise_db_id`).

**Migraciones:** 0027 (89 ejercicios con ON CONFLICT), 0028 (orden corregido), 0029 (51 URLs), 0030 (9 músculos eliminados).

**Documentación:** 04-data-model.md v3.8, 07-backend.md v2.6, 13-maintenance.md v1.4, 14-changelog.md entrada 3.8.0.

---


**musculos.json con url_imagen completo (51/51):**
- 12 músculos que faltaban ahora tienen `url_imagen` apuntando a R2: cuádriceps, elevador de la escápula, estabilizadores de tobillo, extensores de muñeca, flexores de la cadera, flexores de muñeca, muñecas, serrato anterior, sistema cardiovascular, supraespinoso, sóleo, tensor de la fascia lata.
- `manos` ya tenía url_imagen correctamente (`manos.png`).
- Corregido `deltoides posteriores` que apuntaba a `deltoides.png` → ahora apunta a `deltoide_posterior.png`.

**Migración 0028 (`20260528_0028_eliminar_exercise_db_id.sql`):**
- Elimina triggers de refresco de `mv_ejercicios_completos`.
- Dropea la función `refrescar_mv_ejercicios_completos()`.
- Dropea la vista materializada `mv_ejercicios_completos` (legacy, no usada desde 0018).
- Dropea columna `exercise_db_id` de `ejercicios`.
- Recrea `v_ejercicios_completos` SIN `exercise_db_id` y con ORDER BY en los array_agg.

**Migración 0029 (`20260529_0029_agregar_url_imagen_musculos.sql`):**
- `ALTER TABLE musculos ADD COLUMN url_imagen text`.
- UPDATE con 51 CASE WHEN para poblar todas las rutas R2.

**Migración 0030 (`20260529_0030_eliminar_musculos_duplicados.sql`):**
- Remapea 9 músculos redundantes en tablas puente (`ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`).
- DELETE de los 9 músculos redundantes: abdominales, deltoides anteriores, dorsales, glúteos, hombros, parte interna del muslo, pectorales, tibiales, tobillos.

**Documentación:** 04-data-model.md v3.8, 07-backend.md v2.6, 13-maintenance.md v1.4, 14-changelog.md entrada 3.8.0.

---


### Deprecación de `exercise_db_id` + ampliación de finalidad + nuevos ejercicios Demic

**Migración 0019 (`20260527_0019_ampliar_finalidad.sql`):**
- Amplía el CHECK de `finalidad` en `ejercicios` para aceptar: `hipertrofia`, `resistencia`, `movilidad`.
- La UI y los prompts de IA quedan preparados para estas nuevas categorías.

**Migración 0020 (`20260528_0020_deprecar_exercise_db_id.sql`):**
- `exercise_db_id` pasa a nullable, eliminando UNIQUE y el índice `idx_ejercicios_exercise_db_id`.

**Nuevos ejercicios desde Demic:**
- 8 ejercicios nuevos insertados desde `supabase/nuevos_ejercicios.json`.
- 2 músculos nuevos: glúteo medio, glúteo mayor.
- 1 equipamiento nuevo: almohada.
- Videos MP4 descargados por lote con Internet Download Manager, alojados en `demic/nuevos_para_r2/`.
- Archivo `demic/nombres_videos.txt` con 56 slugs únicos para subida a R2.

**Seed scripts actualizados:**
- `seed_ejercicios.py` y `seed_gym_workout.py`: ya no incluyen `exercise_db_id` en el payload.
- `seed_nuevos_ejercicios.py`: ahora restaura relaciones N:M incluso para ejercicios existentes usando upsert.

**Refactorización Flutter — `exerciseDbId` eliminado:**
- `EjercicioDb`: campo `exerciseDbId` eliminado del modelo, `fromMap` y `toMap`.
- `ejercicios_repository.dart`: `exercise_db_id` removido de las queries.
- `detalle_ejercicio_screen.dart`: sección "ExerciseDB ID" eliminada del widget `_InfoTab`.
- `nueva_rutina_screen.dart`: matching por `ex?.id` en vez de `ex?.exerciseDbId ?? ex?.id`.
- `recomendacion_ia_service.dart`: `e.id` directo en vez de `e.exerciseDbId ?? e.id`.

**Documentación actualizada:**
- `04-data-model.md`: v3.3 — schema actualizado (finalidad ampliada, exercise_db_id deprecado, vista recreada, catálogos expandidos).
- `07-backend.md`: v2.2 — migraciones 0019 y 0020 agregadas al historial.
- `13-maintenance.md`: v1.2 — flujo Demic documentado, catálogo actual (110 ejercicios, 13 partes, 60 músculos, 37 equipos, 56 slugs), sección de deprecación.
- `14-changelog.md`: entrada 3.6.0 agregada.

---

## [3.7.0] — 28-05-2026

### Reestructuración integral del catálogo de ejercicios

**JSONs consolidados:**
- `supabase/nuevos_ejercicios.json`: 95 ejercicios unificados con campo `fuente` (demic=62, exercisedb=21, gym_workout=12).
- `supabase/musculos.json`: 60 músculos unificados.
- `supabase/partes_cuerpo.json`: 13 partes del cuerpo unificadas.
- `url_video` con ruta R2 según fuente: `ejercicios/{fuente}/{slug}.{ext}`.

**Videos renombrados y organizados:**
- `r2_staging/demic/`: 55 MP4s con slugs descriptivos.
- `r2_staging/exercisedb/`: 30 GIFs renombrados de exerciseId a slug.
- `r2_staging/gym_workout/`: 22 MP4s renombrados de UUID a slug.
- 817 MP4s sobrantes de Gym Workout eliminados.
- 5 ejercicios Gym Workout recuperados de deduplicación incorrecta.

**Seed unificado:**
- `supabase/seed_todo.py`: script único que reemplaza a seed_ejercicios.py, seed_nuevos_ejercicios.py, seed_gym_workout.py (ELIMINADOS).
- Migración 0021: DELETE en orden FK para limpieza total antes de re-carga.

**Reorganización de carpetas:**
- `exercisedb/`: raw/, traducciones/, scripts/.
- `demic/`: originales/ (403 videos fuente).
- `r2_staging/`: staging centralizado para Cloudflare R2 (107 archivos).
- `Gym Workout/`: eliminado (vacío).
- `_archivo/`: archivos obsoletos (GIFs otras resoluciones, scripts temporales).

**.gitignore actualizado:** r2_staging/, demic/originales/, demic/*.mp4, demic/*.py, _archivo/, .aiassistant/, .idea/.

**Seguridad — SECURITY INVOKER:**
- Migración 0022: `v_ejercicios_completos` cambiada de SECURITY DEFINER (default) a SECURITY INVOKER. La vista ahora ejecuta con los permisos RLS del usuario consultante. Compatible con las políticas `public-read` existentes en tablas subyacentes.

**Dificultad alineada con JSON:**
- Migración 0023: CHECK de `dificultad` en `ejercicios` cambiado de `('facil','medio','dificil')` a `('principiante','intermedio','avanzado')`.

**Nuevo JSON: equipamientos.json:**
- `supabase/equipamientos.json`: 24 equipamientos con `nombre` y `fuente`, extraídos de `nuevos_ejercicios.json`.

**Migrations de datos (0024-0027):**
- 0024: INSERT de 24 equipamientos desde `equipamientos.json`.
- 0025: INSERT de 13 partes del cuerpo desde `partes_cuerpo.json`.
- 0026: INSERT de 60 músculos desde `musculos.json`.
- 0027: UNIQUE en `ejercicios.nombre` + INSERT de 95 ejercicios desde `nuevos_ejercicios.json`.

**seed_todo.py refactorizado:**
- Ya no inserta catálogos ni ejercicios (lo hacen las migraciones 0024-0027).
- Solo verifica existencia en BD y restaura las relaciones N:M (musculos, partes, equipos).

**Documentación:** 04-data-model.md v3.7, 07-backend.md v2.5, 13-maintenance.md v1.3, 14-changelog.md entrada 3.7.0.

---



### Finalidad del ejercicio: campos dinámicos por tipo + GIF previews

**Migración 0018 (`20260519_0018_finalidad_ejercicios.sql`):**
- Nueva columna `finalidad` en `ejercicios`: `TEXT NOT NULL DEFAULT 'fuerza'` con CHECK (`fuerza`, `cardio`, `isometrico`).
- Índice `idx_ejercicios_finalidad` para filtrado rápido por tipo.
- Nuevas columnas en `seleccion_de_ejercicios`:
  - `duracion_segundos INT` — duración del cardio en segundos.
  - `distancia_metros INT` — distancia recorrida (opcional, solo cardio).
  - `tiempo_isometrico_segundos INT` — tiempo de sujeción (solo isométrico).
- Vista `v_ejercicios_completos` recreada como vista normal (no materializada) con subqueries, incluyendo el campo `finalidad`. Grants actualizados.

**Enum `FinalidadEjercicio` (`db_models.dart:96-137`):**
- Valores: `fuerza`, `cardio`, `isometrico`.
- Métodos: `.fromString()` para deserializar desde BD, `.etiqueta` para UI en español, `.icono` con emoji representativo (🏋️ 🏃 🧘).
- `EjercicioDb` ahora incluye campo `finalidad` (leído de `v_ejercicios_completos`).

**Modelo `SeleccionEjercicioDb` actualizado (`db_models.dart:280-349`):**
- Nuevos campos opcionales: `duracionSegundos`, `distanciaMetros`, `tiempoIsometricoSegundos`.
- `fromMap()` y `toMap()` actualizados para incluir las nuevas columnas.

**Widget `_EjercicioCompacto` con campos dinámicos (`nueva_rutina_screen.dart:1748-2067`):**
- Switch statement en `_buildCamposDinamicos()` que renderiza campos específicos según finalidad:
  - **Fuerza:** Series, Repeticiones, Descanso, Peso (kg) — grid 2×2 original.
  - **Cardio:** Intervalos (=series), Duración (input libre tipo "5m 30s" → parseado a segundos), Distancia (metros, opcional), Descanso.
  - **Isométrico:** Series, Tiempo de sujeción (segundos), Descanso.
- `_finalidadChip()`: badge coloreado (naranja=fuerza, teal=cardio, índigo=isométrico) con icono + etiqueta.
- `_parseDuracion()`: parser de texto libre que acepta formatos "5m 30s", "5:30", "300", "5 min".

**Widget `_MiniGifPreview` (`nueva_rutina_screen.dart:1544-1623`):**
- Miniatura de GIF con `CachedNetworkImage`, tamaño configurable (48px en buscador, 42px en tarjeta compacta).
- Tap → diálogo de vista ampliada (280px, fondo negro semitransparente, botón de cierre).
- Placeholder y error widget con iconos semánticos.

**IA prompts actualizados con reglas de finalidad (`recomendacion_ia_service.dart`):**
- Los 3 prompts principales incluyen sección `REGLAS SEGUN FINALIDAD DEL EJERCICIO`:
  - `fuerza`: usa `series`, `repeticiones`, `segundosDescanso`, `pesoKg`.
  - `cardio`: usa `duracionSegundos` (600-3600s), opcional `distanciaMetros`, `series`=intervalos. `repeticiones: 0`, `pesoKg: null`.
  - `isometrico`: usa `tiempoIsometricoSegundos` (10-120s). `repeticiones: 0`, `pesoKg: null`.
  - Prohibición de combinar campos de distintas finalidades en un mismo ejercicio.
- Reglas específicas para cardio (intervalos 1-10, descanso 30-120s) e isométrico (series 2-4).
- El catálogo de ejercicios enviado a Gemini ahora incluye el campo `finalidad`.

**Seed script actualizado (`seed_ejercicios.py`):**
- Nueva función `_generar_finalidad(ej: dict) -> str` con clasificación automática:
  - **Cardio:** detecta por músculo `cardiovascular`, parte del cuerpo `cardio`, o 25+ palabras clave en nombre (bilingües: correr/running, nadar/swimming, saltar/jump, burpees, etc.).
  - **Isométrico:** detecta por plancha/plank, isométrico/isometric, wall sit, puente estático, static hold, L-sit, hollow body, dead hang, sentadilla estática.
  - **Fuerza:** default para todo lo demás.
- El seeding ahora inserta el campo `finalidad` en ejercicios nuevos Y actualiza ejercicios existentes (migración de datos antiguos).

### Documentación actualizada
- `04-data-model.md` (v3.2): Columna `finalidad` en ER y SQL de `ejercicios`. Índice `idx_ejercicios_finalidad`. Nuevas columnas en `seleccion_de_ejercicios`. `finalidad` en vista `v_ejercicios_completos`. Nueva sección 2.2.7 documentando finalidad, columnas por tipo y clasificación automática.
- `06-frontend.md` (v4.2): Sección 8.1 enum `FinalidadEjercicio`. Sección 8.2 widget `_EjercicioCompacto` con switch dinámico y tabla de campos por finalidad. Sección 8.3 widget `_MiniGifPreview` con diálogo ampliado. Componentes `FinalidadBadge` y `_MiniGifPreview` en tabla de componentes.
- `07-backend.md` (v2.1): Migración 0018 añadida al historial completo.
- `13-maintenance.md` (v1.1): Nueva sección 1.6 documentando `_generar_finalidad()` con criterios de clasificación.
- `15-ia-recomendacion-sistema.md` (v3.4): Nueva sección 5.7 con reglas de finalidad en prompts, formato JSON esperado, reglas de cardio e isométrico.
- `14-changelog.md`: Esta entrada.

---

### Trigger de cascada días → semanas + fixes de UI reactiva

**Migración 0020 — Trigger `trg_dias_rutina_estado`:**
- Nuevo trigger PostgreSQL que mantiene `semanas_rutina.estado` sincronizado con el estado de sus días.
- Si todos los días están `'completado'` → semana `'completada'`. Si algún día no → semana `'pendiente'`.
- Dispara en `INSERT`, `UPDATE OF estado` y `DELETE` sobre `dias_rutina`.
- Elimina la lógica de cascada manual que estaba duplicada en el cliente (20 líneas en `finalizarSesion()`).

**Fix: botón "Completar rutina" ahora aparece correctamente:**
- `finalizarSesion()` ahora recibe `rutinaId` como parámetro obligatorio.
- Tras marcar el día como `'completado'`, se invalidan `diasDeSemanaProvider` + `semanasDeRutinaProvider(rutinaId)`.
- El trigger de BD actualiza la semana, y la UI lo refleja inmediatamente.

**Fix: día se revierte a pendiente al modificar ejercicios:**
- Ambas versiones de `_invalidarDiaSiCompletado()` (en `_DiaCardState` y `_EjercicioRowState`) ahora invalidan `semanasDeRutinaProvider` para refrescar el selector de semanas.
- La cascada de revertir semana se delega al trigger de BD.
- Se añadió invalidación de `ejerciciosDeDiaProvider` + `nombresEjerciciosProvider` en la versión de `_EjercicioRowState`.

**Fix: carga reactiva de ejercicios con nombres actualizados:**
- `agregarEjercicioADia()`, `quitarEjercicioDeDia()`, `actualizarEjercicioDia()` ahora también invalidan `nombresEjerciciosProvider(diaId)`.
- Los nombres de ejercicios se refrescan instantáneamente al añadir/quitar/editar.

**Fix: eliminado mensaje molesto "Ya has hecho check-in hoy":**
- `_lanzarCheckInOverlay()` ahora consulta `estadoDiarioHoyProvider` antes de mostrar el overlay.
- Si ya existe check-in hoy, el overlay no se muestra en absoluto (antes aparecía brevemente con el mensaje y se auto-cerraba).
- Eliminada la lógica `_yaExisteCheckIn`, `_verificar()` y el mensaje del widget `_CheckInOverlay`.

### Documentación actualizada
- `04-data-model.md`: Documentado trigger `trg_dias_rutina_estado` con SQL completo.
- `03-architecture.md`: Diagrama de secuencia actualizado con `rutinaId`, trigger y nuevas invalidaciones. Sección 9.3 actualizada al flujo overlay actual.
- `06-frontend.md`: Tabla de funciones actualizada con `rutinaId`, invalidaciones de `nombresEjerciciosProvider` y flujo de check-in corregido.
- `14-changelog.md`: Esta entrada.

---

## [3.3.0] — 13-05-2026

### Opción B refinada: Check-in durante el primer descanso + adaptación IA

**Nuevo flujo de sesión en vivo (`sesion_en_vivo_screen.dart`):**
- Al pulsar "Iniciar" → el cronómetro y la lista de ejercicios aparecen **inmediatamente** (antes: diálogo de check-in bloqueante antes de empezar).
- El check-in diario se muestra durante el **primer periodo de descanso** (tras completar la primera serie), como overlay no bloqueante. El descanso sigue corriendo.
- Si ya existe un check-in para hoy (`estadoDiarioHoyProvider` != null), no se vuelve a preguntar.

**Diagrama de flujo:**
```
RutinaDetalleScreen → "Iniciar"
  → LiveSessionScreen (cronómetro visible de inmediato)
  → Usuario empieza 1er ejercicio
  → Completa 1ª serie → descanso 90s
      → Overlay "¿Cómo te sientes?" (no bloquea descanso)
      → Si adaptación necesaria → diálogo SynaptixFit AI con sugerencias
  → Sesión continúa con ajustes aplicados
```

**Sistema de adaptación post-check-in (reglas locales, sin IA):**
- Fórmula de fatiga: `(6-sueño)×5 + (estrés-1)×5 + (6-energía)×4 + (dolor-1)×7`
- **Fatiga > 50:** sugerencia "Reducir 1 serie por ejercicio" + "Bajar peso 10% en compuestos"
- **Dolor ≥ 3 + zonas:** sugerencia "Evitar ejercicios de [zona1, zona2]"
- **Energía ≤ 2:** sugerencia "Reducir intensidad general"
- Cada sugerencia es seleccionable individualmente en el diálogo de adaptación.

**Widget `_AdaptacionDialog`:**
- Lista de sugerencias con iconos semánticos (fitness_center, healing, battery, monitor_weight)
- Cada sugerencia es tappeable para seleccionar/deseleccionar
- Botones: "Ignorar todo", "Aplicar todos", "Aplicar solo este"
- Las sugerencias seleccionadas se aplican vía callbacks (`VoidCallback aplicar`)

**Banners visuales durante la sesión adaptada:**
- Banner naranja: "Sesión adaptada: -1 serie por ejercicio"
- Banner rojo: "Se evitarán ejercicios de: [zonas]"

**Fix overflow en `_CheckInDialog`:** `Text` envuelto en `Expanded` en el title row.

### Resto de features 3.3.0

(Ver entrada anterior completa con todos los features)

### Botón para cancelar recomendación IA

- Los 3 botones de IA en `NuevaRutinaScreen` ahora muestran botón **"Cancelar"** durante la carga.
- Se descarta la petición HTTP en curso mediante `CancelToken` de `dio`.
- Snackbar "Recomendación cancelada". Formulario intacto para edición manual.

### Campo de peso con soporte decimal corregido

- `TextField` de peso (`pesoKg`) en Paso 2 ahora acepta correctamente valores decimales (ej: `75.5` kg).
- Teclado numérico con `TextInputType.numberWithOptions(decimal: true)` e `inputFormatters`.
- Label "Peso", hint "— kg", icono de balanza.

### Vista detallada con drill-down en "Revisa tu rutina"

**Nuevo sistema expand/colapsar en `RutinaDetalleScreen`:**
- `_DiaCard` convertido a `ConsumerStatefulWidget` con estado local `_expandido`.
- **Colapsado:** vista previa compacta con hasta 3 ejercicios (nombre, series×reps, peso). "+ N ejercicios más" si hay más de 3.
- **Expandido:** listado completo de ejercicios con controles de edición inline.
- Flecha animada con `AnimatedRotation` (0° → 180°). Borde de la card cambia de color al expandirse.
- Los nombres de ejercicios en preview cargados vía `FutureBuilder` desde tabla `ejercicios`.

### Botón "Sugerir Rutina con IA" en pantalla Rutinas

**Nuevo botón en `RutinasComunidadScreen`:**
- `FilledButton.tonalIcon` verde con icono `Icons.auto_awesome`, texto "Sugerir Rutina con IA".
- Navega a `NuevaRutinaScreen` con `extra: {'autoRecomendar': true}`.

**Auto-trigger implementado en `NuevaRutinaScreen`:**
- Nuevo parámetro `autoRecomendar` (bool, default false) en constructor.
- `initState`: si `autoRecomendar == true`, llama `_recomendarRutina()` vía `addPostFrameCallback`.
- Router actualizado: la ruta lee `state.extra` y pasa `autoRecomendar`.

### Robustecemos la generación IA contra fallos

**Dio con timeouts (`recomendacion_ia_service.dart`):**
- Cliente HTTP de Gemini ahora tiene `connectTimeout: 15s`, `receiveTimeout: 60s`, `sendTimeout: 15s`.
- Antes: `Dio()` sin timeouts → llamadas podían colgar indefinidamente o fallar en ciertas redes.

**Timeout de 45s en las 3 llamadas a Gemini:**
- Los métodos ahora envuelven `await servicio.generar*()` con `.timeout(Duration(seconds: 45))`.
- Mensajes diferenciados: "La IA tardó demasiado en responder" (TimeoutException) vs "Verifica tu conexión" (error genérico).

**Inyección de dependencias fresca (invalida providers antes de cada llamada):**
- Los 3 métodos de IA (`_recomendarRutina`, `_recomendarEjercicios`, `_sugerirEjerciciosIA`) ahora invalidan los 4 providers (`perfilBienestar`, `ejercicios`, `historialSesion`, `estadoDiario`) antes de leerlos. Así se evita cualquier error cacheado de ejecuciones previas.

**Carga en paralelo unificada en los 3 métodos:**
- `_sugerirEjerciciosIA` ahora también usa `Future.wait` + `_obtenerOConTimeout` (antes eran 4 `await` secuenciales).
- Los 3 métodos comparten el mismo patrón: invalidar → parallel fetch → timeout 20s → guard cancel.

**Timer blindado contra doble disparo:**
- `_iniciarSecuenciaMensajes()` ahora cancela el timer previo (`_timerMensajes?.cancel()`) antes de crear uno nuevo. Evita timers huérfanos si se llama dos veces seguidas.

### Pantalla profesional de sugerencia de ejercicios por día

**Nuevo `_buildPantallaGeneracionEjerciciosDia` en Paso 2:**
- Se muestra cuando el usuario pulsa "Sugerir ejercicios con IA" en un día del editor (Paso 2).
- Estética diferenciada: icono con gradiente violeta (`#7C3AED → #A78BFA`), glow violeta, icono `fitness_center`.
- Pulso animado más rápido (900ms, 0.93→1.07).
- Badge "Personalizando ejercicios" con borde violeta.
- Barra de progreso color `#A78BFA`.
- 8 mensajes secuenciales específicos para sugerencia de ejercicios por día: "Analizando ejercicios del día..." → "Identificando grupos musculares..." → "Buscando ejercicios complementarios..." → "Seleccionando según tu equipamiento..." → "Ajustando series y repeticiones..." → "Optimizando tiempos de descanso..." → "Verificando balance muscular..." → "¡Casi listo! Últimos ajustes..."
- Botón Cancelar disponible (mismo comportamiento que en Paso 1).

**`_buildPaso2` ahora muestra la pantalla de carga:**
- Si `_loadingIA == true`, Paso 2 muestra `_buildPantallaGeneracionEjerciciosDia` en lugar del editor.

- `autofocus` en campo Nombre ahora es condicional: `autofocus: !widget.autoRecomendar`.
- Cuando se pulsa "Sugerir Rutina con IA", el teclado no se abre, permitiendo ver la pantalla completa.

### Pantalla de generación IA profesional

**Pantalla de carga unificada para rutina y ejercicios (`_buildPantallaGeneracion`):**
- Se muestra siempre que `_loadingIA == true` (ya no solo en modo autoRecomendar). Cubre tanto "Recomendar rutina con IA", "Recomendar ejercicios" como el botón "Sugerir Rutina con IA".
- Icono de IA con gradiente verde y glow, pulsando suavemente (`TweenAnimationBuilder` 0.92→1.08).
- Barra de progreso indeterminada estilizada (200px, color `#00C853`).
- Subtítulo dinámico: "Generando tu rutina personalizada" vs "Generando estructura de ejercicios".

**Secuencias de mensajes por tipo de carga:**
- **Rutina** (8 etapas): perfil → historial → estado diario → catálogo → periodización → objetivo → semanas → ¡casi listo!
- **Ejercicios** (8 etapas): estructura → periodización → grupos musculares → ejercicios compatibles → volumen → días → progresión → ¡últimos ajustes!

**Botón Cancelar:**
- `TextButton.icon` rojo al final de la pantalla de carga.
- Llama a `_cancelarCargaIA()`: detiene el timer, limpia `_loadingIA` / `_tipoCarga`, muestra Snackbar "Recomendación cancelada".
- Guard `if (!_loadingIA) return;` en ambos métodos de recomendación tras el await de Gemini, para descartar respuestas tardías si el usuario canceló.

### Documentación actualizada
- `06-frontend.md` (v3.3): Sección 5.0 drill-down, 4.3 cancelación IA, 4.4 campo decimal, 4.6 auto-trigger.
- `15-ia-recomendacion-sistema.md` (v3.3): Sección 4.0 vía rápida, 12.1 cancelación manual.
- `12-user-guide.md` (v3.3): Flujo real 3 pasos + IA, navegación drill-down, vía rápida.
- `14-changelog.md`: Esta entrada.

---

## [3.2.0] — 12-05-2026

### Sistema de recomendación IA: series dinámicas y descripciones inteligentes

**Series personalizadas por ejercicio (`recomendacion_ia_service.dart`):**
- Las series ya no son fijas (3). Ahora la IA las personaliza según:
  - Objetivo: fuerza 3-5, ganar_masa 3-4, perder_peso 2-3, resistencia 2-3, movilidad 2-3.
  - Minutos/sesión: <30→2-3, 30-45→2-4, 45-90→3-5, >90→4-5.
  - Tipo de ejercicio: compuestos +1 serie, aislados -1 serie.
  - Fatiga diaria: puntuación > 50 reduce 1 serie.
  - Semana de periodización: adaptación 2-3, carga 3-4, pico 4-5, descarga 2.
- Añadido `$estadoTxt` al Prompt #2 (se calculaba pero no se usaba).

**Descripciones sin números hardcodeados:**
- Nuevas reglas en Prompt #1: la IA NO incluye números concretos (días, semanas, sesiones) en la descripción.
- La descripción se centra en la filosofía de entrenamiento (enfoque, metodología, tipo de ejercicios).
- La descripción permanece válida aunque el usuario modifique semanas/días manualmente.

### Pantalla de perfil con sincronización en tiempo real optimizada

**Nuevo provider cacheado con invalidación selectiva (`perfil/application/perfil_provider.dart`):**
- `perfilUsuarioProvider` — usuario + perfil bienestar (2 queries, cacheado).
- `perfilBienestarCompletoProvider` — perfil + historial peso (2 queries).
- `perfilActividadProvider` — sesiones, logros, calorías (3 queries en paralelo).
- `perfilPreferenciasProvider` — preferencias de notificación (1 query).
- `perfilCompletoProvider` — compuesto para compatibilidad con otras pantallas.
- Enum `PerfilCambio` (nombre, bienestar, preferencias, todo) para invalidar solo lo necesario.
- Sin `autoDispose` → keepAlive implícito en memoria.
- Al cambiar nombre: solo 2 queries vs 7 anteriores. Al cambiar bienestar: solo 3 queries.

**Refactor de `perfil_screen.dart`:**
- Eliminada carga manual en `initState()` con 7 consultas Supabase secuenciales.
- Eliminadas: `_loading`, `_data`, `_cargar()`, `_cargarPerfil()`, clase `_PerfilData`.
- `build()` usa `ref.watch()` sobre providers individuales.
- `_onPerfilActualizado` recibe `PerfilCambio` para invalidación dirigida.

### Nueva documentación

- `docs/15-ia-recomendacion-sistema.md` — Documentación completa del sistema de recomendación IA (17 secciones, 10 diagramas Mermaid/ASCII, 12 tablas de datos, 24 referencias a código).

---

## [3.1.0] — 11-05-2026

### Rediseño completo de la pantalla de Perfil (`PerfilScreen`)

**Hero Header atlético:**
- Fondo con gradiente oscuro de 3 tonos navy: `#0A1628` → `#152238` → `#0D1B2A`.
- Avatar circular de 88px con anillo de gradiente verde (`#72FE8G` → `#006E2D`) y sombra glow (`boxShadow` con opacidad 25%).
- `Image.network` con `loadingBuilder` (muestra inicial durante carga) y `errorBuilder` (fallback a inicial estilizada: texto verde sobre fondo `#1A2A40`).
- Nombre editable con icono `Icons.edit` → diálogo → `BienestarRepository.actualizarNombre()`.
- Badge de nivel con `Icons.stars_rounded` verde. Barra de progreso XP: `xpTotal / (1000 × nivel)`, color `#72FE8G`.
- Mini stats rápidos: racha (🔥), días/semana (📅), minutos/sesión (⏱).

**3 pestañas con `DefaultTabController` + `NestedScrollView`:**

1. **Estadísticas** — Grid 2×2 + fila completa de tarjetas glass:
   - XP Total (verde `#72FE8G`), Sesiones (azul `#60A5FA`), Retos (dorado `#E8A838`), Calorías (naranja `#FF6B35`), Racha (violeta `#A78BFA`).
   - Valores numéricos grandes (28px, `FontWeight.w800`, `letterSpacing: -1`) con colores semánticos.
   - Tarjetas con `BorderRadius.circular(16)`, fondos semitransparentes (`alpha: 0.06`) y bordes sutiles (`alpha: 0.12`).

2. **Bienestar** — 3 secciones:
   - **Perfil físico (9 campos):** peso (30-250 kg), altura (120-230 cm), IMC (solo lectura, calculado), sexo (radio buttons), edad (1-120), objetivo principal (6 opciones en radio buttons), nivel de actividad (4 opciones), días/semana (1-7), minutos/sesión (10-180). Todos editables con diálogos individuales (numérico, selector radio, o multi-chip). Valores 0 o nulos muestran `'—'`.
   - **Equipamiento:** chips `Wrap` con `FilterChip` multi-selección de 8 opciones. Botón "Configurar equipamiento".
   - **Evolución de peso:** últimos 5 registros desde `historial_peso`.

3. **Ajustes:**
   - Notificaciones: navega a `/notificaciones` (ruta real, ya no es placeholder).
   - Visibilidad del perfil y Modo silencio: placeholders.
   - Carreras universitarias (`_CarrerasCard`): muestra count + botón gestionar.
   - Botón "Cerrar sesión" con estilo rojo (`#EF4444`).

**Arquitectura de datos:**
- DTO interno `_PerfilData`: agrupa `UsuarioDb`, `PerfilBienestarDb`, `sesiones` (COUNT), `logros` (COUNT retos completados), `caloriasAcumuladas` (SUM), `historial` (List<HistorialPesoDb>), `preferencias` (PrefsNotificacionDb).
- Tras cada edición: `_onPerfilActualizado()` invalida `perfilBienestarProvider` + `dashboardProvider` + recarga `_cargar()`.
- `_TabBarDelegate` (`SliverPersistentHeaderDelegate`) fija el `TabBar` al hacer scroll.

---

## [3.0.0] — 11-05-2026

### IA — Servicio de Recomendación con Gemini Flash (`RecomendacionIaService`)

**Arquitectura del servicio** (`app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart`, 867 líneas):
- Integración con Gemini Flash API (`gemini-flash-latest`) vía `dio` como HTTP client. No se usa SDK de Google.
- Configuración: `GEMINI_API_KEY` en `.env` → `EnvConfig.geminiApiKey`. Si no existe, métodos retornan error descriptivo sin crashear.
- Timeout: 15 segundos.

**Métodos implementados:**
1. `generarRecomendacionRutina(perfil, ejercicios, historial?, estadoDiario?)` → `RecomendacionRutinaResult`
   - Construye prompt de 7 secciones: contexto del usuario, reglas de seguridad IMC, reglas de equipamiento, historial deportivo, reglas por objetivo, periodización, formato JSON.
   - Filtra catálogo por equipamiento antes de enviar al prompt (`_ejercicioUsaEquipamiento` con mapeo de equivalencias mancuerna↔mancuernas, banda_elastica↔banda de resistencia, etc.).
   - Rellena automáticamente: nombre, descripción, objetivo, duración y estructura semana×día con ejercicios.
   - Usado desde botón "Recomendar rutina con IA" en Paso 1 de `NuevaRutinaScreen`.

2. `generarEstructuraCompleta(perfil, ejercicios, rutinaConfig, historial?, estadoDiario?)` → `RecomendacionRutinaResult`
   - Para rutinas ya configuradas por el usuario. Recibe nombre, desc, objetivo, semanas, días/semana.
   - Prompt incluye: catálogo completo como JSON, reglas de periodización detalladas por semana, reglas de programación por objetivo, datos de sobrecarga progresiva si hay historial, obligación de alternar grupos musculares.
   - Usado desde botón "Recomendar ejercicios" en Paso 1 (rellena TODA la estructura).

3. `generarRecomendacionEjercicios(perfil, ejercicios, nombreRutina, objetivo, diaNum, yaAgregados, historial?, estadoDiario?)` → `RecomendacionEjerciciosResult`
   - Añade 3-6 ejercicios a un día sin repetir los ya agregados.
   - Respuesta: array JSON (no objeto).
   - Usado desde botón "Sugerir ejercicios con IA" por cada día en Paso 2.

4. `generarProgresionEjercicio(perfil, nombreEjercicio, objetivo, historialEjercicio, rpeUltimaSesion)` → `EjercicioRecomendado?`
   - Analiza historial real (peso, reps, RPE) de sesiones previas.
   - Reglas de progresión en prompt: RPE<7 → +5-10% peso o +1-2 reps; RPE 7-8 → +2.5-5%; RPE 8.5-9.5 → mantener; RPE=10 → NO subir.
   - Modulación por objetivo: fuerza prioriza peso, ganar_masa equilibrio, perder_peso mantiene peso y sube reps.

**DTOs creados:**
- `EjercicioRecomendado`: `ejercicioId`, `series`, `repeticiones`, `segundosDescanso`, `pesoKg?`
- `RecomendacionRutinaResult`: `nombre`, `descripcion`, `objetivo`, `duracionSemanas`, `estructura` (Map<int, Map<int, List<EjercicioRecomendado>>>), `error?`
- `RecomendacionEjerciciosResult`: `ejercicios`, `error?`
- `HistorialSesionDto`: `totalSesionesCompletadas`, `rpePromedio`, `volumenSemanalEstimado`, `ejerciciosRecientes`, `diasCompletadosUltimaSemana`, `semanasConsecutivasEntrenando`, `requiereDescarga`
- `EjercicioRecienteDto`: `nombreEjercicio`, `pesoPromedio`, `repsPromedio`, `rpePromedio`, `ultimaFecha`

**Prompt Engineering — Helpers privados:**
- `_reglasSeguridadIMC(imc, edad)`: Restricciones ACSM. IMC>30→bajo impacto, IMC<18.5→evitar déficit, edad>50→fortalecimiento articular, edad<18→priorizar técnica.
- `_reglasPeriodizacion(duracionSemanas, historial)`: Adaptación→Carga→Pico→Descarga. Si `requiereDescarga`, semana 1 es descarga.
- `_reglasPorObjetivo(objetivo)`: 6 estrategias: fuerza (3-6 reps, 120-180s), hipertrofia (8-12 reps, 60-90s), resistencia (15-25 reps, 30-45s), perder_peso (15-20 reps, 45-60s, circuito), movilidad (rango completo, peso corporal), fitness_general (10-12 reps, 60-90s).
- `_formatearEstadoDiario(estado)`: Traduce fatiga a reglas IA. Fatiga>50→reducir 30%, zonas dolor→sustituir, energía≤2→movilidad, sueño≤2→evitar peso muerto/squat.
- `_formatearHistorial(historial)`: Datos de sesiones para contexto IA.
- `_formatearProgresion(historial)`: Últimos 5 ejercicios con peso/reps/RPE para sobrecarga.
- `_callGemini(apiKey, prompt)`: POST a `generativelanguage.googleapis.com`. Extrae de `candidates[0].content.parts[0].text`.
- `_extraerJson(raw)`: 3 estrategias: regex bloques ```json```, búsqueda primer `{`/`[` hasta último cierre, fallback Exception.
- `_parseError(e)`: Clasifica DioException (400/401/403→API key, otros→conexión), FormatException→JSON malformado, genérico→truncado 100 chars.

### Sistema de Check-in Diario de Fatiga

**Migración 0016** (`20260511_0016_estado_diario.sql`):
- Tabla `estado_diario_usuario`: `calidad_sueno` (1-5), `nivel_estres` (1-5), `nivel_energia` (1-5), `dolor_muscular` (1-5), `zonas_dolor` (TEXT[]), `listo_para_entrenar` (BOOLEAN), `notas` (TEXT nullable).
- UNIQUE `(usuario_id, fecha)` — un solo check-in por día.
- Índice `(usuario_id, fecha DESC)` para consulta rápida del check-in de hoy.
- RLS: solo propietario (SELECT, INSERT, UPDATE).

**Modelo `EstadoDiarioDb`** (`db_models.dart:903-972`):
- `puntuacionFatiga` (0-100): `(6-sueño)×5 + (estrés-1)×5 + (6-energía)×4 + (dolor-1)×7`
- `requiereAdaptacion`: `puntuacionFatiga > 50`
- Pesos justificados: dolor (×7, mayor impacto en rendimiento), sueño (×5, factor #1 recuperación), estrés (×5, cortisol), energía (×4, SNC).
- `listoParaEntrenar`: `calidadSueno > 1 OR nivelEnergia > 2`

**Diálogo `_CheckInDialog`** en `sesion_en_vivo_screen.dart:626-633`:
- 4 sliders con labels y emojis indicadores (1-5).
- Zonas de dolor (chips multi-select): visibles solo si `dolorMuscular >= 3`.
- 6 zonas: piernas, espalda, hombros, brazos, pecho, core.
- Botones: "Empezar" (guarda y continúa) / "Omitir" (solo continúa sin datos).
- `barrierDismissible: false` — no se cierra tocando fuera.

**Persistencia — `guardarEstadoDiario()`** (`rutina_provider.dart:840-868`):
- UPSERT en `estado_diario_usuario` con `onConflict: 'usuario_id,fecha'`.
- Invalida `estadoDiarioHoyProvider` → la UI y la IA ven los datos actualizados.

**Indicador de fatiga en UI:**
- Si `estadoDiarioHoyProvider` devuelve `requiereAdaptacion == true` → banner naranja en `RutinaDetalleScreen`:
  "⚠️ Hoy tu cuerpo necesita un entrenamiento más ligero."
- La IA recibe esta información en cada prompt y ajusta volumen/intensidad.

### Periodización Inteligente Automática

**Migración 0017** (`20260511_0017_periodizacion_tipo_semana.sql`):
- Columna `tipo_semana` en `semanas_rutina` con CHECK: `adaptacion`, `carga`, `pico`, `descarga`.
- Índice `(rutina_id, numero_semana, tipo_semana)` para consultas rápidas.

**Modelo `SemanaRutinaDb`** (`db_models.dart:1476-1522`):
- `tipoSemana` (String) con getters: `esDescarga`, `esAdaptacion`, `esPico`.

**Algoritmo `_calcularTipoSemana()`** (`rutina_provider.dart:875-881`):
- Tabla de decisión determinista: 1 semana→carga, semana 1→adaptacion, sem 3 de 3→pico, última de 4+→descarga, resto→carga.
- Se ejecuta en `crearRutinaCompleta()` al insertar cada semana.

**Detección de necesidad de descarga — `estadoPeriodizacionProvider`** (`rutina_provider.dart:886-972`):
- Analiza `sesiones_registradas` de últimas 3 semanas (RPE, duración).
- Calcula RPE promedio de todas las sesiones.
- Agrupa volumen por semana (suma de minutos).
- Detecta volumen decreciente (3 semanas consecutivas bajando).
- Cruza con check-in diario (`estado_diario_usuario` de hoy).
- `necesitaDescarga = TRUE` si: (RPE>8 + 3+ semanas + volumen decreciente) O (fatiga diaria > 50).
- DTO `PeriodizacionEstado`: `necesitaDescarga`, `rpePromedioReciente`, `volumenDecreciente`, `semanasConsecutivas`, `puntuacionFatigaDiaria`.

**Badges visuales en `RutinaDetalleScreen`:**
- Selector horizontal de semanas con chips coloreados:
  - Adaptación: azul, "Adapt" — 70% volumen, técnica
  - Carga: verde, "Carga" — 85-90% volumen, progresión
  - Pico: naranja, "Pico" — máxima intensidad
  - Descarga: teal, "Desc" — 60% volumen, recuperación

### Perfil de Usuario — Bienestar Editable

**Pestaña Bienestar en `PerfilScreen`:**
- **Sexo:** dropdown (masculino, femenino, prefiero_no_decirlo) → `actualizarPerfilParcial({'sexo': valor})`
- **Edad:** diálogo numérico (15-80 años) → `actualizarPerfilParcial({'edad': valor})`
- **Objetivo principal:** ChoiceChips (fitness_general, perder_peso, ganar_masa, fuerza, resistencia, movilidad) → `actualizarPerfilParcial({'objetivo_principal': valor})`
- **Nombre:** diálogo con TextField en header → `actualizarNombre(valor)` → UPDATE `usuarios.nombre_completo`

**Métodos en `BienestarRepository`** (`auth/infrastructure/bienestar_repository.dart:180-202`):
- `actualizarNombre(nombreCompleto)`: UPDATE `public.usuarios` SET `nombre_completo`
- `actualizarPerfilParcial(data)`: UPDATE `perfil_bienestar_usuario` SET campos parciales

### Nuevos Providers Riverpod (en `rutina_provider.dart`)

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `perfilBienestarProvider` | `FutureProvider<PerfilBienestarDb?>` | Perfil físico desde `BienestarRepository` |
| `estadoDiarioHoyProvider` | `FutureProvider<EstadoDiarioDb?>` | Check-in de hoy desde `estado_diario_usuario` WHERE fecha=today |
| `historialSesionUsuarioProvider` | `FutureProvider<HistorialSesionDto?>` | Historial 4 semanas: sesiones (30), RPE, volumen, ejercicios recientes (JOIN series_sesion→seleccion→ejercicios) |
| `estadoPeriodizacionProvider` | `FutureProvider<PeriodizacionEstado>` | Detección de descarga: RPE>8 + 3+ semanas + volumen decreciente OR fatiga>50 |
| `tiempoDiaProvider` | `FutureProvider.family<int, String>` | Duración de última sesión de un día |
| `semanasDeRutinaProvider` | `FutureProvider.family` | Semanas con tipo_semana |
| `diasDeSemanaProvider` | `FutureProvider.family` | Días de una semana con estado |
| `ejerciciosDeDiaProvider` | `FutureProvider.family` | Ejercicios de un día con series/reps/peso |

### Barra de Progreso de Rutina (`RutinaDetalleScreen`)

- **Cálculo:** días completados / días totales → barra lineal con porcentaje.
- **Tiempo acumulado:** suma de `tiempoDiaProvider` para todos los días de la rutina.
- **Bloqueo de día sin ejercicios:** botón "Iniciar" deshabilitado + SnackBar "Este día no tiene ejercicios".
- **Invalidación:** al añadir/quitar ejercicios → `ejerciciosDeDiaProvider(diaId)` invalidado. Barra de progreso se refresca automáticamente.

### Mejoras en `RutinaDetalleScreen`

- **Header enriquecido:** nombre, badge de objetivo (color), badge de estado, duración, barra de progreso %, "X/Y días", tiempo total acumulado.
- **Badge de tipo de semana** en selector horizontal (color + abreviatura).
- **Icono de check (✓)** en semanas completadas.
- **Validación pre-inicio:** día sin ejercicios → botón bloqueado + SnackBar.
- **Añadir día** a semana existente. **Sustituir ejercicio** (long-press).
- **Cards de días completados** con fondo verde y borde destacado.

### Correcciones

- Fix: `FilledButton.tonalIcon` en lugar de `.tonal.icon` en varias pantallas.
- Fix: Orden de rutas GoRouter — `/bienestar/rutina/sesion` antes de `/bienestar/rutina/:id` (evita capturar "sesion" como UUID).
- Fix: Invalidación de providers al añadir/quitar ejercicios desde detalle (día completado vuelve a pendiente).
- Fix: `const` removido de `EdgeInsets` con valores dinámicos.

### Documentación — Reescritura Profesional Completa

Se reescribieron 6 documentos del estándar de 14 puntos con nivel profesional exhaustivo:

- `02-requirements.md` (v3.0): **+5 requisitos funcionales** (RF-BIE-13 a RF-BIE-21), **+2 casos de uso** (CU-20: creación con IA, CU-21: check-in diario), **+5 reglas de negocio** (RB-21 a RB-25), **+2 requisitos de integración** (RI-11, RI-12), **+6 historias de usuario** (HU-33 a HU-38). Matriz de trazabilidad ampliada. Nuevos riesgos y mitigaciones para IA.

- `03-architecture.md` (v3.0): **Diagramas Mermaid de secuencia**: flujo completo de recomendación IA (9 pasos), flujo de check-in + sesión en vivo, flujo de periodización. Documentación exhaustiva de cada método del servicio IA con parámetros, prompt engineering, reglas de seguridad, parsing JSON. Justificación de decisión Gemini Flash vs alternativas. Justificación de IA en cliente vs Edge Function. Catálogo completo de 30+ providers Riverpod.

- `04-data-model.md` (v2.3 → se mantiene): Ya contenía documentación exhaustiva de las 27 tablas con SQL, RLS, índices y vistas materializadas. Actualizada versión y fecha.

- `06-frontend.md` (v3.0): **Catálogo completo de 30+ providers** con tipo, propósito, fuente de datos e invalidaciones. **Diagrama de flujo** para creación de rutina con IA (3 pasos). Documentación detallada de `NuevaRutinaScreen`, `RutinaDetalleScreen` (header, progreso, periodización), `LiveSessionScreen` (check-in, series, descanso, finalización), `PerfilScreen` (bienestar editable). Matriz de errores de IA y su manejo en UI. Cobertura de casos de uso v3.0.

- `07-backend.md` (v2.0): **Documentación exhaustiva del servicio IA**: arquitectura, los 4 métodos con flujos de ejecución, prompt engineering (7 secciones del prompt), helpers privados con tablas de reglas, mecanismo de parsing JSON robusto (3 estrategias), manejo de errores clasificado. **Sistema de check-in**: SQL completo, RLS, fórmula de fatiga justificada, lógica de persistencia. **Periodización**: algoritmo determinista con tabla de decisión, detección automática de descarga con pseudocódigo. **Historial de sesiones**: consultas SQL equivalentes. Historial completo de 17 migraciones.

- `14-changelog.md` (v3.0.0): **Entrada [3.0.0] reescrita** con nivel de detalle de release notes profesional: arquitectura del servicio IA, 4 métodos documentados, DTOs, prompt engineering, helpers, sistema de check-in (migración, modelo, diálogo, persistencia), periodización (migración, algoritmo, badges, detección automática), perfil editable, 8 nuevos providers, barra de progreso, correcciones, y resumen de reescritura de documentación.

---

### Sistema de rutinas periodizadas (RF-BIE-COMPLETO)
- **Migración 0015:** Tablas `semanas_rutina`, `dias_rutina`, `series_sesion`. Columnas `duracion_semanas`, `objetivo`, `estado` en `rutinas`. Columna `dia_id` y `peso_kg` en `seleccion_de_ejercicios`. Columnas `dia_id`, `tipo` en `sesiones_registradas`. RLS completa. Drop de constraints antiguos que impedían periodización.
- **Modelos nuevos:** `SemanaRutinaDb`, `DiaRutinaDb`, `SerieSesionDb`. Actualizados `RutinaDb`, `SeleccionEjercicioDb`, `SesionRegistradaDb`.
- **Providers:** `semanasDeRutinaProvider`, `diasDeSemanaProvider`, `ejerciciosDeDiaProvider`, `agregarDiaASemana()`, `crearRutinaCompleta()`, `iniciarSesion()`, `finalizarSesion()`, `registrarSerie()`, `eliminarRutina()`, `actualizarEjercicioDia()`, `agregarEjercicioADia()`, `quitarEjercicioDeDia()`. Eliminado `rutinasUsuarioProvider` duplicado de `sesion_provider.dart`.

### Pantalla de detalle de rutina (`RutinaDetalleScreen`)
- **Selector de semanas** interactivo con badge de ejercicios por semana.
- **Lista de días** por semana con estado (pendiente/en_progreso/completado). Botón "Iniciar" para comenzar sesión.
- **Edición inline de ejercicios:** series (±), repeticiones (±), descanso (±) y peso (kg, opcional). Botón "Guardar" persiste cambios.
- **Añadir ejercicio** a un día existente desde buscador de catálogo.
- **Añadir día** a una semana existente. **Sustituir ejercicio** (long-press).
- **Cards de días completados** con fondo verde, borde destacado y badge "Completado".
- **Eliminar rutina** con confirmación. Navegación: `/bienestar/rutina/:id`.

### Entrenamiento en vivo (`LiveSessionScreen`)
- **Cronómetro de sesión** automático al iniciar.
- **Check por serie** — al marcar completada, inicia automáticamente el cronómetro de descanso.
- **Descanso:** cuenta atrás con botones `+15s` / `-15s` / `Saltar`. El contador finaliza automáticamente al llegar a 0.
- **Edición inline de peso/reps** por serie durante el entreno.
- **Diálogo de finalización** con slider RPE (1-10) y selector "Solo hoy" / "Para siempre" (persistir cambios en rutina).
- **Registro por ejercicio:** tabla `series_sesion` guarda cada serie ejecutada con reps/peso real.
- **Navegación post-sesión** vuelve al detalle de la rutina para continuar con el siguiente día.
- Ruta: `/bienestar/rutina/sesion`.

### Creación de rutinas — Refactor completo (`CrearRutinaScreen`)
- **Paso 1 — Metadatos:** nombre, descripción, objetivo (ChoiceChips: fuerza/resistencia/hipertrofia/movilidad), visibilidad, semanas y días por defecto.
- **Paso 2 — Estructura:** selector de semanas con añadir/eliminar semanas. Por cada día: añadir/eliminar ejercicios del catálogo con steppers de series/reps/descanso y campo de peso (kg).
- **Añadir/eliminar semanas** dinámicamente (cada semana puede tener distinto número de días).
- **Añadir/eliminar días** por semana. **Campo de peso opcional** en cada ejercicio.
- **Steppers compactos** para evitar overflow en móviles.
- **Paso 3 — Revisión:** nombre editable, resumen de semanas/días/ejercicios, crear rutina.
- Navegación post-creación: `/bienestar/rutina/:id` (nueva rutina creada).

### Optimizaciones de rendimiento
- **IndexedStack en ShellRoute** (`StatefulShellRoute.indexedStack`) — los 5 tabs se mantienen vivos, sin re-fetch al navegar.
- **Dashboard queries paralelizadas** con `Future.wait<Object?>`. Eliminado N+1 RPC: dashboard reutiliza `retosProvider` (progreso calculado en batch).
- **Optimistic UI en toggle de tareas** — checkbox cambia instantáneamente. `toggleTareaCompletada` pasó de 2 queries a 1 (UPDATE directo, retoId desde caller).
- **`autoDispose` eliminado** de `rutinasComunidadProvider`, `rutinasUsuarioProvider`, `bloquesPorPlanProvider`, `carrerasUsuarioConNombreProvider`.
- **Compact retos cards** en dashboard: sin descripción, botón "Completar" a la izquierda, badges Simple/Complejo pre-cargados.

### Dashboard — Mejoras de UI
- **Avatar en card de bienvenida** con glow verde, muestra `NetworkImage` o inicial, clickable a `/perfil`.
- **AppBar compacta** (`hideAppBar: true`): sin espacio vacío innecesario.
- **Margen superior** usa `MediaQuery.padding.top + 8` para respetar barra de estado.
- **Retos activos** con tareas expandibles y botón "Completar" con confirmación.

### Correcciones
- Fix: orden de rutas GoRouter — `/bienestar/rutina/sesion` antes de `/bienestar/rutina/:id` (evitaba capturar "sesion" como UUID).
- Fix: constraint `UNIQUE(rutina_id, indice_orden)` dropeado para permitir periodización.
- Fix: constraint `UNIQUE(rutina_id, ejercicio_id, indice_orden)` dropeado.
- Fix: `rutinaId` pasado correctamente por route extras a `LiveSessionScreen`.
- Fix: `FilledButton.tonalIcon` en lugar de `.tonal.icon`.
- Fix: `const` removido de `EdgeInsets` con valores dinámicos en Paso 2.

### Eliminado
- `constructor_rutina_screen.dart` y `configurar_rutina_screen.dart` (reemplazados por `RutinaDetalleScreen` y nuevo flujo de creación).
- Routes obsoletas: `/bienestar/constructor-rutina`, `/bienestar/configurar-rutina`.

### Git
- Añadidas carpetas de GIFs y `Gym Workout/` a `.gitignore`. GIFs removidos del tracking (`git rm --cached`).

---

## [2.7.1] — 10-05-2026

### Sincronización de documentación
- **04-data-model.md (v2.1):** Añadidas tablas `catalogo_universidades`, `catalogo_carreras`, `catalogo_asignaturas`, `usuario_carreras`, `planes_estudio`, `apuntes` con SQL, RLS y ER. Actualizada definición de `asignaturas` con `docente`, `archivado` y `catalogo_asignatura_id`. Documentada `mv_ejercicios_completos` (vista materializada con triggers de refresco). Actualizada matriz RLS.
- **11-security.md (v1.2):** Añadidas las 6 nuevas tablas a la matriz RLS. Añadida clasificación de sensibilidad para datos del catálogo académico (públicos) y apuntes.
- **07-backend.md (v1.2):** Añadida tabla completa de las 14 migraciones. Documentada vista materializada `mv_ejercicios_completos`. Actualizada numeración de secciones.
- **03-architecture.md (v2.6):** Sincronizado ER conceptual con nombres reales de tablas (`hitos_de_reto`, `seleccion_de_ejercicios`, `sesiones_registradas`, `actividades_sociales`, `interacciones_sociales`). Añadidas tablas de catálogo académico, `usuario_carreras` y `planes_estudio`. Corregidos nombres de campos obsoletos (`nombre_mostrar` → `nombre_completo`, `propietario_id` → `usuario_id`, etc.).
- **06-frontend.md (v2.7):** Añadidas rutas faltantes (`/bienestar/explorador`, `/bienestar/ejercicio/:id`, `/bienestar/nueva-rutina`, `/bienestar/configurar-rutina`, `/plan-semanal`, `/academico/apuntes/editor`). Actualizada sección de Perfil con "Mis carreras". Actualizada ruta de bienestar principal a `RutinasComunidadScreen`.
- **14-changelog.md:** Documentada sincronización actual.

---

## [2.7.0] — 09-05-2026

### Módulo académico — Completado (RF-ACA-06/07/08)
- **Gestión de asignaturas (`gestion_asignaturas_screen.dart`):** Reescrita con búsqueda en catálogo en tiempo real, sin creación manual. Detalle con modal bottom sheet que consulta datos del catálogo (créditos, curso, semestre, carácter). Edición de campos propios. Tabs Activas/Archivadas. Highlight animado para nuevas asignaturas (fade azul 3s).
- **Configuración académica (`configuracion_academica_screen.dart`):** Selector universidad → carrera. Loading dialog con `ValueNotifier` + contador "X de Y procesadas". Persiste carrera en `usuario_carreras`. Prevención de duplicados. FAB flotante para cargar.
- **Apuntes (`apuntes_screen.dart`):** Editor Markdown con vista previa, asignación de asignatura, visibilidad, nota rápida. Fix: `GoRouterState.of(context)` movido de `initState` a `build()`.
- **Perfil:** Sección "Mis carreras" rediseñada: universidad + nombre de carrera.

### Retos — Mejoras completas
- **Barra de progreso:** Esquema intuitivo gris (0%) → azul (>0%) → naranja (≥30%) → verde (≥70%).
- **Auto-completado** al 100% con `ref.listen`. Botón "Desmarcar" para deshacer.
- **Filtro Simple/Complejo:** Badge visual verde/púrpura en cards. Filtro en las 3 pestañas.
- **Marcar desde lista:** Botón `check_circle_outline` en cada reto propio.
- **Hitos → Tareas:** Renombrado. Peso como "X% del total". Label explicativo del cálculo.
- **Fix:** Retos simples sin hito por defecto. `tieneHitos: false` filtro correcto.

### Correcciones de bugs
- Error `dependOnInheritedWidgetOfExactType` en apuntes (`initState`)
- Overflow dropdown Asignatura en apuntes (+75px) → `isExpanded: true`
- `AsyncData` sin `when` en retos → refactorizado a `AsyncValue` + callback
- Filtrado de completados que no aplicaba tipo ni búsqueda
- Overflow dropdowns en configuración académica

### Proveedores, modelos y BD
- **Nuevos providers:** `asignaturas_provider.dart`, `catalogo_provider.dart`, `apuntes_provider.dart`, `planes_estudio_provider.dart`, `usuario_carreras_provider.dart`, `bienestar_semanal_provider.dart`, `sesion_provider.dart`
- **`CatalogoCarreraDb`:** Campo `universidadNombre` del join
- **`RetoResumen`:** Campo `tieneHitos` vía batch query
- **Migraciones:** 6 nuevas desde `0008` hasta `0013` (catálogo académico, apuntes, usuario_carreras, realtime)

### Rutas nuevas
- `/academico/asignaturas`, `/academico/configuracion`, `/academico/apuntes`, `/retos/simple`, `/retos/complejo`, `/retos/:id`

---

## [2.6.1] — 05-05-2026

### Fixes y mejoras de UX
- **Fix overflow Dashboard:** Se eliminó `Flexible` del título "Crear en SynaptixFit", se añadió `SingleChildScrollView` al BottomSheet completo para evitar desbordamiento vertical en pantallas pequeñas.
- **Navegación corregida:** Cambio `context.go` → `context.push` en menú de creación del Dashboard, explorador de ejercicios y constructor de rutina. El usuario ahora puede volver atrás correctamente.
- **Menú de creación ampliado:** Añadida opción "Nuevo apunte" en el FAB del Dashboard (5 opciones). Lenguaje simplificado y directo en todas las descripciones.
- **TabController:** Añadido listener en gestión de asignaturas para refrescar al cambiar de pestaña.
- **Modelo AsignaturaDb:** Añadido campo `catalogoAsignaturaId` en constructor, fromMap, toMap y copyWith.

### Hito 6: RF-BIE-06 — Registrar sesión completada
- Provider `sesion_provider.dart` con `registrarSesion()` y providers `sesionesProvider`, `rutinasUsuarioProvider`.
- Pantalla `sesion_completada_screen.dart` reescrita: ahora usa Riverpod, añade FAB "Registrar sesión", diálogo con selector de rutina, slider de duración (5-120 min) y RPE (1-10).
- Cálculo automático de calorías: `duración × RPE × 0.8`.
- Cada sesión muestra tarjeta con nombre de rutina, duración, RPE, calorías y XP.

### Hito 7: RF-BIE-10 — Tablero semanal de bienestar
- Provider `bienestar_semanal_provider.dart` con DTO `BienestarSemanalDto`: sesiones planificadas vs completadas, cumplimiento %, tendencia, sugerencia.
- `plan_semanal_screen.dart` ahora tiene pestañas "Académico" / "Bienestar" (SegmentedButton).
- Tablero de bienestar: anillo de progreso circular, indicadores planificado/completado, tarjeta de plan activo (intensidad, duración, estado), tendencia vs semana anterior, sugerencia contextual.
- La pestaña "Académico" mantiene los planes de estudio y bloques existentes.

---

## [2.6.0] — 05-05-2026

### Implementación del módulo académico (MUST)
- **Hito 1 — RF-ACA-06: CRUD Asignaturas**
  - Migration `20260504_0009`: columnas `docente` y `archivado` en `asignaturas`.
  - Pantalla `gestion_asignaturas_screen.dart` con tabs Activas/Archivadas, crear/editar/archivar/eliminar.
  - Provider `asignaturas_provider.dart` con CRUD Supabase.
  - Ruta `/academico/asignaturas`, botón en AppBar de Plan Académico.
  - Seed script `supabase/seed_asignaturas.py` para poblar desde `grados.json`.

- **Hito 2 — RF-ACA-01/02: Catálogo académico + Planes de estudio**
  - Migration `20260504_0010`: tablas `catalogo_universidades`, `catalogo_carreras`, `catalogo_asignaturas` (catálogo público desde `grados.json`, solo lectura RLS).
  - Migration `20260504_0011`: tabla `planes_estudio` (visibilidad con RLS), columnas `plan_estudio_id` y `prioridad` en `horarios_academicos`.
  - Nuevos modelos: `PlanEstudioDb`, `CatalogoUniversidadDb`, `CatalogoCarreraDb`, `CatalogoAsignaturaDb`.
  - Providers `catalogo_provider.dart` y `planes_estudio_provider.dart`.
  - `plan_semanal_screen.dart` reescrito con planes expandibles, crear plan con selector de fechas y visibilidad, añadir/eliminar bloques con asignatura/hora/prioridad.
  - Seed script `supabase/seed_catalogo.py` (175 KB, UTF-8).

- **Hito 3 — RF-ACA-03: CRUD Apuntes Markdown**
  - Migration `20260505_0012`: tabla `apuntes` (titulo, contenido markdown, visibilidad, `es_nota_rapida`, FK opcional a `asignaturas`, RLS).
  - Dependencia `flutter_markdown: ^0.7.4` en `pubspec.yaml`.
  - Modelo `ApunteDb` con `copyWith`.
  - Pantalla `apuntes_screen.dart` con pestañas "Mis apuntes"/"Explorar", lista con cards y FAB.
  - Editor `apuntes_editor_screen.dart` con editor Markdown, toggle preview renderizado, visibilidad, vincular asignatura.
  - Rutas `/academico/apuntes`, `/academico/apuntes/editor`.

- **Hito 4 — RF-ACA-04/05: Visibilidad y control de acceso**
  - RLS completa en `planes_estudio` y `apuntes` para visibilidad público/solo_amigos/privado.
  - Provider `apuntesPublicosProvider` con join a `usuarios(nombre_completo)`, filtrado automático por RLS.
  - Explorador público de apuntes con nombre del autor.
  - Visibilidad chips en todas las cards de lista.

### Fix de encoding en seed_catalogo.py
- El script ahora escribe directamente a archivo con UTF-8 en lugar de stdout, evitando corrupción de caracteres acentuados en Windows.

### SQL consolidado para despliegue manual
- Archivo `migraciones_pendientes.sql` en raíz con las 4 migraciones nuevas para ejecutar en Supabase SQL Editor.

---

## [2.5.28] — 03-05-2026

### Realtime activado en catálogo de ejercicios
- Se habilitó Supabase Realtime en las 8 tablas del catálogo de ejercicios: `ejercicios`, `partes_cuerpo`, `musculos`, `equipamientos`, `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_parte_cuerpo` y `ejercicio_equipamiento`.
- Se actualizó [app/lib/features/bienestar/application/ejercicios_provider.dart](app/lib/features/bienestar/application/ejercicios_provider.dart) para usar `.stream()` y reflejar cambios en vivo en la UI.
- Migración: [supabase/migrations/20260501_0008_enable_realtime_ejercicios.sql](supabase/migrations/20260501_0008_enable_realtime_ejercicios.sql).

---

## [2.5.27] — 22-04-2026

### Catálogo de ejercicios poblado con terminología anatómica profesional
- Se ejecutó `supabase/seed_ejercicios.py` con los JSON traducidos al español (`synaptix_bodyParts_es.json`, `synaptix_muscles_es.json`, `synaptix_equipments_es.json`, `synaptix_exercises_es.json`).
- Los nombres de músculos, partes del cuerpo y equipamientos usan terminología anatómica profesional (ej. "Pectoral mayor" en lugar de "pecho", "Deltoides anterior" en lugar de "hombros").
- Los GIFs se referencian desde Cloudflare R2 en resolución 360x360.

---

## [2.5.26] — 22-04-2026

### Modelo normalizado de ejercicios (ExerciseDB v2)
- Se reemplazó la tabla plana `ejercicios` (con columnas `grupo_muscular TEXT`, `equipamiento TEXT` y ENUMs fijos) por un modelo 3NF completo:
	- 3 tablas de catálogo: `partes_cuerpo`, `musculos`, `equipamientos`.
	- 4 tablas de relación N:M: `ejercicio_musculo_objetivo`, `ejercicio_musculo_secundario`, `ejercicio_parte_cuerpo`, `ejercicio_equipamiento`.
	- Vista denormalizada `v_ejercicios_completos` para consultas rápidas desde el frontend.
- Campo `exercise_db_id TEXT UNIQUE` reemplaza al obsoleto `id_wger INT`.
- Campo `url_gif TEXT` unifica `url_video` y `url_imagen`.
- Campo `instrucciones TEXT[]` reemplaza `instrucciones TEXT`.
- Se eliminaron `descripcion_respaldo`, `url_video`, `url_imagen`, `id_wger`.
- Se actualizó `EjercicioDb` en [app/lib/shared/models/db_models.dart](app/lib/shared/models/db_models.dart) con propiedades derivadas (`musculoPrincipal`, `equipamientoPrincipal`, `parteCuerpoPrincipal`).
- Se añadieron modelos de catálogo en [app/lib/shared/models/catalogo_models.dart](app/lib/shared/models/catalogo_models.dart) (`ParteCuerpoDb`, `MusculoDb`, `EquipamientoDb`, `CatalogosEjercicios`).
- Migración: [supabase/migrations/20260422_0006_ejercicios_v2_normalizado.sql](supabase/migrations/20260422_0006_ejercicios_v2_normalizado.sql).

### Actualización de UI de ejercicios
- `ExploradorEjerciciosScreen` ahora filtra por catálogos N:M (parte del cuerpo, músculo, equipamiento) usando las tablas de relación.
- `DetalleEjercicioScreen` muestra chips de metadatos anatómicos (músculos objetivo, músculos secundarios, partes del cuerpo, equipamientos) y renderiza el GIF animado desde `url_gif`.
- `ExerciseCard` muestra `musculoPrincipal` y `equipamientoPrincipal` desde las propiedades derivadas del modelo.
- Se actualizó `EjerciciosRepository` para consultar `v_ejercicios_completos` y las tablas de catálogo y relación N:M.

---

## [2.5.25] — 26-04-2026

### Inicio orientado a creación
- La barra superior de inicio ahora muestra el logo en el lado izquierdo y elimina el título textual de la app.
- El botón flotante de añadir se transformó en un menú de creación con accesos directos a:
	- Nueva rutina
	- Reto simple
	- Reto complejo
	- Plan de estudio semanal
- Se mantuvo la lógica alineada con las rutas y flujos de creación ya disponibles en la aplicación.

---

## [2.5.24] — 25-04-2026

### Seguridad de repositorio
- Se agregó [.gitignore](.gitignore) en la raíz del workspace para evitar publicar archivos sensibles en GitHub.
- Se excluyeron archivos de entorno (`.env`), secretos OAuth de Google (`client_secret_*.json`, `google-services.json`, `GoogleService-Info.plist`), certificados/llaves privadas y secretos locales de Cloudflare (`.dev.vars`, `.secrets*`).

---

## [2.5.23] — 25-04-2026

### Retroceso unificado
- El botón físico de volver atrás del dispositivo ahora comparte la misma lógica de navegación que el botón de retroceso de la interfaz en las pantallas con `FeatureScaffold`.
- Se centralizó la navegación de retorno en un helper común para mantener consistencia entre la barra superior y el sistema.

---

## [2.5.22] — 25-04-2026

### Acceso inteligente y cierre de sesión
- La pantalla de presentación y la pantalla de acceso ahora detectan una sesión activa y redirigen automáticamente a onboarding o dashboard según corresponda.
- Se conectó el botón de cerrar sesión en el perfil para ejecutar el `logout` real y volver a la pantalla de acceso.
- El controlador de autenticación ahora limpia su estado local al cerrar sesión para evitar estados obsoletos en navegación posterior.

---

## [2.5.21] — 25-04-2026

### Retorno consistente en pantallas secundarias
- Se añadió un destino de retorno explícito en el scaffold compartido para pantallas que se abren con rutas directas sin historial de navegación.
- Se habilitó botón de volver atrás en:
	- [app/lib/features/bienestar/presentation/explorador_ejercicios_screen.dart](app/lib/features/bienestar/presentation/explorador_ejercicios_screen.dart)
	- [app/lib/features/bienestar/presentation/detalle_ejercicio_screen.dart](app/lib/features/bienestar/presentation/detalle_ejercicio_screen.dart)
	- [app/lib/features/bienestar/presentation/sesion_completada_screen.dart](app/lib/features/bienestar/presentation/sesion_completada_screen.dart)
	- [app/lib/features/bienestar/presentation/constructor_rutina_screen.dart](app/lib/features/bienestar/presentation/constructor_rutina_screen.dart)
	- [app/lib/features/retos/presentation/detalle_reto_screen.dart](app/lib/features/retos/presentation/detalle_reto_screen.dart)
	- [app/lib/features/retos/presentation/crear_reto_simple_screen.dart](app/lib/features/retos/presentation/crear_reto_simple_screen.dart)
	- [app/lib/features/retos/presentation/crear_reto_complejo_screen.dart](app/lib/features/retos/presentation/crear_reto_complejo_screen.dart)
	- [app/lib/features/academico/presentation/plan_semanal_screen.dart](app/lib/features/academico/presentation/plan_semanal_screen.dart)
	- [app/lib/features/notificaciones/presentation/notificaciones_screen.dart](app/lib/features/notificaciones/presentation/notificaciones_screen.dart)
- Se reforzó el `FeatureScaffold` y el `SynaptixFitAppBar` para soportar retornos explícitos cuando el `context.canPop()` no está disponible.

---

## [2.5.20] — 25-04-2026

### R2 público alineado
- Se actualizó la URL pública de Cloudflare R2 a `https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev` en [app/.env](app/.env), y se alineó el valor por defecto del seed de ejercicios en [supabase/seed_ejercicios.py](supabase/seed_ejercicios.py).
- Se documentó la misma URL pública en [docs/08-installation.md](docs/08-installation.md) para mantener consistencia entre entorno local, scripts y documentación.

---

## [2.5.19] — 25-04-2026

### Barra inferior centrada con avatar y dashboard sin título genérico
- Se movió la pestaña de perfil al centro de la navegación inferior y ahora muestra el avatar del usuario cuando existe `url_avatar`, con fallback a la inicial del nombre en [app/lib/shared/widgets/bottom_nav_bar.dart](app/lib/shared/widgets/bottom_nav_bar.dart).
- Se reordenó el shell de rutas para mantener la navegación coherente con la nueva posición central del perfil en [app/lib/core/routing/shell_route.dart](app/lib/core/routing/shell_route.dart).
- Se reemplazó el título `Dashboard` por `SynaptixFit` en [app/lib/features/dashboard/presentation/dashboard_screen.dart](app/lib/features/dashboard/presentation/dashboard_screen.dart).

### Seed demo enriquecido en Supabase
- Se añadió [supabase/seed_demo_data.py](supabase/seed_demo_data.py) para poblar usuarios, perfil de bienestar, asignaturas, horarios, sesiones, retos, hitos, actividades sociales, interacciones y notificaciones con datos de demo reales.
- Se reforzó el guardado de avatar en [app/lib/features/auth/infrastructure/bienestar_repository.dart](app/lib/features/auth/infrastructure/bienestar_repository.dart) para aceptar `avatar_url` o `picture` desde metadata.

---

## [2.5.18] — 25-04-2026

### Fix crítico en Dashboard y módulos relacionados (Supabase)
- Se corrigieron referencias erróneas a la tabla `sesion_registrada` en:
	- [app/lib/features/dashboard/application/dashboard_provider.dart](app/lib/features/dashboard/application/dashboard_provider.dart)
	- [app/lib/features/academico/presentation/plan_semanal_screen.dart](app/lib/features/academico/presentation/plan_semanal_screen.dart)
	- [app/lib/features/bienestar/presentation/sesion_completada_screen.dart](app/lib/features/bienestar/presentation/sesion_completada_screen.dart)
	- [app/lib/features/perfil/presentation/perfil_screen.dart](app/lib/features/perfil/presentation/perfil_screen.dart)
- Se alineó el consumo de hitos de retos con el esquema real, cambiando `hitos_reto` por `hitos_de_reto` en [app/lib/features/retos/application/retos_provider.dart](app/lib/features/retos/application/retos_provider.dart).

### Implementación funcional de creación de retos
- Se reemplazó la creación mock de reto simple por flujo real con:
	- Validación de formulario.
	- Selección de tipo, visibilidad y fechas.
	- Persistencia en Supabase (`retos` + hito inicial en `hitos_de_reto`).
	- Redirección automática al detalle del reto creado.
	- Archivo: [app/lib/features/retos/presentation/crear_reto_simple_screen.dart](app/lib/features/retos/presentation/crear_reto_simple_screen.dart).
- Se reemplazó la creación mock de reto complejo por flujo real con:
	- Gestión dinámica de hitos (crear/eliminar).
	- Validación de pesos (suma exacta 100%).
	- Persistencia en Supabase (`retos` + inserción por lote en `hitos_de_reto`).
	- Redirección automática al detalle del reto creado.
	- Archivo: [app/lib/features/retos/presentation/crear_reto_complejo_screen.dart](app/lib/features/retos/presentation/crear_reto_complejo_screen.dart).

---

## [2.5.17] — 21-04-2026

### Salidas esperadas de traducir.py y evidencias de ejecucion
- Se actualizo [docs/08-installation.md](docs/08-installation.md) para especificar `ARCHIVO_SALIDA` esperado al ejecutar `traducir.py` con `muscles.json`, `equipments.json` y `bodyParts.json`.
- Se actualizaron [docs/08-installation.md](docs/08-installation.md) y [docs/13-maintenance.md](docs/13-maintenance.md) incorporando capturas de ejecucion:
	- `traducir_ejercicios.png`
	- `traducir_musculos.png`
	- `traducir_equipamientos.png`
	- `traducir_partesCuerpo.png`

---

## [2.5.16] — 21-04-2026

### Pipeline de traduccion ExerciseDB documentado
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) para reflejar la traduccion al espanol como parte vigente del seeding del dataset.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) incorporando la fase de traduccion en el pipeline Kaggle -> Supabase + R2.
- Se actualizo [docs/08-installation.md](docs/08-installation.md) con el procedimiento real ejecutado usando [exercisedb/traducir_ejercicios.py](exercisedb/traducir_ejercicios.py) y [exercisedb/traducir.py](exercisedb/traducir.py).
- Se actualizo [docs/13-maintenance.md](docs/13-maintenance.md) con trazabilidad operacional de traduccion para `exercises.json`, `muscles.json`, `equipments.json` y `bodyParts.json`.

---

## [2.5.15] — 21-04-2026

### Adopcion definitiva de ExerciseDB (AscendAPI) via Kaggle
- Se actualizo [docs/01-introduction.md](docs/01-introduction.md) para reflejar ExerciseDB como fuente aprobada del catalogo de ejercicios.
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) con la decision final de proveedor y la ruta oficial de obtencion del dataset en Kaggle.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) para pasar de estado de evaluacion a pipeline activo ExerciseDB -> Supabase + R2.
- Se actualizaron [docs/04-data-model.md](docs/04-data-model.md), [docs/07-backend.md](docs/07-backend.md), [docs/08-installation.md](docs/08-installation.md) y [docs/09-testing.md](docs/09-testing.md) para alinear funciones, variables y criterios con ExerciseDB.
- Se reescribio [docs/13-maintenance.md](docs/13-maintenance.md) incorporando evidencia visual en `app/assets/images/documentacion/exercisesdb/` sobre GitHub shell, descarga Kaggle y estructura del dataset.

---

## [2.5.14] — 21-04-2026

### Decision tecnica documentada: proveedor de ejercicios en evaluacion
- Se actualizo [docs/01-introduction.md](docs/01-introduction.md) para reflejar que el catalogo de ejercicios usa infraestructura propia (Supabase + R2) con proveedor externo pendiente de aprobacion.
- Se actualizo [docs/02-requirements.md](docs/02-requirements.md) con el descarte temporal de wger (Docker y API REST) y la condicion de ExerciseDB como candidato de evaluacion futura.
- Se actualizo [docs/03-architecture.md](docs/03-architecture.md) para eliminar la suposicion de wger como fuente adoptada y dejar el pipeline de ingesta en estado suspendido hasta nueva decision.
- Se actualizaron [docs/04-data-model.md](docs/04-data-model.md), [docs/06-frontend.md](docs/06-frontend.md), [docs/07-backend.md](docs/07-backend.md), [docs/08-installation.md](docs/08-installation.md) y [docs/09-testing.md](docs/09-testing.md) para desacoplar referencias de operacion activa en wger.
- Se reescribio [docs/13-maintenance.md](docs/13-maintenance.md) con evidencia visual del intento Docker/REST en la carpeta `app/assets/images/documentacion/wger/` y criterios formales para aprobar el siguiente proveedor.

---

## [2.5.13] — 21-04-2026

### Capa académica extendida para personalización
- Se actualizó [docs/04-data-model.md](docs/04-data-model.md) con:
	- Extensión de `asignaturas` (`dificultad_percibida`, `creditos`, `prioridad`, `proxima_evaluacion`).
	- Nueva tabla `perfil_academico_usuario` para contexto académico base.
	- Nueva tabla `carga_academica_semanal` para señales semanales de carga y estrés.
- Se actualizó [docs/11-security.md](docs/11-security.md) incorporando las nuevas tablas en la matriz RLS y la clasificación de sensibilidad para datos académicos.
- Se preparó la implementación SQL con RLS y permisos desde el inicio para prevenir errores de acceso en PostgREST.

---

## [2.5.12] — 21-04-2026

### Fix de permisos Supabase tras reset de esquema
- Se corrigió el error `PostgrestException 42501 (permission denied)` al guardar el perfil de bienestar.
- Se agregó la migración [supabase/migrations/20260421_0003_restore_table_grants_after_schema_reset.sql](supabase/migrations/20260421_0003_restore_table_grants_after_schema_reset.sql) para restaurar permisos de tablas y secuencias para roles `anon`, `authenticated` y `service_role`.
- Se reforzó [supabase/sql/schema.sql](supabase/sql/schema.sql) con `GRANT` y `ALTER DEFAULT PRIVILEGES` para evitar que el problema reaparezca después de `DROP SCHEMA public CASCADE`.
- Se añadió [supabase/migrations/20260421_0004_backfill_usuarios_and_restore_auth_trigger.sql](supabase/migrations/20260421_0004_backfill_usuarios_and_restore_auth_trigger.sql) para reponer el trigger `auth.users -> public.usuarios` y backfillear usuarios faltantes, corrigiendo el error `23503` de FK en `perfil_bienestar_usuario`.
- Se blindó [app/lib/features/auth/infrastructure/bienestar_repository.dart](app/lib/features/auth/infrastructure/bienestar_repository.dart) para asegurar automáticamente la fila en `public.usuarios` antes de guardar o actualizar datos de bienestar.

---

## [2.5.11] — 19-04-2026

### Perfil físico (IA y UX de campos)
- Se cambió `Nivel de actividad` a desplegable en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart).
- Se integraron sugerencias de IA para `Objetivo principal` usando Gemini en:
	- [app/lib/features/auth/infrastructure/objetivo_ia_service.dart](app/lib/features/auth/infrastructure/objetivo_ia_service.dart)
	- [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart)
- Se añadió soporte de variable de entorno `GEMINI_API_KEY` en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart).
- Se mejoró la visualización de labels flotantes y bordes de campos para evitar pérdida de legibilidad al enfocar inputs en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart).
- Se corrigió overflow horizontal del bloque de sugerencias/acciones en pantallas estrechas con layout adaptable.
- Se añadió opción `Ocultar sugerencias` / `Mostrar sugerencias` para permitir edición manual del objetivo principal tras generar recomendaciones.
- Se implementó cálculo dinámico de IMC al introducir `Peso` y `Altura` con actualización en tiempo real.
- Se ajustó el layout general para evitar cortes de scroll en la etapa de sugerencias (contenedor expandible + Stepper con scroll interno).
- Se reforzó la apariencia de botones accionables en sugerencias IA con estilos `FilledButton` y `OutlinedButton`.

---

## [2.5.10] — 19-04-2026

### Perfil físico y progreso de pasos
- Se transformo el campo `Sexo` en un desplegable en [app/lib/features/auth/presentation/perfil_fisico_screen.dart](app/lib/features/auth/presentation/perfil_fisico_screen.dart) para evitar entradas ambiguas.
- Se modernizo el flujo del Stepper con un indicador superior de progreso, estados completado/activo y transiciones visuales suaves.
- Se habilito la navegacion real hacia atras tocando un paso anterior en el Stepper, sin boton adicional.
- Se preservan los campos al regresar a pasos previos mediante controladores dedicados.

---

## [2.5.9] — 19-04-2026

### Autenticacion Google nativa en mobile
- Se reemplazo el flujo OAuth por navegador en mobile por Google Sign-In nativo en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart), evitando redireccion a localhost.
- Se integra `google_sign_in` + `signInWithIdToken` de Supabase para Android/iOS.
- Se agregaron variables de entorno para configuracion de cliente Google en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart):
	- `GOOGLE_WEB_CLIENT_ID` (requerido para mobile)
	- `GOOGLE_IOS_CLIENT_ID` (opcional para iOS)
- Se mejoro el manejo de errores de Google Sign-In en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart) para mostrar diagnosticos accionables (DEVELOPER_ERROR/SHA-1, cliente OAuth, red, cancelacion).
- Se añadio el scope `openid` al flujo de Google Sign-In para que coincida con los permisos del consentimiento OAuth.
- Se fuerza el reinicio de la sesion local de Google Sign-In antes de mostrar el selector de cuenta, para evitar reutilizar el correo anterior.
- La pantalla de acceso deja de autoredirigir por una sesion previa en Supabase para que el formulario siga visible al entrar a la app.

---

## [2.5.8] — 19-04-2026

### Autenticacion y pantalla de acceso
- Se agrego el logo oficial de la app en [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart) con `Hero` y fallback visual.
- Se implemento boton profesional **Continuar con Google** en [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart).
- Se conecto la autenticacion real con Supabase en [app/lib/features/auth/infrastructure/auth_repository.dart](app/lib/features/auth/infrastructure/auth_repository.dart):
	- Login con email y contrasena (`signInWithPassword`).
	- Registro con email y contrasena (`signUp`).
	- Inicio con Google OAuth (`signInWithOAuth`).
	- Cierre de sesion real (`signOut`).
- Se amplio el estado de autenticacion en [app/lib/features/auth/presentation/auth_controller.dart](app/lib/features/auth/presentation/auth_controller.dart) para manejar `autenticado`, `loginConGoogle` y `sincronizarSesionActiva`.
- La pantalla de acceso ahora escucha cambios de sesion OAuth y sincroniza correctamente la navegacion post-login.

---

## [2.5.7] — 19-04-2026

### Convencion de nombres de pantallas
- Se ajusto la convención de nombres para vistas Flutter al formato `*_screen.dart`.
- Se renombraron los archivos:
	- `pantalla_presentacion.dart` -> [app/lib/features/splash/presentation/presentacion_screen.dart](app/lib/features/splash/presentation/presentacion_screen.dart)
	- `pantalla_acceso.dart` -> [app/lib/features/auth/presentation/acceso_screen.dart](app/lib/features/auth/presentation/acceso_screen.dart)
- Se actualizaron las clases a sufijo `Screen`:
	- `PantallaPresentacion` -> `PresentacionScreen`
	- `PantallaAcceso` -> `AccesoScreen`
- Se actualizaron imports y referencias en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart).

---

## [2.5.6] — 19-04-2026

### UI/UX Flutter (presentacion y acceso)
- Se renombro la pantalla de autenticacion a [app/lib/features/auth/presentation/pantalla_acceso.dart](app/lib/features/auth/presentation/pantalla_acceso.dart) con clase `PantallaAcceso` para mantener nomenclatura clara en espanol.
- Se renombro la pantalla de onboarding a [app/lib/features/splash/presentation/pantalla_presentacion.dart](app/lib/features/splash/presentation/pantalla_presentacion.dart) con clase `PantallaPresentacion`.
- Se modernizo la interfaz de acceso con composicion visual premium (gradientes, glass-card, microanimaciones y grafico generado por codigo).
- Se mejoro la presentacion inicial con estilo visual mas inmersivo y arte generativo nativo en Flutter (sin imagenes estaticas externas).
- Se actualizaron rutas en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart) y [app/lib/features/splash/presentation/splash_screen.dart](app/lib/features/splash/presentation/splash_screen.dart): `/` ahora abre la presentacion y la navegacion de entrada usa `/acceso`.
- Se eliminaron los archivos obsoletos `bienvenida_screen.dart` y `presentacion_screen.dart`.

---

## [2.5.5] — 19-04-2026

### Base de datos Supabase (SQL inicial)
- Se creo la carpeta [supabase/](supabase/) para centralizar scripts SQL y migraciones.
- Se agrego la migracion inicial [supabase/migrations/20260419_0001_init_schema.sql](supabase/migrations/20260419_0001_init_schema.sql) con tablas, indices, funciones y politicas RLS.
- Se agrego [supabase/sql/schema.sql](supabase/sql/schema.sql) listo para copiar y pegar en Supabase SQL Editor.
- Se agrego [supabase/README.md](supabase/README.md) con estructura y uso rapido.

---

## [2.5.4] — 19-04-2026

### Documentación SHA-1 Android (validada)
- Se añadió en [docs/08-installation.md](08-installation.md) el procedimiento verificado para obtener SHA-1 en Windows con `gradlew signingReport`.
- Se agregaron comandos alternativos con `keytool` para casos donde Gradle falle.
- Se incluyeron referencias de capturas pendientes para documentar visualmente: ejecución de comando, salida SHA1 y formulario OAuth Android.

---

## [2.5.3] — 19-04-2026

### Documentación de autenticación Android
- Se añadió en [docs/08-installation.md](08-installation.md) la aclaración de cuándo es obligatorio o recomendable crear un OAuth Client de tipo Android.
- Se documentó un paso a paso completo para crear el cliente Android (tipo de aplicación, package name y huella SHA-1) y registrarlo en Supabase junto al cliente web.
- Se mejoró el formato de la sección de configuración de Google Provider en Supabase para mayor legibilidad.

---

## [2.5.2] — 19-04-2026

### Documentación de autenticación (Google + Supabase)
- Se añadió una guía visual profesional en [docs/08-installation.md](08-installation.md) con capturas reales del flujo completo de Google Auth Platform y Supabase.
- Se actualizaron los pasos para reflejar la interfaz en español de Google Cloud: **Descripción general**, **Público**, **Acceso a los datos** y **Clientes**.
- Se incorporaron opciones avanzadas no documentadas previamente en Supabase Provider de Google: **Skip nonce checks** y **Allow users without an email**.
- Se corrigió y normalizó la estructura Markdown de [docs/08-installation.md](08-installation.md) para evitar bloques mal cerrados.

---

## [2.5.1] — 19-04-2026

### Implementación Flutter (MVP inicial)
- Se inicializó el bootstrap real de la app con `Riverpod` + `GoRouter` en [app/lib/main.dart](app/lib/main.dart).
- Se añadió configuración base de entorno/Supabase en [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart) y [app/lib/core/config/supabase_config.dart](app/lib/core/config/supabase_config.dart).
- Se implementó routing completo (incluyendo `ShellRoute` con navegación inferior) en [app/lib/core/routing/app_router.dart](app/lib/core/routing/app_router.dart) y [app/lib/core/routing/shell_route.dart](app/lib/core/routing/shell_route.dart).
- Se añadieron widgets compartidos del MVP en [app/lib/shared/widgets](app/lib/shared/widgets).
- Se crearon pantallas base (mock) para las 15 vistas del MVP en `features/auth`, `features/dashboard`, `features/bienestar`, `features/retos`, `features/academico`, `features/notificaciones`, `features/social` y `features/perfil`.
- Se añadieron providers iniciales de estado en `features/auth`, `features/dashboard`, `features/bienestar` y `features/retos`.

### Calidad y verificación
- Se corrigieron errores de compilación y lints deprecados detectados por `flutter analyze`.
- Se actualizó el test base en [app/test/widget_test.dart](app/test/widget_test.dart).
- Estado final de validación: `flutter analyze` sin issues y `flutter test` con pruebas en verde.

---

## [2.5.0] — 19-04-2026

### Documentación
- **Reestructuración completa:** Migración de 6 archivos con nombres arbitrarios al estándar de 14 puntos del equipo jloen.
- Se crearon los archivos faltantes: `01-introduction.md`, `05-api.md`, `06-frontend.md`, `07-backend.md`, `08-installation.md`, `09-testing.md`, `10-deployment.md`, `11-security.md`, `12-user-guide.md`, `13-maintenance.md`, `14-changelog.md`.
- Se renombraron: `03-architecture-rfc.md` → `03-architecture.md`, `06-database-schema.md` → `04-data-model.md`.
- Se eliminaron archivos obsoletos: `01-project-documentation-index.md`, `04-design-phase.md`, `05-screen-specifications.md`.

### Requisitos (SRS v2.5)
- 19 casos de uso completos (CU-01 a CU-19) con flujos principales, alternativos y de excepción.
- Módulo académico expandido: asignaturas, evaluaciones, calificaciones, notas rápidas.
- Módulo de bienestar expandido: perfil físico, recomendación semanal de entrenamiento, catálogo de ejercicios.
- 20 reglas de negocio formalizadas.
- Matriz de trazabilidad requisitos → diseño → código.

### Arquitectura (RFC v2.5)
- Stack definido: Flutter + Supabase + Cloudflare R2.
- Estructura de carpetas Clean Architecture por features.
- 9 repositorios de dominio con contratos completos.
- 6 canales Realtime definidos.
- Pipeline de ingesta wger documentado paso a paso.

### Diseño (v2.0)
- 15 pantallas funcionales generadas en Stitch (todas en español es-ES).
- Design System Synapse Velocity aplicado con tokens de color, tipografía y espaciado.
- Flujos UX detallados con diagramas Mermaid.
- Cobertura 100% de los 14 casos de uso MVP.

### Modelo de Datos (v1.0)
- 13 tablas principales con constraints y validaciones SQL.
- Políticas RLS completas por tabla.
- 3 stored procedures: detección de conflictos, cálculo de progreso, sistema XP.
- Índices de performance para queries críticos.

---

## [1.0.0] — 16-04-2026

### Inicio del proyecto
- Definición inicial de la idea: app de bienestar para estudiantes.
- Investigación de competencia (StudySmarter, Habitica, Duolingo).
- Análisis de viabilidad técnica (Flutter, Supabase, wger).
- Primera versión del SRS con requisitos base.

---

**Mantenido por:** Equipo jloen  
**Convención de commit:** `feat:`, `fix:`, `docs:`, `refactor:`
