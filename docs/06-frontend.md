# 06 - Frontend (Estructura UI, Componentes y Pantallas)

**Proyecto:** SynaptixFit
**Versión:** 7.2
**Fecha:** 27-06-2026
**Referencia:** [03-architecture.md](03-architecture.md), [02-requirements.md](02-requirements.md), [15-ia-recomendacion-sistema.md](15-ia-recomendacion-sistema.md), [04-data-model.md](04-data-model.md)

---

## 1. Arquitectura de Información (MVP v3.0)

```mermaid
flowchart LR
    Home["Inicio<br/>Dashboard"] --> Academic["Académico<br/>Plan Semanal"]
    Home --> Wellness["Rutinas<br/>Bienestar/IA/Ejercicios"]
    Home --> Challenges["Retos<br/>Crear/Listar"]
    Home --> Social["Social<br/>Muro de Logros"]

    Wellness --> RoutineList["Mis Rutinas<br/>+ Comunidad"]
    RoutineList --> NewRoutine["Nueva Rutina<br/>3 pasos + IA"]
    RoutineList --> RoutineDetail["Detalle Rutina<br/>Semanas/Días/Ejercicios"]
    RoutineDetail --> LiveSession["Sesión en Vivo<br/>Cronómetro + Series"]
    LiveSession --> CheckIn["Check-in Diario<br/>Fatiga + Adaptación"]
    Wellness --> ExerciseExplorer["Explorador<br/>Ejercicios"]
    ExerciseExplorer --> ExerciseDetail["Detalle<br/>Ejercicio"]
```

## 2. Navegación (GoRouter — ShellRoute)

**Diseño:** Bottom Navigation Bar con 5 tabs, glassmorphism (80% opacidad + 20px backdrop blur). Tab activo con color verde secundario y punto indicador de 4px. Avatar del usuario en el tab central de Perfil.

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/dashboard` | `DashboardScreen` | Inicio con KPIs, retos activos, acceso rápido |
| `/academico` | `PlanAcademicoScreen` | Plan académico semanal con horarios |
| `/academico/planificar` | `CanvasScreen` | Lienzo Time-Blocking (grid 7×16h, DnD libre, asistente IA) |
| `/academico/planificar/inbox` | `InboxScreen` | Configuración de carga académica semanal (legacy) |
| `/academico/configuracion` | `ConfiguracionAcademicaScreen` | Selección universidad/carrera + carga masiva |
| `/academico/apuntes` | `ApuntesScreen` | Editor Markdown + explorador |
| `/academico/apuntes/editor` | `ApuntesEditorScreen` | Editor Markdown a pantalla completa |
| `/retos` | `RetosScreen` | Retos activos/explorar/completados |
| `/retos/simple` | `CrearRetoSimpleScreen` | Crear reto simple |
| `/retos/complejo` | `CrearRetoComplejoScreen` | Crear reto con hitos |
| `/retos/:id` | `DetalleRetoScreen` | Detalle y progreso |
| `/bienestar` | `RutinasComunidadScreen` | Comunidad y mis rutinas |
| `/bienestar/nueva-rutina` | `NuevaRutinaScreen` | **Crear rutina con IA (3 pasos)** |
| `/bienestar/explorador` | `ExploradorEjerciciosScreen` | Catálogo de ejercicios (~1300) |
| `/bienestar/ejercicio/:id` | `DetalleEjercicioScreen` | Detalle de ejercicio. Soporta `extra: true` para ocultar botón "Agregar a rutina" (usado desde editor de rutina `_EjercicioCompacto`) |
| `/bienestar/rutina/:id` | `RutinaDetalleScreen` | **Gestión: semanas, días, ejercicios, progreso, periodización** |
| `/bienestar/rutina/sesion` | `LiveSessionScreen` | **Entrenamiento en vivo + check-in diario** |
| `/bienestar/sesion-completada` | `SesionCompletadaScreen` | Historial de sesiones |
| `/perfil` | `PerfilScreen` | Perfil + bienestar editable + carreras + ajustes |
| `/notificaciones` | `NotificacionesScreen` | Centro de notificaciones |

**Nota importante:** La ruta `/bienestar/rutina/sesion` debe estar definida ANTES de `/bienestar/rutina/:id` en GoRouter para evitar que "sesion" sea capturado como parámetro `:id`.

### 2.0 Localización (i18n / l10n)

SynaptixFit soporta español (predeterminado) e inglés mediante `flutter_localizations`:

| Archivo | Configuración |
|---------|--------------|
| `pubspec.yaml` | `flutter_localizations: sdk: flutter` |
| `main.dart` | `MaterialApp.router(locale: Locale('es','ES'), localizationsDelegates: [GlobalMaterialLocalizations, GlobalWidgetsLocalizations, GlobalCupertinoLocalizations], supportedLocales: [es_ES, es, en])` |
| `canvas_screen.dart` | `DateFormat('d MMM', 'es')` — banner de fechas en español |

**Causa raíz documentada:** Antes solo estaba `initializeDateFormatting('es')` + `locale`, pero sin `localizationsDelegates` los widgets Material (`showDatePicker`, `showTimePicker`) caían a inglés. Con los delegates, **todos** los `showDatePicker` de la app salen en español.

### 2.1 Flujo "Agregar a Rutina" desde Detalle de Ejercicio

La pantalla de detalle de ejercicio (`DetalleEjercicioScreen`) implementa un flujo de navegación bidireccional con retorno de datos que permite agregar ejercicios a una selección desde la vista de detalle:

```mermaid
flowchart TD
    A["SeleccionEjerciciosScreen\n(Cuadrícula de selección)"] -->|"Tap en ejercicio"| B["_verDetalle()"]
    B --> C["Navigator.push<EjercicioDb>\nMaterialPageRoute → DetalleEjercicioScreen"]
    C --> D{"¿showAddButton?\n(controlado por extra)"}

    D -->|"true (default)\nNavegado desde cuadrícula"| E["Muestra botón\n'Agregar a rutina'"]
    D -->|"false (extra: true)\nNavegado desde _EjercicioCompacto"| F["Oculta botón\n(el ejercicio ya está añadido)"]

    E --> G{"¿Usuario pulsa\n'Agregar a rutina'?"}
    G -->|Sí| H["Navigator.pop(context, ejercicio)\nRetorna el EjercicioDb completo"]
    G -->|No| I["Vuelve sin selección"]

    H --> J["_verDetalle() recibe el resultado\ny lo añade a la selección automáticamente"]

    F --> K["Solo vista de detalle\nsin acción de agregar"]
```

**Parámetro `showAddButton`:**

| Archivo | Línea | Descripción |
|---------|-------|-------------|
| `detalle_ejercicio_screen.dart` | Constructor | `final bool showAddButton` (default `true`). Controla la visibilidad del botón "Agregar a rutina". |
| `app_router.dart` | Ruta `/bienestar/ejercicio/:id` | Acepta `extra: true` para establecer `showAddButton: false`. |
| `seleccion_ejercicios_screen.dart` | `_verDetalle()` | Usa `await Navigator.of(context).push<EjercicioDb>(MaterialPageRoute(...))`. Al recibir el `EjercicioDb` de vuelta, lo añade a la selección. |
| `nueva_rutina_screen.dart` | `_EjercicioCompacto` | Navega con `extra: true` para ocultar "Agregar a rutina" (el ejercicio ya está en la rutina). |

**Comportamiento contextual:**
- **Desde la cuadrícula de selección:** `showAddButton = true` (default). El botón "Agregar a rutina" está visible y al pulsarlo retorna el ejercicio seleccionado mediante `Navigator.pop`.
- **Desde el editor de rutina (`_EjercicioCompacto`):** `showAddButton = false` (vía `extra: true`). El botón se oculta porque el ejercicio ya forma parte de la rutina. El usuario solo puede ver los detalles del ejercicio.

## 3. Gestión de Estado (Riverpod) — Catálogo Completo

### 3.1 Estrategia General

| Provider Type | Uso | Ciclo de vida |
|--------------|-----|---------------|
| `FutureProvider` | Datos que se cargan una vez con refresh manual | Persiste mientras el provider tenga listeners |
| `FutureProvider.family` | Detalle de entidades por ID | Cacheado por parámetro |
| `StreamProvider` | Datos en tiempo real (Supabase Realtime) | Suscripción WebSocket activa mientras haya listeners |
| `StateNotifierProvider` | Estados con lógica de cambio compleja | Persiste en memoria |
| `FutureProvider.autoDispose` | Datos de pantallas que no necesitan persistencia | Se destruye al salir de la pantalla |

**Decisión de `autoDispose`:** Los providers de rutinas, comunidad, bloques y carreras NO usan `autoDispose` porque se consultan desde múltiples pantallas y mantenerlos en memoria evita re-fetching costoso al navegar entre tabs (gracias al `IndexedStack` del `StatefulShellRoute`).

### 3.2 Proveedores del Módulo de Bienestar (IA + Periodización)

| Provider | Tipo | Propósito | Fuente Supabase |
|----------|------|-----------|-----------------|
| `perfilBienestarProvider` | `FutureProvider<PerfilBienestarDb?>` | Perfil físico: antropometría, objetivo, equipamiento, disponibilidad | `perfil_bienestar_usuario` → `BienestarRepository.obtenerPerfilBienestar()` |
| `estadoDiarioHoyProvider` | `FutureProvider<EstadoDiarioDb?>` | Check-in diario de hoy (o null si no se ha hecho) | `estado_diario_usuario` WHERE `usuario_id` AND `fecha = today` |
| `historialSesionUsuarioProvider` | `FutureProvider<HistorialSesionDto?>` | Historial agregado de 4 semanas: RPE promedio, volumen, ejercicios recientes, semanas consecutivas | `sesiones_registradas` (30 últimas) + `series_sesion` (JOIN con `seleccion_de_ejercicios` → `ejercicios`) |
| `estadoPeriodizacionProvider` | `FutureProvider<PeriodizacionEstado>` | Detección de necesidad de descarga: RPE>8 + 3+ semanas + volumen decreciente O fatiga>50 | `sesiones_registradas` (3 semanas) + `estado_diario_usuario` (hoy) |
| `semanasDeRutinaProvider` | `FutureProvider.family<List<SemanaRutinaDb>, String>` | Semanas de una rutina con `tipo_semana` | `semanas_rutina` WHERE `rutina_id` |
| `diasDeSemanaProvider` | `FutureProvider.family<List<DiaRutinaDb>, String>` | Días de entrenamiento de una semana | `dias_rutina` WHERE `semana_id` |
| `ejerciciosDeDiaProvider` | `FutureProvider.family<List<SeleccionEjercicioDb>, String>` | Ejercicios de un día con series/reps/peso | `seleccion_de_ejercicios` WHERE `dia_id` |
| `tiempoDiaProvider` | `FutureProvider.family<int, String>` | Duración registrada de un día (última sesión) | `sesiones_registradas` WHERE `dia_id` (última) |
| `rutinasUsuarioProvider` | `FutureProvider<List<RutinaDb>>` | Rutinas del usuario autenticado | `rutinas` WHERE `usuario_id` |
| `rutinasComunidadProvider` | `FutureProvider<List<RutinaComunidadDto>>` | Rutinas públicas de la comunidad con nombre del autor | `rutinas` WHERE `visibilidad='public'` JOIN `usuarios` |

### 3.2.1 Proveedores del Motor de Recomendaciones (Fases 0-10)

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `geminiApiKeyProvider` | `Provider<String>` | Lee `GEMINI_API_KEY` de `EnvConfig`. Cadena vacía si no configurada. |
| `recomendacionOrquestadorProvider` | `Provider<RecomendacionOrquestadorService>` | Instancia única del orquestador que coordina los 7 servicios del pipeline |
| `generarRutinaProvider` | `FutureProvider.family<ResultadoGeneracion, ({String usuarioId, bool usarIa})>` | Ejecuta el pipeline completo: sanitización → reglas → contexto → transición → progresión → IA (opcional). Invalida y recarga los 4 providers de contexto antes de ejecutar. |

### 3.3 Proveedores del Módulo de Ejercicios

| Provider | Tipo | Propósito | Fuente |
|----------|------|-----------|--------|
| `ejerciciosProvider` | `StreamProvider<List<EjercicioDb>>` | Catálogo completo en tiempo real | `supabase.from('ejercicios').stream()` (Realtime) |
| `catalogosProvider` | `FutureProvider<CatalogosEjercicios>` | Datos maestros: partes_cuerpo, musculos, equipamientos | `partes_cuerpo`, `musculos`, `equipamientos` |
| `ejercicioDetalleProvider` | `FutureProvider.family<EjercicioDb?, String>` | Detalle completo de un ejercicio (incluye instrucciones) | `v_ejercicios_completos` WHERE `id` |
| `ejerciciosFiltradosProvider` | `Family` (lógica en provider) | Búsqueda con filtros por grupo muscular, equipamiento, parte del cuerpo, dificultad, texto | `v_ejercicios_completos` con filtros |

### 3.4 Proveedores del Dashboard

[OBSOLETO v6.0 — Reemplazado por §9 Dashboard Rediseñado]

> **Nota Sprint 9A:** Los QuickActions Pomodoro y Escanear ya no son placeholders — tienen navegación real a `/pomodoro` y `/escanear`. El `QuickActionsRow` es ahora un `ConsumerWidget` que consume `diaPendienteProvider` para el botón Workout.

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `dashboardProvider` | `FutureProvider<DashboardData>` | Datos agregados: usuario, calorías, sesiones, retos activos, notificaciones, perfil bienestar, plan semanal, rutinas activas. 7 queries en paralelo con `Future.wait`. |

### 3.4.1 Proveedores del Pipeline Académico (NUEVOS v5.0)

| Provider | Tipo | Propósito | Fuente Supabase |
|----------|------|-----------|-----------------|
| `cargaAcademicaSemanalProvider` | `FutureProvider<CargaAcademicaSemanalDb?>` | Carga académica de la semana actual (horas estudio, evaluaciones, estrés, sueño). Timeout 8s. | `carga_academica_semanal` WHERE `usuario_id` AND `semana_inicio = lunes` |
| `adherenciaAcademicaProvider` | `FutureProvider<double>` (0-100) | Disciplina académica pura: `cumplimientoHoras(60%) + completitudTareas(30%) + rachaDias(10%)`. NO usa biometrías. | `carga_academica_semanal` + `entregas_examenes` + `horarios_academicos` |
| `estadoEnergeticoProvider` | `FutureProvider<double>` (0-100) | Estado energético compuesto: base lineal (energía 30%, sueño 25%, recuperación 20%, cognitiva 15%, estrés 10%) × 3 gates no lineales. Previene falsos positivos. | `estado_diario_usuario` (hoy) + `carga_academica_semanal` |
| `contextoAcademicoProvider` | `FutureProvider<ContextoAcademico?>` | DTO que agrega carga semanal + exámenes próximos (7 días) + adherencia + energía. Alimenta el pipeline de recomendación. | `carga_academica_semanal` + `entregas_examenes` + `adherenciaAcademicaProvider` + `estadoEnergeticoProvider` |

**Función `syncCargaAcademicaSemanal(ref)`** (`app/lib/features/bienestar/application/rutina_provider.dart:1094`):
- Se ejecuta automáticamente antes de `_recomendarRutina()` en `NuevaRutinaScreen`
- Consulta `horarios_academicos` (tipo='estudio') → calcula horas reales
- Consulta `entregas_examenes` → cuenta evaluaciones y entregas
- UPSERT en `carga_academica_semanal`
- Invalida 4 providers: `cargaAcademicaSemanalProvider`, `adherenciaAcademicaProvider`, `estadoEnergeticoProvider`, `contextoAcademicoProvider`

**Cálculo de `adherenciaAcademicaProvider`:**
- `cumplimientoHoras` (60%): `horasEstudioReales / horasEstudioPlaneadas`
- `completitudTareas` (30%): `entregas_completadas / total_entregas`
- `rachaDias` (10%): `diasUnicosEstudio / 7`
- Resultado: clamp(0, 100). SIN penalización por sueño o estrés.

**Cálculo de `estadoEnergeticoProvider`:**
- Base: `energíaDiaria×0.30 + sueño×0.25 + recuperación×0.20 + cargaCognitiva×0.15 + estrésInvertido×0.10`
- Gate sueño ≤1 → ×0.40
- Gate dolor ≥4 → ×0.60
- Gate energía ≤1 → ×0.50
- Resultado: clamp(0, 100). Previene falsos positivos como "energía=75 con sueño=0".

### 3.5 Funciones de Mutación (en `rutina_provider.dart`)

| Función | Operación SQL | Invalidaciones |
|---------|--------------|----------------|
| `crearRutinaCompleta({nombre, objetivo, visibilidad, duracionSemanas, estructura, ref})` | INSERT `rutinas` + `semanas_rutina` (con `tipo_semana`) + `dias_rutina` + `seleccion_de_ejercicios` | `rutinasUsuarioProvider` |
| `eliminarRutina(rutinaId, ref)` | DELETE `rutinas` (CASCADE) | `rutinasUsuarioProvider` |
| `clonarRutina(rutinaId, ref)` | INSERT `rutinas` (copia como privada) + `seleccion_de_ejercicios` | `rutinasUsuarioProvider` |
| `iniciarSesion({rutinaId, diaId, ref})` | INSERT `sesiones_registradas` + UPDATE `dias_rutina.estado='en_progreso'` | `diasDeSemanaProvider` |
| `finalizarSesion({sesionId, diaId, rutinaId, duracionSegundos, rpe, ref})` | UPDATE `sesiones_registradas` (duración, RPE, calorías) + UPDATE `dias_rutina.estado='completado'` (cascada a semana vía trigger `trg_dias_rutina_estado`) + **`otorgarXp()`** (cálculo: `50 + min(duraciónMin, 90) + rpe × 5`). Retorna `XpResultado?`. | `diasDeSemanaProvider` + `semanasDeRutinaProvider(rutinaId)` + `dashboardProvider` |
| `registrarSerie({sesionId, seleccionId, numeroSerie, reps, peso})` | INSERT `series_sesion` | — |
| `guardarEstadoDiario({sueño, estrés, energía, dolor, zonas, listo, ref})` | UPSERT `estado_diario_usuario` ON CONFLICT (`usuario_id`, `fecha`) | `estadoDiarioHoyProvider` |
| `agregarEjercicioADia({rutinaId, diaId, ejercicioId, series, reps, descanso, ref})` | INSERT `seleccion_de_ejercicios` | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
| `quitarEjercicioDeDia(seleccionId, diaId, ref)` | DELETE `seleccion_de_ejercicios` | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
| `actualizarEjercicioDia(seleccionId, patch, diaId, ref)` | UPDATE `seleccion_de_ejercicios` — soporta `pesos_kg` (jsonb) como parte del patch | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
| `agregarDiaASemana(semanaId, numeroDia, ref)` | INSERT `dias_rutina` | `diasDeSemanaProvider(semanaId)` |

### 3.6 Proveedores del Módulo de Perfil

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `perfilUsuarioProvider` | `FutureProvider<PerfilUsuario>` | Usuario + perfil bienestar (2 queries, cacheado). Se invalida solo cuando cambia nombre o perfil. |
| `perfilBienestarCompletoProvider` | `FutureProvider<PerfilBienestarCompleto?>` | Perfil bienestar + historial peso (2 queries). Se invalida solo en cambios de bienestar. |
| `perfilActividadProvider` | `FutureProvider<PerfilActividad>` | Sesiones, logros, calorías (3 queries en paralelo con `Future.wait`). |
| `perfilPreferenciasProvider` | `FutureProvider<PreferenciasNotificacionDb>` | Preferencias de notificación (1 query). |
| `perfilCompletoProvider` | `FutureProvider<PerfilCompleto>` | Compuesto que delega en los 4 providers anteriores. Para compatibilidad con otras pantallas. |
| `usuarioCarrerasProvider` | `FutureProvider` | Carreras vinculadas del usuario (M:N) |
| `carrerasUsuarioConNombreProvider` | `Family` | Carreras con nombre de universidad resuelto vía JOIN |
| `carreraConAsignaturasProvider` | `FutureProvider<List<({CarreraDb, List<AsignaturaCatalogoDb>})>>` | Carreras del usuario con sus asignaturas del catálogo. Intenta primero `usuario_carreras` (FK); fallback a búsqueda por nombre desde `perfil_academico_usuario.carrera`. Útil para la sección Plan de estudios en PerfilScreen. |
| `asignaturasUsuarioSemestreProvider` | `FutureProvider<List<AsignaturaUsuarioSemestreDb>>` | Asignaturas del catálogo con `semestre=0` que el usuario ha mapeado a un curso+semestre mediante la tabla `asignaturas_usuario_semestre`. |
| `asignaturasSinSemestreProvider` | `FutureProvider<List<AsignaturaCatalogoDb>>` | Asignaturas del catálogo con `semestre=0` (optativas/transversales sin temporalidad fija) que el usuario puede mapear manualmente. Filtra por carrera del usuario. |
| `_getCarrerasUsuario()` | Función helper | Devuelve `List<String>` de `carrera_id` del usuario. Consulta `usuario_carreras` primero; fallback a búsqueda por nombre desde `perfil_academico_usuario.carrera`. Usada por `asignaturasUsuarioSemestreProvider` y `asignaturasSinSemestreProvider`. |

**Invalidación selectiva (`PerfilCambio` enum):**
- `PerfilCambio.nombre` → solo `perfilUsuarioProvider` (2 queries vs 7)
- `PerfilCambio.bienestar` → `perfilBienestarCompletoProvider` + `perfilUsuarioProvider` + `perfilBienestarProvider` (3-4 queries vs 7)
- `PerfilCambio.preferencias` → solo `perfilPreferenciasProvider` (1 query vs 7)
- `PerfilCambio.todo` → todos los providers
- Sin `autoDispose` → keepAlive implícito en memoria tras primera carga

## 4. Pantalla: Nueva Rutina con IA (`NuevaRutinaScreen`)

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart`
**Ruta:** `/bienestar/nueva-rutina`

### 4.1 Flujo de 3 Pasos (v5.0 — con Motor de Recomendaciones)

```mermaid
flowchart TD
    Start["Usuario accede a Nueva Rutina"] --> Paso1["PASO 1: Metadatos"]

    Paso1 --> BotonRapido{"⚡ Generar rutina rápida\n(FilledButton, siempre visible)"}
    Paso1 --> BotonIA{"✨ Recomendar con IA\n(OutlinedButton, solo con API key)"}

    BotonRapido -->|"Motor determinista\n(Fases 0-8, sin IA)"| Pipeline["Pipeline completo:\n1. Sanitizar objetivo\n2. Reglas → estructura\n3. Contexto → ajustes\n4. Progresión → sobrecarga\n5. Validación"]
    BotonIA -->|"IA opcional\n(Fase 6 incluida)"| PipelineIA["Pipeline + refinarRutina()\nGemini mejora nombres,\nvaría 1-2 ejercicios/día,\nreordena"]

    Pipeline --> Paso2["PASO 2: Estructura\nrellena automáticamente"]
    PipelineIA --> Paso2

    Paso2 --> Semanas["Selector de semanas\n(añadir/eliminar)"]
    Semanas --> Dias["Por cada semana: lista de días\n(añadir/eliminar)"]
    Dias --> Paso3

    Paso3["PASO 3: Revisión"] --> Review["Resumen: semanas, días,\nejercicios totales,\nperiodización, modalidades"]
    Review --> Create["Crear Rutina\nllama a crearRutinaCompleta()"]
    Create --> Navigate["Navega a /bienestar/rutina/:id"]
```

**Cambios clave respecto a v4.x:**
- **Eliminados:** Botón redundante "Recomendar ejercicios" y método `_recomendarEjercicios()` (~140 líneas). Método `_llenarEstructuraDesdeRecomendacion()` (~30 líneas).
- **Eliminado:** Método privado `_sanitizarObjetivo()` — ahora usa `sanitizarObjetivo()` de `string_utils.dart`.
- **Nuevo:** Botón "⚡ Generar rutina rápida" (FilledButton, siempre visible) ejecuta el pipeline determinista completo en <2s.
- **Nuevo:** Botón "✨ Recomendar rutina con IA" (OutlinedButton, solo visible si `GEMINI_API_KEY` configurada) añade refinamiento con Gemini.
- **`_DiaEditorCard`** ahora recibe `objetivo` como parámetro para defaults contextuales al añadir ejercicios manualmente.
- **`_generarRutinaRapida()`** resuelve nombres de ejercicios desde el catálogo real y aplica defaults por objetivo.

### 4.2 Datos de Entrada al Motor de Recomendaciones

El pipeline determinista (y el refinamiento IA opcional) reciben los siguientes datos, recopilados de providers Riverpod:

| Dato | Provider/Origen | Uso en el pipeline |
|------|----------------|-------------------|
| Edad, sexo, peso, altura, IMC | `perfilBienestarProvider` | `ParametrosObjetivo` + `RecomendacionContextoService` (tendencia peso) |
| Objetivo principal | `perfilBienestarProvider` | `sanitizarObjetivo()` → `ParametrosObjetivo.de()` → tabla de 7 parámetros |
| Nivel de actividad | `perfilBienestarProvider` | `determinarSplit()` y `_nivelNumerico()` en reglas |
| Equipamiento disponible | `perfilBienestarProvider` | Filtro de compatibilidad en `_aplicarFiltros()` |
| Días disponibles / semana | `perfilBienestarProvider` | `determinarSplit()` — árbol de decisión del split |
| Minutos por sesión | `perfilBienestarProvider` | No usado directamente por el motor de reglas (usa `ejerciciosPorDia` de `ParametrosObjetivo`) |
| Historial de sesiones | `historialSesionUsuarioProvider` | `ProgresionCalculator` (sobrecarga) + `RecomendacionReglasService` (filtro de ejercicios recientes) |
| Estado diario (hoy) | `estadoDiarioHoyProvider` | `RecomendacionContextoService` (FCT, fatiga, listoParaEntrenar) |
| Catálogo de ejercicios | `ejerciciosProvider` | Filtrado por equipamiento, enviado a los 5 filtros del motor de reglas |
| Contexto académico | `cargaAcademicaSemanal` | `RecomendacionContextoService.calcularFCT()` — pondera estudio, estrés, evaluaciones |
| Historial de objetivos | `historial_objetivos` | `TransicionObjetivoService` — interpola si hubo cambio de objetivo |
| Ejercicios ya agregados | Estado local del formulario | Lista de exclusión en el motor de reglas (no repite músculos primarios) |

### 4.3 Botón de Cancelación y Pantalla de Generación IA

**Pantalla de carga profesional unificada** para "Recomendar rutina", "Recomendar ejercicios" y "Sugerir Rutina con IA":

```
┌─────────────────────────────────────────────┐
│                                             │
│         (Icono IA con gradiente             │
│          verde, pulsa suavemente)            │
│                                             │
│           SynaptixFit AI                    │
│   Generando tu rutina personalizada          │
│      (o: Generando estructura de ejercicios) │
│                                             │
│      ━━━━━━━━━━━━━━━━━━━━━━━━              │
│      (barra de progreso animada)            │
│                                             │
│   ┌─────────────────────────────────┐      │
│   │ ◌  Analizando tu perfil...      │      │
│   └─────────────────────────────────┘      │
│                                             │
│              [ Cancelar ]                    │
│                                             │
└─────────────────────────────────────────────┘
```

**Secuencias de mensajes por tipo de carga:**

| Etapa | Rutina | Ejercicios |
|-------|--------|------------|
| 1 | Analizando tu perfil físico... | Analizando estructura de la rutina... |
| 2 | Consultando tu historial de entrenamiento... | Evaluando periodización por semana... |
| 3 | Revisando tu estado diario... | Distribuyendo grupos musculares... |
| 4 | Procesando catálogo de ejercicios... | Seleccionando ejercicios compatibles... |
| 5 | Aplicando reglas de periodización... | Ajustando volumen e intensidad... |
| 6 | Personalizando según tu objetivo... | Organizando días de entrenamiento... |
| 7 | Estructurando semanas y días... | Verificando progresión de cargas... |
| 8 | ¡Casi listo! Ajustando detalles finales... | ¡Casi listo! Últimos ajustes... |

**Botón Cancelar:**
- `TextButton.icon` con `Icons.close`, texto "Cancelar", color `theme.colorScheme.error`.
- Llama a `_cancelarCargaIA()`: detiene el `Timer` de mensajes, limpia `_loadingIA` y `_tipoCarga`.
- Muestra Snackbar: "Recomendación cancelada."
- Guard `if (!_loadingIA) return;` tras cada `await` de Gemini descarta respuestas tardías.

**Comportamiento del botón Cancelar:**

| Acción | Resultado |
|--------|-----------|
| Pulsar "Cancelar" durante carga | Se detiene la secuencia de mensajes y se oculta la pantalla de carga. El formulario Paso 1 se muestra intacto. |
| Indicador visual | Pantalla completa de generación con icono pulsante, barra de progreso, mensajes secuenciales y botón Cancelar. |
| Cobertura | Aplica a los 2 botones de IA en Paso 1: "Recomendar rutina" y "Recomendar ejercicios" (vía `_tipoCarga`). |

### 4.4 Campo de Peso con Soporte Decimal

El campo de peso (`pesoKg`) en el editor de ejercicios (Paso 2) ha sido mejorado:

| Aspecto | Antes | Ahora |
|---------|-------|-------|
| Tipo de entrada | `TextInputType.numberWithOptions(decimal: true)` — pero con comportamiento errático en enteros | `TextInputType.numberWithOptions(decimal: true)` con `inputFormatters` que permiten decimales (ej: `75.5`) |
| Facilidad de entrada | Difícil introducir cifras de varios dígitos | Campo numérico fluido con soporte para punto decimal |
| Validación | `double.tryParse(v)` — acepta nulos | `double.tryParse(v)` — acepta nulos y decimales correctamente |
| UI | `TextField` con hint "— kg" | `TextField` con hint "— kg", label "Peso", icono de balanza, teclado numérico optimizado |

### 4.5 Manejo de Errores de IA

| Escenario | Comportamiento |
|-----------|---------------|
| `GEMINI_API_KEY` no configurada | Error descriptivo: "Falta GEMINI_API_KEY en el archivo .env". El formulario sigue funcionando en modo manual. |
| Sin ejercicios compatibles con equipamiento | Error: "No hay ejercicios compatibles con tu equipamiento (peso_corporal, mancuerna)." |
| Gemini no responde (timeout 15s) | Error: "No se pudo conectar con Gemini en este momento." |
| Gemini responde con JSON malformado | `_extraerJson()` intenta 3 estrategias de parsing. Si falla: "Gemini generó una respuesta con formato no válido." |
| Gemini responde con array/objeto vacío | Error específico: "Gemini no generó ejercicios válidos." |
| Usuario cancela manualmente | Snackbar: "Recomendación cancelada". El formulario queda intacto. |

### 4.6 Botón "Sugerir Rutina con IA" y Auto-Trigger

Desde la pantalla de **Rutinas** (`RutinasComunidadScreen`), el usuario dispone de un acceso rápido para generar una rutina con IA sin pasar manualmente por los 3 pasos:

```
RutinasComunidadScreen
  │
  ├── FAB "Nueva rutina" → /bienestar/nueva-rutina (modo manual normal)
  │
  └── Botón "Sugerir Rutina con IA"
        │  FilledButton.tonalIcon verde con Icons.auto_awesome
        │  Ubicado bajo el SegmentedButton de tabs
        │
        └── Navega a /bienestar/nueva-rutina
              extra: {'autoRecomendar': true}
                    │
                    ▼
              NuevaRutinaScreen(autoRecomendar: true)
                    │
                    │  initState() → addPostFrameCallback
                    │
                    └── _recomendarRutina() se dispara automáticamente
                          │
                          ├── Rellena: nombre, descripción, objetivo, duración
                          ├── Muestra SnackBar: "¡Rutina recomendada!"
                          └── El usuario continúa manualmente desde Paso 1
```

**Pantalla de generación IA** (`_buildPantallaGeneracion`):

Cuando se activa el modo auto, en lugar del formulario Paso 1 se muestra una pantalla de carga profesional:

```
┌─────────────────────────────────────────────┐
│                                             │
│         (Icono IA con gradiente             │
│          verde, pulsa suavemente)            │
│                                             │
│           SynaptixFit AI                    │
│      Generando tu rutina personalizada       │
│                                             │
│      ━━━━━━━━━━━━━━━━━━━━━━━━              │
│      (barra de progreso animada)            │
│                                             │
│   ┌─────────────────────────────────┐      │
│   │ ◌  Analizando tu perfil físico...│      │
│   └─────────────────────────────────┘      │
│                                             │
└─────────────────────────────────────────────┘
```

**Secuencia de mensajes animados** (8 etapas, 1800ms cada una):
1. "Analizando tu perfil físico..."
2. "Consultando tu historial de entrenamiento..."
3. "Revisando tu estado diario..."
4. "Procesando catálogo de ejercicios..."
5. "Aplicando reglas de periodización..."
6. "Personalizando según tu objetivo..."
7. "Estructurando semanas y días..."
8. "¡Casi listo! Ajustando detalles finales..."

**Elementos visuales:**
- Icono de IA: círculo 96px con gradiente `#006E2D → #00C853`, glow verde, icono `auto_awesome`.
- Pulso animado: `TweenAnimationBuilder` escala 0.92 → 1.08 en 1200ms, bucle infinito.
- Barra de progreso: `LinearProgressIndicator` indeterminada, 200px, color `#00C853`.
- Mensajes: `AnimatedSwitcher` con `ValueKey` para transición suave entre mensajes.

**Fix de teclado:**
- `autofocus` del campo Nombre ahora es condicional: `autofocus: !widget.autoRecomendar`.
- En modo auto-generación el teclado no se abre, permitiendo ver la pantalla completa.

**Implementación en el router** (`app_router.dart:107-115`):
```dart
GoRoute(
  path: '/bienestar/nueva-rutina',
  builder: (context, state) {
    final extra = state.extra;
    final autoRecomendar =
        extra is Map && extra['autoRecomendar'] == true;
    return NuevaRutinaScreen(autoRecomendar: autoRecomendar);
  },
),
```

**Implementación en la pantalla** (`nueva_rutina_screen.dart:92-98`):
```dart
@override
void initState() {
  super.initState();
  _inicializarEstructura();
  _cargarObjetivoPerfil();
  if (widget.autoRecomendar) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomendarRutina());
  }
}
```

El usuario ve la pantalla de generación IA con los mensajes progresivos. Al finalizar, se muestra el Paso 1 con los campos ya rellenados.

| Escenario | Comportamiento |
|-----------|---------------|
| `GEMINI_API_KEY` no configurada | Error descriptivo: "Falta GEMINI_API_KEY en el archivo .env". El formulario sigue funcionando en modo manual. |
| Sin ejercicios compatibles con equipamiento | Error: "No hay ejercicios compatibles con tu equipamiento (peso_corporal, mancuerna)." |
| Gemini no responde (timeout 15s) | Error: "No se pudo conectar con Gemini en este momento." |
| Gemini responde con JSON malformado | `_extraerJson()` intenta 3 estrategias de parsing. Si falla: "Gemini generó una respuesta con formato no válido." |
| Gemini responde con array/objeto vacío | Error específico: "Gemini no generó ejercicios válidos." |
| Usuario cancela manualmente | Snackbar: "Recomendación cancelada". El formulario queda intacto. |


### 4.7 Progreso de Rutinas en "Mis rutinas" (RutinasComunidadScreen)

En la pestaña "Mis rutinas" de la pantalla principal de bienestar (RutinasComunidadScreen), se presentará un resumen visual y creativo sobre el progreso del usuario.

**Elementos UI/UX:**
- **Tarjetas interactivas de rutinas:** Cada rutina activa mostrará una barra de progreso circular o lineal, destacando el porcentaje de completitud.
- **Resumen rápido:** Estadísticas visibles de un vistazo, como "3/12 sesiones completadas", "Faltan 2 días para terminar la semana de carga", y el próximo hito.
- **Incentivos visuales:** Se usarán códigos de colores para reflejar el estado actual (ej. verde para ritmo óptimo, naranja si se aproxima una semana de descarga).
- **Llamada a la acción clara:** Botón prominente de "Continuar entrenamiento" en la rutina activa que lleva directamente a la siguiente sesión pendiente en RutinaDetalleScreen.


## 5. Pantalla: Detalle de Rutina (`RutinaDetalleScreen`)

**Archivo:** `app/lib/features/bienestar/presentation/rutina_detalle_screen.dart`
**Ruta:** `/bienestar/rutina/:id`

### 5.0 Sistema de Drill-Down (Semana → Día → Ejercicios)

La pantalla de detalle implementa un patrón de navegación jerárquico de 3 niveles:

```
┌─────────────────────────────────────────────────┐
│  NIVEL 1: Selector de Semanas                    │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ Sem 1   │ │ Sem 2   │ │ Sem 3   │ ...       │
│  │ Adapt   │ │ Carga   │ │ Pico    │           │
│  │ 5 ejerc │ │ 6 ejerc │ │ 4 ejerc │           │
│  └────┬────┘ └─────────┘ └─────────┘           │
│       │ (tap)                                   │
│       ▼                                         │
│  ═══════════════════════════════════════════    │
│  NIVEL 2: Lista de Días (Semana seleccionada)   │
│  ┌─────────────────────────────────────────┐   │
│  │ Día 1 — Pierna         4 ejercicios  ▶ │   │
│  │ ▸ Sentadilla con barra   4×8×90s        │   │
│  │ ▸ Prensa de pierna       3×12×60s       │   │
│  │ ▸ Extensión de cuádriceps 3×15×45s      │   │
│  │ ▸ Peso muerto rumano    3×10×90s        │   │
│  ├─────────────────────────────────────────┤   │
│  │ Día 2 — Empuje          5 ejercicios  ▶ │   │
│  │ ▸ Press banca plano      4×8×120s       │   │
│  │ ▸ Press militar          3×10×90s       │   │
│  │ ▸ ... (colapsado)                        │   │
│  └─────────────────────────────────────────┘   │
│       │ (tap en día)                            │
│       ▼                                         │
│  ═══════════════════════════════════════════    │
│  NIVEL 3: Detalle de Día (expansión completa)   │
│  ┌─────────────────────────────────────────┐   │
│  │ Día 1 — Pierna          ▼               │   │
│  │                                          │   │
│  │ 1. Sentadilla con barra                  │   │
│  │    Series: 4  Reps: 8  Descanso: 90s     │   │
│  │    Peso: 80 kg                           │   │
│  │    [−] [Series] [+] [−] [Reps] [+]       │   │
│  │                                          │   │
│  │ 2. Prensa de pierna                      │   │
│  │    Series: 3  Reps: 12  Descanso: 60s    │   │
│  │    Peso: 120 kg                          │   │
│  │    [−] [Series] [+] [−] [Reps] [+]       │   │
│  │    ...                                   │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

**Interacciones de drill-down:**

| Nivel | Acción | Resultado |
|-------|--------|-----------|
| Semana | Tap en chip de semana | Se despliega el nivel 2 con los días de esa semana y vista previa de ejercicios (miniatura) |
| Día (colapsado) | Tap en card de día | El día se expande mostrando el **listado completo de ejercicios** con todos sus detalles editables |
| Día (expandido) | Tap en card de día | El día se colapsa ocultando los detalles |
| Ejercicio | Tap en fila de ejercicio | Entra en **modo edición inline**: se habilitan steppers ± para series, reps, descanso y campo de peso |
| Ejercicio | Long-press | Menú contextual: "Sustituir ejercicio" (abre buscador) o "Eliminar de este día" |

**Estados visuales de días:**

| Estado | Estilo |
|--------|--------|
| `pendiente` | Fondo gris claro, borde sutil, texto "Pendiente" |
| `en_progreso` | Fondo ámbar suave, borde ámbar, icono de reloj |
| `completado` | Fondo verde (#006E2D al 8%), borde verde, check en badge, highlight sutil |

**Animaciones:**
- Expansión/colapso de días con `AnimatedCrossFade` o `AnimatedSize` para transición suave.
- Los ejercicios dentro de un día expandido usan `ListView` con separadores para rendimiento.
- La barra de progreso en el header se actualiza en tiempo real al cambiar estados.

### 5.1 Componentes del Header

| Elemento | Fuente de datos | Descripción |
|----------|----------------|-------------|
| Nombre de rutina | `RutinaDb.nombre` | Título principal |
| Badge de objetivo | `RutinaDb.objetivo` | Chip coloreado: fuerza (rojo), resistencia (azul), hipertrofia (púrpura), movilidad (teal), mixto (gris) |
| Badge de estado | `RutinaDb.estado` | Chip: activo (verde), pausado (ámbar), completado (azul) |
| Duración | `RutinaDb.duracionSemanas` | "4 semanas" |
| Barra de progreso | Cálculo: días completados / días totales | Barra lineal con porcentaje |
| Días completados | Suma de días con `estado='completado'` | "8/16 días" |
| Tiempo total | Suma de `tiempoDiaProvider` para todos los días | "3h 25min acumulados" |

### 5.2 Selector de Semanas con Periodización

```
[Sem 1 Adapt] [Sem 2 Carga] [Sem 3 Carga] [Sem 4 Desc]
    ████          ████         ████          ████
```

Cada chip de semana muestra:
- **Número de semana** (1, 2, 3, 4...)
- **Tipo de semana** con badge coloreado: Adapt (azul), Carga (verde), Pico (naranja), Desc (teal)
- **Icono de check** (✓) si la semana está completada
- **Indicador de ejercicios**: "5 ejercicios" o conteo de días

### 5.3 Lista de Días

Cada día muestra:
- **Número y nombre** ("Día 1", "Día 2 - Pierna"...)
- **Estado:** pendiente (gris), en_progreso (ámbar), completado (verde con fondo)
- **Ejercicios:** lista con nombre, series × reps, peso (kg), descanso
- **Edición inline:** botones ± para series/reps/descanso, campo de peso
- **Botón "Iniciar"** → navega a `LiveSessionScreen` (bloqueado si no hay ejercicios)
- **Botón "Añadir ejercicio"** → abre buscador de catálogo
- **Long-press en ejercicio** → opción de sustituir

### 5.4 Validación Pre-Inicio

```dart
// En RutinaDetalleScreen, antes de navegar a sesión en vivo:
if (ejerciciosDelDia.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Este día no tiene ejercicios. Añade al menos uno.')),
  );
  return; // No navega
}
// Si tiene ejercicios → inicia sesión (check-in se hace durante el primer descanso vía _CheckInOverlay)
```

### 5.5 Bloqueo de Día sin Ejercicios

- El botón "Iniciar" se muestra deshabilitado (gris) si `ejerciciosDeDiaProvider` devuelve lista vacía
- Tooltip: "Añade ejercicios a este día antes de empezar"

### 5.6 Invalidación al Modificar Ejercicios

Cuando se añade, quita o edita un ejercicio de un día:
1. `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` se invalidan → UI se refresca con nombres actualizados
2. Si el día estaba `completado` → se revierte a `pendiente` en BD y se invalidan `diasDeSemanaProvider` + `semanasDeRutinaProvider`
3. La cascada de semana se delega al trigger `trg_dias_rutina_estado` en BD: si algún día deja de estar completado, la semana se revierte automáticamente
4. El botón "Iniciar" reaparece porque el día vuelve a estar pendiente

### 5.7 Rutina Completada: UI Read-Only + Reutilizar

Cuando todas las semanas de una rutina tienen estado `'completada'`, la UI cambia a modo read-only:

| Elemento | Estado normal | Rutina completada |
|----------|--------------|-------------------|
| Icono editar (AppBar actions) | `edit_outlined` visible | **Oculto** |
| Icono reutilizar (AppBar actions) | No existe | `refresh_rounded` visible |
| Botón inferior | "Completar rutina" | "Reutilizar rutina" |
| Edición inline de ejercicios | Permitida | Bloqueada vía safety gate `_editarRutina()` |
| Diálogo de celebración | No | `_CelebracionDialog` al detectar completitud |

**Flujo "Completar rutina":**

```dart
Future<void> _completarRutina() async {
  // UPDATE rutinas SET estado='completado'
  // Invalida rutinasUsuarioProvider + semanasDeRutinaProvider
  // Navega a context.go('/bienestar')
}
```

- El botón se muestra solo cuando `!todasCompletadas` (quedan semanas pendientes).
- Se invalida `rutinasUsuarioProvider` y `semanasDeRutinaProvider` tras la actualización.
- Navega de vuelta a la lista de rutinas (`/bienestar`).

**Flujo "Reutilizar rutina" (`_reutilizarRutina()`):**

Clona la jerarquía completa de la rutina:

1. **Crear nueva rutina:** INSERT en `rutinas` con nombre `"{original} (copia)"`, visibilidad `'private'`, estado `'activo'`.
2. **Iterar semanas:** Por cada `semanas_rutina` → INSERT con `tipo_semana` preservado.
3. **Iterar días:** Por cada `dias_rutina` → INSERT en la nueva semana.
4. **Copiar ejercicios:** Por cada `seleccion_de_ejercicios` del día original → INSERT con todos los parámetros:
   - `peso_kg`, `pesos_kg` (jsonb), `duracion_segundos`, `distancia_metros`, `tiempo_isometrico_segundos`
5. **Actualizar contador:** `UPDATE rutinas SET cantidad_ejercicios = total`.
6. **Invalidar y navegar:** `ref.invalidate(rutinasUsuarioProvider)` → `context.go('/bienestar/rutina/$nuevoId')`.

**Safety gate:** `_editarRutina()` verifica `todasCompletadas` al inicio y retorna temprano si es `true`.

### 5.8 Pesos por Serie con Toggle "Mismo peso en todas las series"

**Archivo:** `app/lib/features/bienestar/presentation/rutina_detalle_screen.dart`

En la edición inline de ejercicios dentro del detalle de rutina (Nivel 3 expandido), se incorporó un nuevo sistema de pesos por serie:

**Toggle "Mismo peso en todas las series":**
- Cuando está activado (default): las series usan el campo `peso_kg` único.
- Cuando se desactiva: aparecen `N` campos de peso (uno por serie) con steppers ± independientes.

**Estado local:**
```dart
late List<double> _pesosKg;          // Inicializado desde e.pesosKg ?? List.filled(e.series, 0.0)
bool _mismoPeso = e.pesosKg == null;  // true si pesos_kg es null en BD
```

**Comportamiento:**
- Al cambiar el número de series: la lista `_pesosKg` se redimensiona preservando valores existentes.
- Si `_mismoPeso`: se serializa `pesos_kg: null` en el UPDATE.
- Si `!_mismoPeso`: se serializa `pesos_kg: [50.0, 52.5, 55.0, ...]` en el UPDATE a `actualizarEjercicioDia()`.
- Cada campo de peso por serie se muestra en una fila con steppers ±1.0kg / ±0.5kg y sufijo "kg".

**Integración con `actualizarEjercicioDia()`:**

```dart
// En rutina_detalle_screen.dart:1195-1200
final updateMap = <String, dynamic>{...};
if (_mismoPeso) {
  updateMap['pesos_kg'] = null;        // Limpia jsonb, usa peso_kg
} else {
  updateMap['pesos_kg'] = _pesosKg;    // Guarda array de pesos
}
await actualizarEjercicioDia(e.id, updateMap, diaId, ref);
```

## 6. Pantalla: Sesión en Vivo (`LiveSessionScreen`)

**Archivo:** `app/lib/features/bienestar/presentation/sesion_en_vivo_screen.dart`
**Ruta:** `/bienestar/rutina/sesion`

### 6.1 Check-in Diario (durante el primer descanso) + Adaptación IA

El check-in ya no bloquea el inicio de la sesión. El cronómetro aparece **inmediatamente** al pulsar "Empezar entrenamiento", y el check-in se muestra durante el **primer descanso** (tras completar la primera serie). **Si el usuario ya hizo check-in hoy, el overlay no se muestra en absoluto** (verificación silenciosa antes de mostrar).

**Texto del overlay mejorado:** "Tus respuestas adaptan el entrenamiento y mejoran las recomendaciones futuras."

```mermaid
flowchart TD
    A["Usuario pulsa 'Empezar entrenamiento'"] --> B["iniciarSesion()\nCronómetro + ejercicios visibles"]

    B --> C["Usuario marca 1ª serie completada"]
    C --> D["iniciarDescanso()\nTimer descanso 90s"]

    D --> E{"_lanzarCheckInOverlay():\n¿Hay check-in hoy?\n(estadoDiarioHoyProvider)"}
    E -->|Sí| F["No mostrar nada.\nContinuar sesión normal."]
    E -->|No| G["Mostrar _CheckInOverlay\n(overlay no bloqueante)"]

    G --> H["4 Sliders (1-5):\n• Sueño • Estrés • Energía • Dolor + zonas"]

    H --> I{"¿Pulsa 'Guardar'?"}
    I -->|"Omitir"| J["Continuar sesión sin datos"]
    I -->|"Guardar"| K["guardarEstadoDiario()\nUPSERT estado_diario_usuario"]

    K --> L["Calcular fatiga:\n(6-s)×5+(e-1)×5+(6-en)×4+(d-1)×7"]

    L --> M{"¿Requiere adaptación?\n(fatiga>50, dolor≥3, energía≤2)"}
    M -->|Sí| N["_AdaptacionDialog con sugerencias"]
    M -->|No| J

    N --> O["Sugerencias:\n- Reducir series\n- Bajar peso\n- Evitar zonas con dolor\n- Reducir intensidad"]
    O --> P{"¿Usuario acepta?"}
    P -->|"Ignorar todo"| J
    P -->|"Aplicar"| Q["Aplica adaptaciones:\n- _seriesReducidas = true\n- Banner naranja visible"]

    Q --> J
    J --> R["Sesión continúa normalmente"]
```

**Reglas de adaptación (locales, sin IA):**

| Condición | Sugerencia | Efecto |
|-----------|-----------|--------|
| `fatiga > 50` | Reducir 1 serie por ejercicio | `_seriesReducidas = true` → efecto en UI (ver más abajo) |
| `fatiga > 50` | Bajar peso 10% en compuestos | Sugerencia visual (no se aplica automáticamente al peso del TextField) |
| `dolor ≥ 3` + zonas | Evitar ejercicios de [zonas] | `_ejerciciosEvitados` se rellena. Banner rojo visible. |
| `energía ≤ 2` | Reducir intensidad general | `_seriesReducidas = true` (mismo efecto) |

**Consumo efectivo de `_seriesReducidas` en la UI:**

La bandera `_seriesReducidas` se pasa desde `_LiveSessionScreenState` → `_EjerciciosList` → `_EjercicioLiveCard`:

```dart
// En _EjercicioLiveCard (sesion_en_vivo_screen.dart:714-715)
final seriesEfectivas =
    seriesReducidas ? (e.series - 1).clamp(1, 99) : e.series;
```

| Aspecto | Normal | `seriesReducidas == true` |
|---------|--------|--------------------------|
| Series por ejercicio | `e.series` | `(e.series - 1).clamp(1, 99)` |
| Texto de series | `"4×10 · 90s"` | `"3×10 · 90s (adaptado)"` en naranja |
| Borde de tarjeta | `outlineVariant` | Naranja con opacidad 30% |
| `List.generate` | `e.series` iteraciones | `seriesEfectivas` iteraciones |

**Prellenado de pesos por serie desde `pesos_kg`:**

```dart
// En _EjercicioLiveCard (sesion_en_vivo_screen.dart:822-834)
final pesoInicial = (e.pesosKg != null &&
        i < e.pesosKg!.length &&
        e.pesosKg![i] > 0)
    ? e.pesosKg![i]
    : e.pesoKg;
```

Cada campo de peso en la sesión en vivo se inicializa con el valor del array `pesos_kg` para esa serie específica. Si no existe o es 0, usa `peso_kg` como fallback.

**Banners de estado durante la sesión:**
- Banner naranja: "Sesión adaptada: -1 serie por ejercicio" (visible si `_seriesReducidas == true`)
- Banner rojo: "Se evitarán ejercicios de: [zonas]" (visible si `_ejerciciosEvitados` no está vacío)

### 6.2 Funcionalidad Durante la Sesión

| Componente | Comportamiento |
|------------|---------------|
| **Cronómetro** | Se inicia automáticamente al entrar. Muestra `HH:MM:SS` en barra superior. |
| **Timer Bar (`_buildTimerBar`)** | Barra fija debajo del AppBar mostrando el cronómetro principal + texto "Objetivo: HH:MM:SS" en gris tenue (calculado como suma de `duracionObjetivoSegundos` de todos los ejercicios del día). |
| **Lista de ejercicios** | Cada ejercicio muestra sus series como filas con: checkbox circular, campo de peso (kg) editable, campo de reps editable. |
| **Check de serie** | Al marcar completada → `registrarSerie()` + inicia cronómetro de descanso (90s). **También inicia el lap por timestamp** (`_lapStartTimes.putIfAbsent(seleccionId, DateTime.now())`). |
| **Cronómetro de descanso** | Cuenta atrás visible. Botones: `+15s`, `-15s`, `Saltar`. Al llegar a 0, desaparece automáticamente. |
| **Edición de peso/reps** | Campos editables inline durante la sesión. Se guardan en `series_sesion`. |
| **Sistema de Laps por Timestamp** | `Map<String, DateTime> _lapStartTimes` registra el inicio de cada ejercicio. `_capturarLap(seleccionId)` calcula `DateTime.now().difference()` y acumula en `_duracionRealMap`. Los laps se capturan al marcar series y al finalizar sesión. **Inmune a backgrounding** (usa timestamps absolutos, no un contador). |

### 6.3 Diálogo de Finalización

Al pulsar "Finalizar sesión":
1. Captura todos los laps abiertos (`for (final id in _lapStartTimes.keys) _capturarLap(id)`)
2. Muestra duración total en formato legible (ej: "45 min 30 s")
3. **Slider RPE** (1-10): Rate of Perceived Exertion
4. **ChoiceChips de persistencia:**
   - "Solo hoy": los cambios de peso/reps NO se guardan en `seleccion_de_ejercicios` (solo en `series_sesion`)
   - "Para siempre": los cambios de peso/reps SÍ se actualizan en `seleccion_de_ejercicios` para futuras sesiones
5. Al confirmar → `finalizarSesion()` recibe `duracionRealPorEjercicio: Map<String, int>` (desde `_duracionRealMap`) que persiste `duracion_real_segundos` en `seleccion_de_ejercicios`. Además actualiza `sesiones_registradas` (duración, RPE, calorías), calcula XP (`50 + min(duraciónMin, 90) + rpe × 5`), llama `otorgarXp()` y retorna `XpResultado?`.
6. **Cálculo calórico en la sesión:** usa `duracionRealSegundos` cuando existe (dato real medido), fallback a `duracionObjetivoSegundos` (proyección planificada).
7. **NUEVO v5.2 — Feedback de XP:** Tras finalizar, se muestra SnackBar:
   - **Sin level-up:** `"+130 XP 🔥"` (duración 2s)
   - **Con level-up:** `"¡Subiste a nivel 5! 🎉 +130 XP"` (duración 3s)
8. Navegación de vuelta a `RutinaDetalleScreen`

**Cambio en navegación post "Completar rutina":**
- Desde `RutinaDetalleScreen`, el botón "Completar rutina" ahora navega a `context.go('/bienestar')` (vuelve a la lista principal), en lugar de permanecer en la misma pantalla.

### 6.4 Indicador de Fatiga

En `RutinaDetalleScreen`, antes de pulsar "Empezar entrenamiento":
- Si `estadoDiarioHoyProvider` devuelve `requiereAdaptacion == true` → banner naranja:
  > ⚠️ Hoy tu cuerpo necesita un entrenamiento más ligero. La IA adaptará las recomendaciones.

## 7. Pantalla: Perfil de Usuario (`PerfilScreen`)

**Archivo:** `app/lib/features/perfil/presentation/perfil_screen.dart` (~1277 líneas)
**Ruta:** `/perfil`

Estructura: `NestedScrollView` con `DefaultTabController(length: 3)` — 3 pestañas bajo un Hero Header común.

### 7.1 Hero Header (`_HeroHeader`)

Widget `SliverToBoxAdapter` al inicio del `NestedScrollView`, con diseño atlético moderno:

| Elemento | Descripción |
|----------|-------------|
| **Fondo** | `LinearGradient` de 3 tonos navy: `#0A1628` → `#152238` → `#0D1B2A` |
| **Avatar** | `Container` 88px circular con anillo de gradiente verde (`#72FE8G` → `#006E2D`) y `boxShadow` glow. Contenido: `ClipOval` con `Image.network` (carga progresiva con `loadingBuilder`) y fallback a inicial estilizada (`_avatarInitial()`: texto verde sobre fondo `#1A2A40`) |
| **Nombre** | `Text` blanco 22px `FontWeight.w800`, `maxLines: 1`. Icono `Icons.edit` a la derecha con `InkWell` → diálogo `_editarNombre()` → `BienestarRepository.actualizarNombre()` → invalida `_onPerfilActualizado(cambio: PerfilCambio.nombre)` → solo `perfilUsuarioProvider` (2 queries) |
| **Email** | Texto con opacidad 50%, 13px |
| **Badge de nivel** | Chip con `Icons.stars_rounded` verde + "Nivel X". Barra XP: `LinearProgressIndicator` con progreso `xpTotal / (1000 × nivel)`, color `#72FE8G` |
| **Mini stats** | Fila: racha (🔥), días/semana (📅), minutos/sesión (⏱) — emoji 18px + valor blanco 15px bold + label 10px gris |

Datos del header: `UsuarioDb` (nombre, email, nivel, xpTotal, rachaActual, urlAvatar) + `PerfilBienestarDb` (diasDisponiblesSemana, minutosPorSesion).

### 7.2 Pestaña 1 — Estadísticas (`_EstadisticasTab`)

`Row` con 4 `Expanded` stats: Sesiones, XP, Calorías, Retos (separados por `_statDivider`).

| Stat | Valor | Icono |
|------|-------|-------|
| **Sesiones** | `act.sesiones` | `Icons.fitness_center_rounded` |
| **XP** | `_formatNum(widget.usuario.xpTotal)` | `Icons.stars_rounded` |
| **Calorías** | `_formatNum(act.caloriasAcumuladas)` | `Icons.local_fire_department_rounded` |
| **Retos** | `act.logros` | `Icons.emoji_events_rounded` |

Cada stat se renderiza con `_statItem()`: icono, valor numérico grande (`fontSize: 22`, `FontWeight.w800`), label descriptivo. Los separadores verticales (`_statDivider`) dividen las 4 columnas.

### 7.3 Pestaña 2 — Bienestar (`_BienestarTab`)

`ListView` con 3 secciones en cards. **Todos los campos del onboarding ahora son editables desde el perfil.**

#### 7.3.1 Perfil físico (9 campos editables)

| Campo | Widget de edición | Rango | Persistencia |
|-------|-------------------|-------|-------------|
| **Peso (kg)** | `AlertDialog` con `TextField` numérico decimal | 30–250 kg | `_guardar({'peso_kg': v, 'altura_cm': p.alturaCm})` |
| **Altura (cm)** | `AlertDialog` con `TextField` numérico decimal | 120–230 cm | `_guardar({'altura_cm': v, 'peso_kg': p.pesoKg})` |
| **IMC** | Solo lectura | Calculado automáticamente | `p.imc.toStringAsFixed(1) · p.imcCategoria` |
| **Sexo** | `SimpleDialog` con radio buttons | `masculino`, `femenino`, `prefiero_no_decirlo` | `_guardar({'sexo': result})` |
| **Edad** | `AlertDialog` con `TextField` numérico entero | 1–120 años | `_guardar({'edad': edad})` |
| **Objetivo principal** | `SimpleDialog` con radio buttons | `fitness_general`, `perder_peso`, `ganar_masa`, `fuerza`, `resistencia`, `movilidad` | `_guardar({'objetivo_principal': result})` |
| **Nivel de actividad** | `SimpleDialog` con radio buttons | `sedentario`, `ligero`, `moderado`, `alto` | `_guardar({'nivel_actividad': result})` |
| **Días/semana** | `AlertDialog` con `TextField` numérico entero | 1–7 | `_guardar({'dias_disponibles_semana': val})` |
| **Minutos/sesión** | `AlertDialog` con `TextField` numérico entero | 10–180 | `_guardar({'minutos_por_sesion': val})` |

Todos los valores muestran `'—'` si son 0 o no existen. Cada fila editable muestra `Icons.edit` a la derecha con `InkWell`.

#### 7.3.2 Equipamiento

- Muestra chips configurados con `Wrap` (fondo `#006E2D` al 8%, texto verde oscuro 12px bold)
- Si no hay equipamiento: texto "Sin equipamiento configurado"
- Botón `OutlinedButton.icon` "Configurar equipamiento" → `_editarEquipamiento()`: diálogo con `StatefulBuilder` + `FilterChip` multi-selección de 8 opciones: `peso_corporal`, `mancuernas`, `barra`, `banda_elastica`, `kettlebell`, `polea`, `maquina`, `medicina_ball`

#### 7.3.3 Evolución de peso

- Lista de últimos 5 registros desde `historial_peso` (orden `registrado_en DESC`)
- Formato: `día/mes/año` → `X kg · IMC Y`
- Si vacío: "Sin registros aún"

### 7.4 Pestaña 3 — Ajustes (`_AjustesTab`)

`ConsumerWidget` con `ListView`:

| Elemento | Descripción | Acción |
|----------|-------------|--------|
| **Visibilidad del perfil** | `ListTile` con icono `visibility_rounded`. Subtítulo: "Privado · Solo tus amigos pueden ver tus rutinas" | `onTap: () {}` (placeholder) |
| **Notificaciones** | `ListTile` con icono `notifications_rounded`. Subtítulo: "Modo: X · Y/día" desde `PrefsNotificacionDb` | `context.push('/notificaciones')` |
| **Modo silencio** | `ListTile` con icono `dark_mode_rounded`. Subtítulo: horario desde `PrefsNotificacionDb` | `onTap: () {}` (placeholder) |
| **Carreras universitarias** | `_CarrerasCard` (`ConsumerWidget`): muestra count + botón "Gestionar carreras" → `/academico/configuracion`. Se oculta si `usuarioCarrerasProvider` está vacío | `context.push('/academico/configuracion')` |
| **Cerrar sesión** | `OutlinedButton.icon` rojo (`#EF4444`) con borde `#3B1C1C`, altura 44px | `authController.logout()` → `context.go('/acceso')` |

### 7.5 Flujo de carga y datos (v3.2 — Caché con invalidación selectiva)

```mermaid
flowchart TD
    A["build() → ref.watch(perfilUsuarioProvider)"] --> B["2 queries: usuarios + perfil_bienestar_usuario"]
    A2["build() → ref.watch(perfilActividadProvider)"] --> C["3 queries en paralelo: sesiones + calorías + retos"]
    A3["build() → ref.watch(perfilPreferenciasProvider)"] --> D["1 query: preferencias_notificacion"]
    A4["build() → ref.watch(perfilBienestarCompletoProvider)"] --> E["2 queries: perfil + historial_peso"]
    B --> F["UI se renderiza con datos cacheados"]
    C --> F
    D --> F
    E --> F
    G["Cambio de nombre"] --> H["_onPerfilActualizado(PerfilCambio.nombre)"]
    H --> I["ref.invalidate(perfilUsuarioProvider) ONLY"]
    I --> B
    J["Cambio en bienestar"] --> K["_onPerfilActualizado(PerfilCambio.bienestar)"]
    K --> L["Invalida 2-3 providers específicos"]
    L --> B
    L --> E
```

**Arquitectura de providers:**

| Provider | Queries | Invalida con | Tiempo estimado |
|----------|---------|-------------|-----------------|
| `perfilUsuarioProvider` | 2 (usuarios + perfil_bienestar) | `PerfilCambio.nombre` | ~200ms |
| `perfilActividadProvider` | 3 (paralelas con `Future.wait`) | `PerfilCambio.todo` | ~200ms |
| `perfilPreferenciasProvider` | 1 | `PerfilCambio.preferencias` | ~100ms |
| `perfilBienestarCompletoProvider` | 2 | `PerfilCambio.bienestar` | ~200ms |

- Sin `autoDispose` → datos permanecen en memoria tras primera carga.
- La UI se actualiza instantáneamente porque cada provider se invalida individualmente.
- Antes (v3.1): cada cambio invalidaba 7 queries secuenciales (~800ms).
- Ahora (v3.2): cambio de nombre → 2 queries (~200ms). Cambio de bienestar → ~3 queries (~250ms).

### 7.6 Sincronización

- `_onPerfilActualizado(cambio: PerfilCambio)` recibe el tipo de cambio para invalidación selectiva.
- `BienestarRepository.actualizarPerfilParcial(data)` persiste cambios parciales en `perfil_bienestar_usuario`.
- Avatar: `Image.network` con `loadingBuilder` (muestra inicial durante carga) y `errorBuilder` (fallback a inicial estilizada).
- El nombre se lee de `usuarios.nombre_completo` (tabla pública), no de `perfil_bienestar_usuario`.
- `_TabBarDelegate` (`SliverPersistentHeaderDelegate`) mantiene el `TabBar` fijado al hacer scroll.

### 7.7 Plan de estudios (sección académica en PerfilScreen)

Widget `_PlanEstudiosView` (StatefulWidget con providers) que se muestra como vista adicional dentro del perfil. Contiene:

#### 7.7.1 Cabecera — Institución y semestre actual

- **Card de institución** (`_buildInstitucionCard`): gradiente sutil, icono `school`, nombre de universidad (editable) y carrera.
- **"Curso X · Y° Semestre"** — texto estático que refleja `perfilAcademicoProvider.cursoActual` y `perfilAcademicoProvider.semestreEnCurso`.

#### 7.7.2 Plan de estudios — Cards de curso

Una fila (`Row`) con tarjetas por cada curso disponible, usando `_buildCursoCards()`:

```
┌─────────┐ ┌─────────┐ ┌─────────┐
│  1°     │ │  2°     │ │  3°     │
│  Curso  │ │  Curso  │ │  Curso  │
│ 5 asig. │ │ 6+1 asig│ │ 7 asig. │
└─────────┘ └─────────┘ └─────────┘
```

- Cada card muestra el número de curso, label "Curso", y contador de asignaturas.
- **Contador en tiempo real**: si hay transversales mapeadas (`asignaturasUsuarioSemestreProvider`), se muestra como "5+1 asig." donde el `+1` son las transversales mapeadas a ese curso.
- El contador usa color `tertiary` si hay transversales, `primary` si no.
- Tap en cada card abre `_showCursoBottomSheet()`: `DraggableScrollableSheet` con `DefaultTabController` (un tab por semestre) mostrando asignaturas del curso filtradas por semestre, con `_buildCursoSubjectRow()`.

#### 7.7.3 Asignaturas transversales (colapsable)

Sección `ExpansionTile` con título "Asignaturas transversales" + badge con conteo. Visible solo si `asignaturasSinSemestreProvider` tiene datos.

Cada fila (`_buildSinSemestreRow`) muestra:
- Icono `menu_book_outlined`
- Nombre de la asignatura
- Badge de créditos (ej: "6 ECTS")
- Badge de estado de mapeo: "Curso 2 · 1° Sem" (si ya mapeada) o "Sin asignar" (si no)
- **Botón +** (si no mapeada): agrega la asignatura al curso y semestre actual del usuario (`INSERT` en `asignaturas_usuario_semestre` con `cursoActual` y `semestreEnCurso`). Invalida `asignaturasUsuarioSemestreProvider` tras la inserción.
- **Botón ✕** (si ya mapeada): elimina el mapeo (`DELETE` de `asignaturas_usuario_semestre`). Invalida `asignaturasUsuarioSemestreProvider`.

#### 7.7.4 Curso y Semestre — Edición

Después de la sección de transversales, se muestran filas editables:

| Campo | Widget | Comportamiento |
|-------|--------|---------------|
| **Curso** | `_editTile` read-only | Muestra `p.cursoActual`. Al hacer tap abre `_seleccionarCurso()`: `SimpleDialog` con `RadioGroup<int>` de 1 hasta `maxCurso` (derivado del catálogo de asignaturas). |
| **Semestre** | `_editTile` editable | Muestra `p.semestreEnCurso°`. Al hacer tap abre `_seleccionarSemestre()`: `SimpleDialog` con `RadioGroup<int>` de solo `[1, 2]` (1° o 2° semestre). |
| **Créditos del semestre** | `_readTile` (solo lectura) | Calculados desde `asignaturas_catalogo` filtrando por curso+semestre actual + transversales mapeadas al mismo curso+semestre. Fallback: `p.creditosSemestreActual`. Formato: "60 ECTS" |
| **Horas estimadas / sem** | `_readTile` (solo lectura) | Mismo cálculo que créditos pero para horas. Fallback: `p.horasObjetivoEstudioSemana`. Formato: "150h" |
| **Promedio objetivo** | `_editTile` editable | Decimal editable (0-5) vía `_editarNumeroDecimal()`. Persiste en `perfil_academico_usuario`. |

#### 7.7.5 Cálculo de créditos y horas

```dart
// En la build de _PlanEstudiosView:
int creditosCalculados = 0;
int horasCalculadas = 0;
// 1. Asignaturas del catálogo filtradas por cursoActual + semestreEnCurso
for (final entry in carreraData) {
  for (final s in entry.subjects) {
    if (s.curso == p.cursoActual && s.semestre == p.semestreEnCurso) {
      creditosCalculados += (s.creditos ?? 0).round();
      horasCalculadas += (s.horas ?? 0);
    }
  }
}
// 2. Incluir transversales mapeadas al mismo curso+semestre
if (mapeos.isNotEmpty) {
  final mappedIds = mapeos
    .where((m) => m.curso == p.cursoActual && m.semestre == p.semestreEnCurso)
    .map((m) => m.asignaturaId).toSet();
  // Sumar créditos/horas de esas asignaturas
}
```

## 8. Componentes Reutilizables

| Componente | Descripción | Uso |
|-----------|-------------|-----|
| `BottomNavBar` | 5 tabs con glassmorphism, avatar en Perfil | ShellRoute |
| `KpiCard` | Anillo, contador, gráfico | Dashboard |
| `ExerciseCard` | GIF, nombre, grupo muscular, equipamiento | Explorador, Constructor |
| `ChallengeProgressBar` | Lineal, circular | Dashboard, Detalle de Reto |
| `MilestoneCard` | Título, peso, progreso | Crear Reto Complejo, Detalle |
| `NotificationCard` | Ícono, prioridad, acción rápida | Centro de Notificaciones |
| `FeedCard` | Avatar, logro, interacciones | Muro Social |
| `SkeletonLoader` | Shimmer effect | Todas las pantallas con carga |
| `EmptyState` | Ilustración + mensaje | Todos los estados vacíos |
| `SemanaBadge` | Chip coloreado con tipo de semana | RutinaDetalleScreen |
| `FatigaBanner` | Banner naranja de advertencia | Pre-sesión |
| `FinalidadBadge` | Chip coloreado con finalidad del ejercicio (naranja=fuerza, teal=cardio, índigo=isométrico) | NuevaRutinaScreen, RutinaDetalleScreen |
| `_MiniGifPreview` | Miniatura de GIF de ejercicio (42-48px). Tap abre diálogo a tamaño completo (280px). | Buscador de ejercicios, tarjeta de ejercicio compacta |
| `MetricGauge` | **NUEVO v5.0** — CustomPainter con arco animado 1200ms, punto brillante en el extremo, color dinámico rojo→naranja→amarillo→verde→teal según valor 0-100, alertas contextuales. | Dashboard: sección "Estado Actual" (Energético, Adherencia Académica, Estudio) |

### 8.0 Widget `MetricGauge` (NUEVO v5.0)

**Archivo:** `app/lib/shared/widgets/metric_gauge.dart` (~248 líneas)

Gauge radial animado usado en la sección "Estado Actual" del dashboard para visualizar métricas 0-100:

```dart
class MetricGauge extends StatefulWidget {
  final double value;        // 0-100
  final String label;        // "Energético", "Adherencia", "Estudio"
  final String? subtitle;    // "Académica", "25/30h"
  final String? alert;       // "Descanso recomendado", "Necesita atención"
  final double size;         // 110-130px
}
```

**Características visuales:**
- Arco de 270° con `CustomPainter` (`_GaugePainter`)
- Animación `easeOutCubic` de 1200ms en carga inicial
- Re-animación cuando cambia `value` (transición suave entre valores)
- Punto brillante (círculo 5px) en el extremo del arco
- Color dinámico por umbrales: `<30` rojo, `<50` naranja, `<70` amarillo, `<85` verde, `≥85` teal
- Valor numérico central grande (`fontSize: 28-32`, `FontWeight.w700`)
- Sufijo `/100` debajo del valor
- Chip de alerta contextual con color de fondo semitransparente

**Uso en el dashboard** (`app/lib/features/dashboard/presentation/dashboard_screen.dart:156-279`):

```dart
MetricGauge(
  value: energia,                    // desde estadoEnergeticoProvider
  label: 'Energético',
  alert: energia < 30 ? 'Descanso recomendado' : null,
  size: 130,
),
MetricGauge(
  value: adherencia,                 // desde adherenciaAcademicaProvider
  label: 'Adherencia',
  subtitle: 'Académica',
  alert: adherencia < 40 ? 'Necesita atención' : null,
  size: 130,
),
MetricGauge(
  value: estudioPct,                 // calculado de cargaAcademicaSemanalProvider
  label: 'Estudio',
  subtitle: '${horasReales}/${horasPlaneadas}h',
  size: 130,
),
```

### 8.0.1 Dashboard — Sección "Estado Actual" (NUEVA v5.0) + Limpieza de KPIs (v5.2)

[OBSOLETO v6.0 — Reemplazado por §9 Dashboard Rediseñado]

**Limpieza de KPIs (v5.2):**

Los siguientes KPIs fueron eliminados del dashboard por ser métricas sin datos reales ("métricas muertas"):
- **KPI "Horas de estudio"** — eliminado (dato no persistido ni calculado correctamente en BD)
- **KPI "Racha actual"** — eliminado (la racha nunca se actualizaba → siempre era 0)
- **Badge 🔥 del `_SaludoCard`** — eliminado (ahora solo muestra nivel + XP con punto de energía)

**KPI "Calorías hoy"** ahora se oculta cuando `calorias == 0` (antes siempre visible con valor 0, mostrando una métrica vacía).

### 8.0.2 Widgets de Métricas de Ejercicio (`exercise_metrics.dart`)

**Archivo:** `app/lib/shared/widgets/exercise_metrics.dart` (~346 líneas)

**`SemantiCalorieChip`:** Chip de calorías con icono de fuego:
- **Modo real:** fondo naranja al 15% con `Icon(Icons.local_fire_department)` y texto `"N kcal"`.
- **Modo estimado:** fondo gris al 12% con texto `"~N kcal (est.)"` para proyecciones.
- Parámetros: `calorias` (double?), `esEstimado` (bool), `dense` (bool para modo compacto).
- Si calorías es null o ≤ 0, no se renderiza (`SizedBox.shrink()`).

**`buildCalorieChip()`:** Función helper que calcula calorías usando `CalorieCalculatorService`:
- Parámetros: `valorMet`, `pesoUsuarioKg`, `duracionSegundos`, `duracionRealSegundos` (opcional), `modalidad`, `esCircuito`, `dense`.
- Si `duracionRealSegundos` está presente, se usa para el cálculo real (chip naranja sólido).
- Si solo hay `duracionSegundos`, se usa como proyección con sufijo `(est.)` (chip gris).
- Usa `CalorieCalculatorService.derivarMet()` para obtener el MET si no se proporciona.
- Delega en `SemantiCalorieChip`.

**`SemanticMicroChip`:** Chip semántico genérico con icono, etiqueta y color contextual.
**`ExerciseMetricsRow`:** Fila de chips semánticos que visualiza métricas de un ejercicio (ya NO muestra duración/distancia/isométrico — estas métricas se movieron a chips independientes).
**`ExerciseMetricCategoria`:** Enum con factory `desdeModalidad()` y `desdeFinalidad()` para clasificar métricas.

**Aplicado en:** `nueva_rutina_screen.dart`, `rutina_detalle_screen.dart`, `sesion_en_vivo_screen.dart`, `rutinas_comunidad_screen.dart`, `detalle_reto_screen.dart`.

### 8.0.3 Servicio de Cálculo Calórico (`CalorieCalculatorService`)

**Archivo:** `app/lib/features/bienestar/infrastructure/calorie_calculator_service.dart` (~116 líneas)

Implementa la fórmula científica estándar del Compendio de Adultos 2024:

```
calorías = valorMet × pesoUsuarioKg × (duracionSegundos / 3600)
```

**Métodos estáticos:**

| Método | Propósito | Parámetros clave |
|--------|-----------|-----------------|
| `calcular()` | Calorías para un bloque de ejercicio | `valorMet`, `pesoUsuarioKg?`, `duracionSegundos` |
| `calcularDescanso()` | Calorías en descanso (MET 1.5) | `pesoUsuarioKg?`, `duracionSegundos` |
| `calcularTotal()` | Gasto calórico de lista de bloques con descansos | `pesoUsuarioKg?`, `bloques: List<Map>` |
| `derivarMet()` | Obtiene MET desde catálogo o deriva por modalidad | `valorMet?`, `modalidad`, `esCircuito` |
| `redondear()` | Convierte a entero para UI | `calorias` (double) |

**Valores MET por defecto (derivados):**

| Modalidad | MET | Uso típico |
|-----------|-----|-----------|
| `movilidad` | 2.3 | Flexibilidad, yoga, estiramientos |
| `fuerza` (default) | 6.0 | Ejercicios de fuerza general |
| `metabolica` | 8.0 | Circuitos, HIIT, cross-training |
| `aerobica` | 8.3 | Cardio, running, cycling |
| Circuito (`esCircuito`) | 8.0 | Anula la modalidad |

**Fallback de peso:** Si `pesoUsuarioKg` es null o ≤ 0, se usa 70.0 kg con warning en consola (sin bloquear la UI).

**Grid de KPIs dinámico** (`_buildKpiGrid` en `dashboard_screen.dart:312`):
- `crossAxisCount` ahora es `children.length.clamp(1, 2)` en vez de un valor fijo
- Cuando solo queda "Sesiones completadas" (calorías = 0), el grid muestra 1 columna
- Cuando hay 2 KPIs (calorías > 0 + sesiones), el grid muestra 2 columnas
- `_buildKpiColumn` refactorizado de arrow function a método con cuerpo para legibilidad

**Indicador de energía en SaludoCard:**
- Punto de color (🟢 verde, 🟡 amarillo, 🟠 naranja, 🔴 rojo) junto al nivel/XP
- Basado en `estadoEnergeticoProvider`: `<30` rojo, `<50` naranja, `<70` amarillo, `≥70` verde
- **v5.2:** Badge de racha (🔥) eliminado. Solo se muestra nivel + XP con punto de energía.

### 8.1 Enum `FinalidadEjercicio`

**Archivo:** `app/lib/shared/models/db_models.dart:96-137`

```dart
enum FinalidadEjercicio {
  fuerza,      // Pesas, reps, descanso — naranja
  cardio,      // Duración, distancia — teal
  isometrico;  // Tiempo de sujeción — índigo

  static FinalidadEjercicio fromString(String value);  // desde BD
  String get etiqueta;  // 'Fuerza', 'Cardio', 'Isométrico'
  String get icono;     // '🏋️', '🏃', '🧘'
}
```

El enum se usa en:
- `EjercicioDb.finalidad` — campo del modelo, leído desde la columna `finalidad` en BD
- `_EjercicioCompacto._finalidadChip()` — badge de color + icono + etiqueta
- `_EjercicioCompacto._buildCamposDinamicos()` — switch para renderizar campos específicos
- `RecomendacionIaService` — prompts de IA incluyen reglas por finalidad

### 8.2 Widget `_EjercicioCompacto` (Campos Dinámicos por Finalidad)

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart:1748-2067`

Cada tarjeta de ejercicio en el Paso 2 (Editor de estructura) ahora muestra campos diferentes según la `finalidad` del ejercicio, mediante un `switch` en `_buildCamposDinamicos()`:

```
┌─ Fuerza (naranja 🏋️) ──────────────────────────────┐
│  [Series: 3] [Reps: 10]                            │
│  [Descanso: 90s]   [Peso: — kg]                    │
└────────────────────────────────────────────────────┘

┌─ Cardio (teal 🏃) ─────────────────────────────────┐
│  [Intervalos: 5]   [Duración: 5m 30s]              │
│  [Distancia: — m]  [Descanso: 60s]                 │
└────────────────────────────────────────────────────┘

┌─ Isométrico (índigo 🧘) ───────────────────────────┐
│  [Series: 3]  [Sujeción: 45s]                      │
│  [Descanso: 60s]                                   │
└────────────────────────────────────────────────────┘
```

**Campos por finalidad:**

| Finalidad | Campos | Widget |
|-----------|--------|--------|
| `fuerza` | Series, Reps, Descanso, Peso(kg) | `_paramPill` steppers ± y `_pesoPill` (TextField decimal) |
| `cardio` | Intervalos (=series), Duración, Distancia (opc), Descanso | `_paramPill`, `_duracionPill` (input libre tipo "5m 30s" → parseado a segundos), `_distanciaPill` |
| `isometrico` | Series, Tiempo de sujeción (s), Descanso | `_paramPill`, `_tiempoIsometricoPill` (TextField numérico) |

**Nuevo: Pesos por serie con toggle:** El widget `_EjercicioCompacto` en `nueva_rutina_screen.dart` también incorpora el sistema de pesos por serie:
- Estado local `_pesosKg` (`List<double>`), `_mismoPeso` (`bool`).
- Toggle "Mismo peso en todas las series" en el editor.
- Cuando se desactiva, aparecen `N` campos de peso por serie con steppers ±1.0kg/±0.5kg.
- Al cambiar el número de series, `_pesosKg` se redimensiona: añade el último valor si crece, o recorta si se reduce.
- Serialización: si `_mismoPeso == true` → no se envía `pesos_kg` al INSERT. Si `false` → se envía `pesos_kg: _pesosKg`.
- `EjercicioInput.pesosKg` (`List<double>?`) transporta los pesos por serie desde `_EjercicioCompacto` hasta `crearRutinaCompleta()`.

**Parser de duración libre (`_parseDuracion()`):** Acepta formatos como `"5m 30s"`, `"5:30"`, `"300"` (segundos puros), `"5 min"`, `"5m"`. Se almacena en segundos en `duracionSegundos`.

### 8.3 Widget `_MiniGifPreview`

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart:1544-1623`

Muestra una miniatura del GIF del ejercicio con tamaño configurable:

| Ubicación | Tamaño | Comportamiento |
|-----------|--------|---------------|
| Buscador de ejercicios (`_BuscadorEjerciciosSheet`) | 48px | Tap → diálogo 280px con GIF a tamaño completo |
| Tarjeta de ejercicio compacta (`_EjercicioCompacto`) | 42px | Tap → mismo diálogo ampliado |

Usa `CachedNetworkImage` con `placeholder` (icono de imagen) y `errorWidget` (icono de pesa). El diálogo de vista ampliada tiene fondo negro semitransparente, borde redondeado 20px, y botón de cierre en la esquina superior derecha.

### 8.4 Pantalla de Resumen de Rutina (`_buildPaso3`) — Enriquecida

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart`

El Paso 3 (revisión antes de guardar) fue enriquecido con visualización avanzada de metadatos, periodización y parámetros dinámicos:

#### 8.4.1 Corrección de Bug — `Expanded` en Filas

**Problema:** Los `Row` con `_resumenFila` causaban `RenderFlex` con `BoxConstraints(unconstrained)` cuando los hijos no tenían restricciones explícitas.

**Solución:** Todos los hijos de `Row` en el resumen ahora se envuelven en `Expanded` para garantizar que cada columna reciba restricciones de ancho del padre:

```dart
Row(
  children: [
    Expanded(child: _resumenFila('Objetivo', ...)),
    Expanded(child: _resumenFila('Duración', ...)),
  ],
)
```

#### 8.4.2 Visualización de Descripción

El campo `_descCtrl.text` (descripción de la rutina) ahora se muestra en el resumen cuando no está vacío, mediante una card dedicada con icono `description` y fondo sutil.

#### 8.4.3 Chips de Periodización (`tipo_semana`)

Cada semana muestra un chip coloreado indicando su fase de periodización:

| Tipo | Color | Significado |
|------|-------|-------------|
| `adaptacion` | Ámbar | 70% volumen, énfasis en técnica |
| `carga` | Naranja | 85-90% volumen, progresión |
| `pico` | Rojo | Máxima intensidad |
| `descarga` | Teal | 60% volumen, recuperación activa |

**Implementación:** Nuevo helper `_calcularTipoSemana()` en `nueva_rutina_screen.dart` que replica la lógica de `rutina_provider.dart`. El chip se renderiza mediante `_buildTipoSemanaChip()` con `ChoiceChip` estilizado.

#### 8.4.4 Fila de Resumen por Ejercicio (`_buildExerciseSummaryRow`)

Reescrito para mostrar chips informativos por cada ejercicio en el resumen:

| Chip | Condición | Color | Ejemplo |
|------|-----------|-------|---------|
| **Circuito** | `esCircuito == true` | Púrpura | `🔄 Circuito` |
| **Finalidad** | Siempre visible | Variable (ver tabla) | `🏋️ Fuerza` |
| **Modalidad** | Siempre visible | Variable | `⚡ Fuerza` |

**Colores de finalidad** (helper `_colorFinalidad()`):

| Finalidad | Color |
|-----------|-------|
| Hipertrofia | Púrpura |
| Fuerza | Rojo |
| Cardio | Verde |
| Resistencia | Azul |
| Movilidad | Teal |
| Isométrico | Índigo |
| (default) | Gris |

**Modalidades de entrenamiento** (helper `_buildModalidadChip()`):
- Fuerza (rojo), Aeróbica (verde), Metabólica (naranja), Movilidad (teal)

#### 8.4.5 Parámetros de Ejercicio Dinámicos (`_buildParametrosEjercicio`)

Reescrito para usar `tipoMedicion` (array) en lugar de `finalidad` (string único), permitiendo ejercicios con múltiples tipos de medición. Muestra dinámicamente:

| Tipo de Medición | Campos Mostrados | Formato |
|-----------------|-----------------|---------|
| Fuerza / Hipertrofia | Series × Reps | `4×8` |
| Isométrico | Series × Tiempo | `3×45s` |
| Cardio | Duración, Distancia (opcional) | `30 min · 5 km` |
| Todos | Peso (kg), Descanso (s) | `60 kg · 90s` |

**Modo Circuito (`esCircuito == true`):**
- Oculta series × repeticiones
- Muestra solo duración total del circuito
- Chip "Circuito" visible (púrpura)

#### 8.4.6 Helpers Nuevos

| Helper | Propósito |
|--------|-----------|
| `_calcularTipoSemana(int semanaNum, int totalSemanas)` | Asigna tipo de periodización a cada semana |
| `_buildTipoSemanaChip(String tipo)` | Renderiza chip de periodización coloreado |
| `_finalidadBadge(String finalidad)` | Chip coloreado con icono de finalidad |
| `_circuitoChip()` | Chip púrpura "Circuito" con icono `loop` |
| `_buildModalidadChip(String modalidad)` | Chip de modalidad de entrenamiento |
| `_colorFinalidad(String finalidad)` | Devuelve `Color` según finalidad |
| `_fmtDistancia(int metros)` | Formatea distancia: `<1000m` → `"X m"`, `≥1000m` → `"X.X km"` |

#### 8.4.7 Función Top-Level `fmtDuracion(int segundos)`

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart` (top-level)

Extraída para ser compartida entre `_NuevaRutinaScreenState` y `_EjercicioCompactoState`. Convierte segundos a formato legible:

```dart
String fmtDuracion(int segundos) {
  if (segundos < 60) return '$segundos s';
  final min = segundos ~/ 60;
  final sec = segundos % 60;
  if (sec == 0) return '$min min';
  return '${min}m ${sec}s';
}
```

### 8.5 Widget `_EjercicioCompacto` — Modo Circuito

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart`

Cuando `esCircuito == true`, los campos de Series y Reps se ocultan en `_camposFuerza`, mostrando en su lugar un único campo de Duración:

```dart
// En _camposFuerza:
if (widget.esCircuito) {
  // Muestra solo campo de Duración (oculta Series + Reps)
  return _duracionPill(context, ...);
} else {
  // Muestra pills normales de Series, Reps, Descanso, Peso
  return Row(
    children: [
      _paramPill(...), // Series
      _paramPill(...), // Reps
      _paramPill(...), // Descanso
      _pesoField(),    // Peso kg
    ],
  );
}
```

Esta lógica ya existía en versiones anteriores y se verificó su correcto funcionamiento.

## 9. Dashboard Rediseñado (v6.0)

### 9.1 Widgets nuevos

| Widget | Tipo | Provider | Archivo |
|--------|------|----------|---------|
| `SaludoCard` | StatelessWidget | recibe `DashboardData` | `widgets/saludo_card.dart` |
| `SmartBannerCard` | ConsumerWidget | `consejoSmartProvider` | `widgets/smart_banner_card.dart` |
| `QuickActionsRow` | ConsumerWidget | `diaPendienteProvider` | `widgets/quick_actions_row.dart` |
| `PlanWeekBar` | ConsumerWidget | `rutinaActivaSeleccionadaProvider` | `widgets/plan_week_bar.dart` |
| `CognitiveLoadBar` | ConsumerWidget | `cargaCognitivaProvider` | `widgets/cognitive_load_bar.dart` |
| `StreakRow` | StatelessWidget | recibe params | `widgets/streak_badge.dart` |
| `KpiGrid` | StatelessWidget | recibe `DashboardData` | `widgets/kpi_grid.dart` |
| `TimelineSection` | ConsumerStatefulWidget | `timelineHoyProvider` + `retosProvider` | `widgets/timeline_section.dart` |

### 9.1.1 TimelineSection — 3 Tabs (NUEVO v6.2)

**Archivo:** `app/lib/features/dashboard/presentation/widgets/timeline_section.dart` (454 líneas)
**Modelo:** `app/lib/shared/models/timeline_item.dart` (186 líneas)
**Provider:** `app/lib/features/dashboard/application/timeline_provider.dart` (91 líneas)

La línea de tiempo unificada del dashboard ahora tiene navegación por pestañas con 3 vistas:

```mermaid
flowchart LR
    TS["TimelineSection\nConsumerStatefulWidget"] --> TC["TabController(length: 3)"]
    TC --> T1["Tab: Hoy"]
    TC --> T2["Tab: Semana"]
    TC --> T3["Tab: Retos"]
    
    T1 --> TH["_TabHoy\n• Bloques académicos\n• Sesiones completadas\n• _EntrenamientoPendienteCard"]
    T2 --> TS2["_TabSemana\n• Entregas 7 días\n• Agrupadas cronológicamente"]
    T3 --> TR["_TabRetos\n• Retos activos\n• Progreso + días restantes"]
```

**Estructura del widget:**
- `TabController(length: 3, vsync: this)` con `SingleTickerProviderStateMixin`
- `Card` con header (icono timeline + título + botón "Plan" → `/plan-semanal`)
- `TabBar` con 3 tabs: "Hoy", "Semana", "Retos"
- `TabBarView` con altura fija 280px

**Tab "Hoy" (`_TabHoy`):**
- Consume `timelineHoyProvider` (5 queries en paralelo)
- Separa entrenamiento pendiente (`TimelineTipo.entrenamientoPendiente`) del resto
- Muestra `_EntrenamientoPendienteCard` destacada (naranja, con botón "Comenzar")
- Muestra resto de items con `_TimelineTarjeta` (max 4-5)
- Loading: `CircularProgressIndicator`, Error: texto "Error al cargar", Empty: "Sin actividades hoy"

**Tab "Semana" (`_TabSemana`):**
- Filtra items del `timelineHoyProvider` con `tipo == TimelineTipo.entrega`
- Muestra max 7 entregas con `_TimelineTarjeta`
- Empty: "Sin entregas esta semana"

**Tab "Retos" (`_TabRetos`):**
- Consume `retosProvider` (provider existente del módulo de retos)
- Muestra max 5 retos con `_RetoCard`: título, `LinearProgressIndicator` con %, días restantes
- Color dinámico: `fitness` → verde, resto → púrpura
- Empty: "Sin retos activos"

#### TimelineTipo — 9 valores

| Valor | Color | Ícono | Label | Origen de datos |
|-------|-------|-------|-------|-----------------|
| `estudio` | Azul `#2196F3` | `menu_book` | Estudio | `horarios_academicos` (tipo='estudio') |
| `clase` | Púrpura `#9C27B0` | `school` | Clase | `horarios_academicos` (tipo='clase') |
| `deporte` | Verde `#4CAF50` | `fitness_center` | Deporte | `horarios_academicos` (tipo='deporte') o `sesiones_registradas` |
| `sesion` | Verde `#4CAF50` | `check_circle` | Sesion | `sesiones_registradas` (completada) |
| `entrega` | Rojo `#FF5722` | `assignment_turned_in` | Entrega | `entregas_examenes` (no completadas, 7 días) |
| `reto` | Púrpura `#7C4DFF` | `emoji_events` | Reto | `retos` (activos, no completados) |
| `entrenamientoPendiente` | Naranja `#FF9800` | `fitness_center` | Pendiente | `diaPendienteProvider` |
| `nutricion` | Cyan `#00BCD4` | `restaurant` | Nutricion | FUTURIBLE — sin query |
| `sueno` | Índigo `#3F51B5` | `bedtime` | Sueno | FUTURIBLE — sin query |

#### Nuevos providers de timeline

| Provider | Tipo | Propósito | Fuentes |
|----------|------|-----------|---------|
| `timelineHoyProvider` | `FutureProvider<List<TimelineItem>>` | Línea de tiempo unificada del día con 5 queries en paralelo | `horarios_academicos` (hoy) + `sesiones_registradas` (hoy) + `entregas_examenes` (7d, no completadas) + `retos` (activos) + `diaPendienteProvider` |
| `diaPendienteProvider` | `FutureProvider<Map<String, String>?>` | Primer día no completado de la rutina activa, iterando TODAS las semanas. Retorna `{diaId, rutinaId}` o `null`. Unificado para QuickAction, Timeline y RutinaDetalle. | `dashboardProvider` → `semanasDeRutinaProvider(rutinaId)` → `diasDeSemanaProvider(semanaId)` |

**`timelineHoyProvider` — 5 queries en paralelo:**
```dart
final resultados = await Future.wait([
  // 1. Horarios académicos de hoy
  client.from('horarios_academicos').select()...,
  // 2. Sesiones registradas hoy
  client.from('sesiones_registradas').select()...,
  // 3. Entregas pendientes (7 días, no completadas)
  client.from('entregas_examenes').select()...,
  // 4. Retos activos
  client.from('retos').select()...,
]);
// 5. Día pendiente (vía ref.read, no Future.wait)
final diaPend = ref.read(diaPendienteProvider).valueOrNull;
```

**`diaPendienteProvider` — lógica unificada:**
```dart
final diaPendienteProvider = FutureProvider<Map<String, String>?>((ref) async {
  final data = ref.watch(dashboardProvider).valueOrNull;
  if (data == null || data.rutinasActivas.isEmpty) return null;
  final rutinaId = data.rutinasActivas.first.rutina.id;
  // Itera TODAS las semanas, no solo la primera
  final semanas = await ref.watch(semanasDeRutinaProvider(rutinaId).future);
  for (final semana in semanas) {
    final dias = await ref.watch(diasDeSemanaProvider(semana.id).future);
    for (final dia in dias) {
      if (dia.estado != 'completado') {
        return {'diaId': dia.id, 'rutinaId': rutinaId};
      }
    }
  }
  return null;
});
```

#### TimelineItem — DTO unificado

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `String` | ID único del item |
| `tipo` | `TimelineTipo` | Tipo de actividad (9 valores) |
| `titulo` | `String` | Título principal |
| `subtitulo` | `String` | Subtítulo descriptivo |
| `horaInicio` | `DateTime` | Hora de inicio |
| `horaFin` | `DateTime` | Hora de fin |
| `completado` | `bool` | Si la actividad está completada |
| `datosOriginales` | `Object?` | Referencia al modelo original (HorarioAcademicoDb, SesionRegistradaDb, etc.) |
| `duracionMinutos` | `int?` | Duración en minutos |
| `rpe` | `int?` | RPE de la sesión (si aplica) |
| `diasRestantes` | `int?` | Días hasta el vencimiento (entregas, retos) |
| `rutinaId` | `String?` | ID de la rutina asociada |

**Factory constructors:**
- `TimelineItem.desdeHorario(HorarioAcademicoDb)` — tipo según `tipoActividad`
- `TimelineItem.desdeSesion(SesionRegistradaDb)` — tipo `deporte`, completado=true
- `TimelineItem.desdeEntrega(EntregaExamenDb)` — tipo `entrega`, subtítulo "Vence en X días"
- `TimelineItem.desdeReto(RetoDb)` — tipo `reto`, subtítulo "Quedan X días"
- `TimelineItem.desdeDiaPendiente(Map<String, String>)` — tipo `entrenamientoPendiente`

### 9.2 Funciones compartidas

Extraídas a `app/lib/shared/widgets/dashboard_dialogs.dart`:

- `colorParaScore(double)` — mapea valor a color
- `buildFormulaBar(...)` — barra de fórmula con items
- `buildCalcRow(...)` — fila de cálculo raw/contrib
- `buildGateRow(...)` — fila visual de gate con chips
- `buildStatCard(...)` — tarjeta de estadística
- `mostrarDialogoEnergia(...)` — diálogo de estado energético
- `mostrarDialogoAdherencia(...)` — diálogo de adherencia académica
- `mostrarDialogoEstudio(...)` — diálogo de progreso de estudio

### 9.3 Estados del dashboard

- **Carga:** SmartBanner muestra skeleton shimmer mientras Gemini responde
- **Sin datos:** PlanWeekBar y CognitiveLoadBar se ocultan con `SizedBox.shrink()`
- **Error:** SmartBanner muestra fallback determinista si Gemini falla

## 10. Manejo de Errores

| Código/Situación | Acción del Cliente |
|------------------|-------------------|
| HTTP 400 | Toast con mensaje específico del campo |
| HTTP 401 | Redirigir a pantalla de login |
| HTTP 500 | Retry automático con backoff exponencial |
| Network timeout | Banner "Sin conexión" |
| `GEMINI_API_KEY` no configurada | Error inline en formulario, creación manual habilitada |
| Gemini timeout (15s) | Toast: "No se pudo conectar con Gemini. Inténtalo de nuevo." |
| Gemini JSON malformado | Toast: "Gemini generó una respuesta con formato no válido." |
| Sin ejercicios compatibles | Error inline con lista de equipamiento del usuario |

## 11. Métricas de Rendimiento

| Pantalla | Objetivo | Notas |
|----------|---------|-------|
| Dashboard | < 2s carga inicial | `Future.wait` paraleliza queries |
| Explorador de Ejercicios | < 3s con filtros | Vista materializada `mv_ejercicios_completos` |
| Detalle de Ejercicio | < 1.5s carga GIF R2 | URL pública de R2, sin firma |
| Recomendación IA | < 8s por prompt | Gemini Flash ~2-3s + parsing |
| Interacciones locales | < 300ms | Sin llamadas de red |

## 12. Cobertura de Casos de Uso (v3.0)

| CU ID | Nombre | Pantallas | Estado |
|-------|--------|-----------|--------|
| CU-01 | Registro y autenticación | Bienvenida, Acceso | ✅ |
| CU-02 | Configurar perfil físico | Perfil Físico, Onboarding | ✅ |
| CU-03 | Dashboard | Dashboard | ✅ |
| CU-04 | Planificar semana académica | Plan Académico Semanal | ✅ |
| CU-06 | Crear rutina personal | Explorador, Constructor, NuevaRutinaScreen | ✅ |
| CU-07 | Registrar sesión completada | LiveSessionScreen, Sesión Completada | ✅ |
| CU-10 | Crear reto simple | Crear Reto Simple | ✅ |
| CU-11 | Crear reto complejo | Crear Reto Complejo | ✅ |
| CU-19 | Buscar y seleccionar ejercicios | Explorador, Detalle, Constructor | ✅ |
| **CU-20** | **Crear rutina con recomendación IA** | **NuevaRutinaScreen (3 pasos + IA)** | ✅ |
| **CU-21** | **Check-in diario durante primer descanso** | **LiveSessionScreen → _CheckInOverlay (no bloqueante)** | ✅ |
| **CU-22** | **Crear reto complejo con dependencias** | **CrearRetoComplejoScreen (3 pasos: metadatos, hitos, dependencias)** | ✅ |
| **CU-23** | **Visualizar grafo de dependencias** | **DetalleRetoScreen → GrafoDependencias** | ✅ |

---

## 13. Pantallas de Retos (Sprint 7 — Fase A3)

### 13.1 `DetalleRetoScreen` — Integración del Grafo de Dependencias

**Archivo:** `app/lib/features/retos/presentation/detalle_reto_screen.dart`
**Ruta:** `/retos/:id`

Cuando un reto tiene `tiene_dependencias = true`, la pantalla de detalle ahora incluye el widget `GrafoDependencias` entre la cabecera y la lista de hitos. El grafo se construye desde el provider `grafoRetoProvider(retoId)`:

```dart
// En detalle_reto_screen.dart, dentro del build():
if (reto.tieneDependencias) ...[
  const SizedBox(height: 12),
  Consumer(
    builder: (context, ref, _) {
      final grafoAsync = ref.watch(grafoRetoProvider(retoId));
      return grafoAsync.when(
        data: (grafo) => GrafoDependencias(grafo: grafo),
        loading: () => const _SkeletonGrafo(),
        error: (e, _) => _ErrorGrafoCard(error: e.toString()),
      );
    },
  ),
  const SizedBox(height: 12),
],
```

### 13.2 `CrearRetoComplejoScreen` — 3 Pasos

**Archivo:** `app/lib/features/retos/presentation/crear_reto_complejo_screen.dart`
**Ruta:** `/retos/complejo`

El flujo de creación de retos complejos se ha ampliado a 3 pasos:

| Paso | Nombre | Contenido |
|------|--------|-----------|
| 1 | Metadatos | Título, tipo (fitness/academic), meta, fechas, visibilidad |
| 2 | Hitos | Lista de hitos con título, porcentaje de peso, orden. Añadir/eliminar hitos dinámicamente |
| 3 | Dependencias | Configuración de dependencias entre hitos: seleccionar dependencias (checkboxes), tipo de condición (AND/OR/X_OF_Y), valor N para X_OF_Y |

### 13.3 Widget `GrafoDependencias`

**Archivo:** `app/lib/features/retos/presentation/widgets/grafo_dependencias.dart` (~233 líneas)

Widget que visualiza el grafo de dependencias de los hitos de un reto como un `Card` con layout estratificado por profundidad:

```
┌─────────────────────────────────────────────────┐
│ 🔗 Dependencias                    Leyenda      │
│                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Hito 1  │    │  Hito 2  │    │  Hito 3  │  │
│  │  20% ✅  │    │  30% 🔒  │    │  50% 🔒  │  │
│  └────┬─────┘    └────┬─────┘    └──────────┘  │
│       │ AND           │ OR                      │
│       └──────┬────────┘                         │
│              ▼                                   │
│  ┌──────────────────────┐                       │
│  │       Hito 4         │                       │
│  │       50% 🔒         │                       │
│  │  Cond: X OF Y (1/2)  │                       │
│  └──────────────────────┘                       │
└─────────────────────────────────────────────────┘
```

**Colores por estado:**

| Estado | Color de fondo | Color de borde | Icono |
|--------|---------------|----------------|-------|
| `bloqueado` | `surfaceContainerHighest` | `grey.shade300` | `lock_rounded` |
| `disponible` | `blue.withValues(alpha: 0.15)` | `blue` | `radio_button_unchecked` |
| `enProgreso` | `orange.withValues(alpha: 0.15)` | `orange` | `play_circle_rounded` |
| `completado` | `green.withValues(alpha: 0.15)` | `green` | `check_circle_rounded` |

**Leyenda de condiciones en aristas:**

| Condición | Label |
|-----------|-------|
| `AND` | "Requiere todas" |
| `OR` | "Requiere 1" |
| `X_OF_Y` | "Requiere N de Y" |

### 13.4 Widget `_NodoHitoCard`

**Archivo:** `app/lib/features/retos/presentation/widgets/grafo_dependencias.dart` (widget privado)

Tarjeta individual que representa un hito dentro del grafo:

- **Icono de estado** (22px a la izquierda): coloreado según `EstadoHito`
- **Título del hito** con peso porcentual (`"Hito 1 — 20%"`)
- **Barra de progreso** (`LinearProgressIndicator`) con el progreso actual del hito
- **Chip de condición de desbloqueo**: visible solo si el hito está bloqueado y tiene dependencias. Muestra el tipo de condición y el progreso actual (ej: "AND (1/2)")
- **Indicador visual**: borde coloreado según estado, opacidad reducida para hitos bloqueados

### 13.5 Providers del Módulo de Retos (Sprint 7)

| Provider | Tipo | Propósito | Fuente |
|----------|------|-----------|--------|
| `grafoRetoProvider` | `FutureProvider.family<GrafoReto?, String>` | Construye el grafo de dependencias desde `hitos_de_reto`. Usa `RetoDependenciaService` para construir nodos, aristas, detección de ciclos (DFS) y asignación de profundidad | `hitos_de_reto` WHERE `reto_id` |
| `retoDependenciaServiceProvider` | `Provider<RetoDependenciaService>` | Servicio de construcción y validación de grafos de dependencias | — |

---

## 14. Sincronización Offline (Sprint 7 — Fase C1)

### 14.1 Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     UI Layer (Riverpod)                      │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ OfflineIndicator│  │ SyncButton   │  │ ColaBadge     │  │
│  │ Widget          │  │ Widget       │  │ (pendientes)  │  │
│  └────────┬────────┘  └──────┬───────┘  └───────┬───────┘  │
│           │                  │                   │           │
├───────────┼──────────────────┼───────────────────┼───────────┤
│           ▼                  ▼                   ▼           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           sync_provider.dart (Providers)              │    │
│  │  connectivityStateProvider  ── Stream<State>         │    │
│  │  offlineQueueLengthProvider ── int (cola Hive)       │    │
│  │  syncProgressProvider       ── double (0.0-1.0)     │    │
│  │  sincronizarColaOffline()   ── Future<void>          │    │
│  └──────────┬───────────────────────────────────────────┘    │
│             │                                                 │
├─────────────┼─────────────────────────────────────────────────┤
│             ▼                                                 │
│  ┌──────────────────────┐  ┌────────────────────────┐       │
│  │ ConnectivityService  │  │ OfflineQueueService    │       │
│  │ connectivity_plus    │  │ Hive box: offline_queue│       │
│  │ Stream<State>        │  │ encolar()/procesarCola()│       │
│  └──────────────────────┘  └────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### 14.2 Servicios

#### `ConnectivityService`
**Archivo:** `app/lib/features/sync/infrastructure/connectivity_service.dart` (35 líneas)

- Usa `connectivity_plus ^6.1.0` para monitorear conectividad
- `Stream<ConnectivityState> onStateChange` — emite cambios de conectividad en tiempo real
- `Future<ConnectivityState> checkNow()` — verificación puntual del estado actual
- `Future<bool> isOnline` — conveniencia booleana
- Enum `ConnectivityState`: `online`, `offline`, `syncing`

#### `OfflineQueueService`
**Archivo:** `app/lib/features/sync/infrastructure/offline_queue_service.dart` (116 líneas)

- **Cola Hive:** box `offline_queue` inicializada en `main.dart`
- **Operaciones soportadas:** `INSERT`, `UPDATE`, `DELETE`
- **DTO `OperacionPendiente`:** `id`, `tabla`, `operacion`, `datos` (JSON), `creadoEn`, `identificador` (opcional, para UPDATE/DELETE), `reintentos` (máx 3)
- **`encolar({tabla, operacion, datos, identificador?})`:** añade operación al final de la cola
- **`procesarCola()`:** recorre la cola secuencialmente, ejecutando cada operación contra Supabase. Si una operación falla, incrementa `reintentos` y continúa con la siguiente. Operaciones con `reintentos >= maxReintentos` se descartan
- **`longitud`:** cantidad de operaciones pendientes

### 14.3 Providers

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `connectivityServiceProvider` | `Provider<ConnectivityService>` | Instancia única del servicio de conectividad |
| `connectivityStateProvider` | `StreamProvider<ConnectivityState>` | Stream del estado de conectividad (online/offline/syncing) |
| `offlineQueueServiceProvider` | `Provider<OfflineQueueService>` | Instancia única de la cola offline |
| `offlineQueueLengthProvider` | `Provider<int>` | Longitud actual de la cola (pendientes) |
| `syncProgressProvider` | `StateProvider<double>` | Progreso de sincronización (0.0 → 1.0) |

### 14.4 Flujo de Sincronización

1. **Sin conexión** → la UI muestra `OfflineIndicator` (banner naranja). Las mutaciones se encolan en Hive.
2. **Reconexión** → `connectivityStateProvider` emite `ConnectivityState.online`. La UI llama a `sincronizarColaOffline(ref)`.
3. **Sincronización** → `syncProgressProvider` se actualiza mientras `OfflineQueueService.procesarCola()` recorre la cola.
4. **Completado** → `syncProgressProvider = 1.0`. La UI muestra confirmación y los providers afectados se invalidan.

### 14.5 DTO `OperacionPendiente`

**Archivo:** `app/lib/features/sync/domain/operacion_pendiente_dto.dart` (21 líneas)

```dart
class OperacionPendiente {
  final String id;
  final String tabla;           // tabla Supabase destino
  final String operacion;       // 'INSERT' | 'UPDATE' | 'DELETE'
  final Map<String, dynamic> datos;  // payload de la operación
  final DateTime creadoEn;
  final String? identificador;  // ID del registro (para UPDATE/DELETE)
  final int reintentos;         // intentos fallidos

  static const maxReintentos = 3;
}
```

---

## 15. Analítica Avanzada (Sprint 7B)

### 15.1 Arquitectura

El módulo de analítica proporciona visualización de tendencias de rendimiento del usuario mediante gráficos interactivos (`fl_chart`) y generación de insights interpretativos en español.

```
┌─────────────────────────────────────────────────────────────┐
│                   AnaliticaScreen                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  SegmentedButton: Semanal | Mensual | Trimestral   │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌──────────────────┐ ┌──────────────────┐                │
│  │ RPE Promedio     │ │ Volumen Total    │                │
│  │      7.2         │ │    320 min       │                │
│  └──────────────────┘ └──────────────────┘                │
│  ┌──────────────────┐ ┌──────────────────┐                │
│  │ Días Entrenados  │ │ Consistencia %   │                │
│  │      4/7         │ │      85%         │                │
│  └──────────────────┘ └──────────────────┘                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         TendenciaRpeChart (LineChart)                 │  │
│  │  RPE semanal con línea de tendencia                  │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         VolumenBarChart (BarChart)                    │  │
│  │  Minutos por semana con colores por objetivo         │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │     CorrelacionCargaScatter (ScatterChart)            │  │
│  │  Carga académica (FCT) vs RPE + línea regresión      │  │
│  │  📊 Coeficiente Pearson: r = -0.42                    │  │
│  │  💬 "A mayor carga académica, tiendes a reportar     │  │
│  │      menor esfuerzo en tus entrenamientos"            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 15.2 Pantalla `AnaliticaScreen`

**Archivo:** `app/lib/features/analitica/presentation/analitica_screen.dart`
**Ruta:** `/analitica` (integrada en navegación principal)

- **Selector de periodo:** `SegmentedButton<PeriodoAnalitica>` con 3 opciones: Semanal, Mensual, Trimestral
- **Métricas clave:** 4 tarjetas (`_MetricaCard`) con RPE promedio, volumen total (min), días entrenados, consistencia (%)
- **Charts:** `TendenciaRpeChart` (LineChart), `VolumenBarChart` (BarChart), `CorrelacionCargaScatter` (ScatterChart)
- **Insights:** Frases generadas por `InsightGenerator` desde correlaciones y tendencias

### 15.3 Charts con `fl_chart`

#### `TendenciaRpeChart`
- **Tipo:** `LineChart` de `fl_chart ^0.70.0`
- **Datos:** RPE promedio semanal desde `v_analitica_semanal`
- **Visualización:** Puntos semanales + línea de tendencia (regresión simple)
- **Tooltips:** Al tocar punto: "Semana 12 jun — RPE 7.2"
- **Provider fuente:** `tendenciaRpeProvider`

#### `VolumenBarChart`
- **Tipo:** `BarChart` de `fl_chart`
- **Datos:** Volumen total en minutos por semana desde `v_analitica_semanal`
- **Colores:** Barras coloreadas según objetivo cumplido (verde) o por debajo (naranja)
- **Provider fuente:** `volumenSemanalProvider`

#### `CorrelacionCargaScatter`
- **Tipo:** `ScatterChart` de `fl_chart`
- **Datos:** Eje X = FCT (Factor de Carga Total, 0-100), Eje Y = RPE promedio (1-10)
- **Visualización:** Puntos de dispersión + línea de regresión lineal + coeficiente de Pearson
- **Provider fuente:** `correlacionCargaProvider`
- **InsightGenerator:** Frases interpretativas en español como:
  - `"A mayor carga académica, tiendes a reportar menor esfuerzo en tus entrenamientos"` (correlación negativa)
  - `"Tu rendimiento es consistente independientemente de la carga académica"` (correlación débil)

### 15.4 Providers de Analítica

| Provider | Tipo | Propósito | Fuente |
|----------|------|-----------|--------|
| `analiticaRepositoryProvider` | `Provider<AnaliticaRepository>` | Repositorio que consulta `v_analitica_semanal` + `carga_academica_semanal`, calcula correlación Pearson (~220 líneas) | `v_analitica_semanal` |
| `analiticaSemanalProvider` | `FutureProvider<List<MetricaSemanal>>` | Datos agregados por semana (RPE, volumen, calorías, días) | `v_analitica_semanal` |
| `tendenciaRpeProvider` | `FutureProvider<List<FlSpot>>` | Puntos (semana, RPE) para LineChart | Derivado de `analiticaSemanalProvider` |
| `volumenSemanalProvider` | `FutureProvider<List<BarChartGroupData>>` | Datos de volumen para BarChart | Derivado de `analiticaSemanalProvider` |
| `correlacionCargaProvider` | `FutureProvider<InsightCorrelacion?>` | Correlación Pearson: FCT vs RPE con frases interpretativas | `AnaliticaRepository` |
| `periodoSeleccionadoProvider` | `StateProvider<PeriodoAnalitica>` | Periodo actual seleccionado (semanal/mensual/trimestral) | Estado local |

### 15.5 DTOs

#### `MetricaSemanal`
**Archivo:** `app/lib/features/analitica/domain/metrica_semanal_dto.dart`
- `inicioSemana` (DateTime), `totalSesiones` (int), `rpePromedio` (double)
- `volumenTotalMin` (int), `caloriasTotales` (int), `ejerciciosDistintos` (int)
- `factory fromMap(Map<String, dynamic>)` para datos de `v_analitica_semanal`

#### `InsightCorrelacion`
**Archivo:** `app/lib/features/analitica/domain/insight_correlacion_dto.dart`
- `coeficientePearson` (double), `puntos` (List<Map<String, double>>)
- `fraseInterpretativa` (String) — generada por `InsightGenerator`

#### `PeriodoAnalitica` (enum)
**Archivo:** `app/lib/features/analitica/domain/periodo_analitica.dart`
- Valores: `semanal`, `mensual`, `trimestral`
- Getters: `semanas` (int), `etiqueta` (String)

### 15.6 `InsightGenerator`

**Archivo:** `app/lib/features/analitica/infrastructure/insight_generator.dart`

Generador estático de frases interpretativas en español:
- **Racha:** `"Llevas {n} semanas consecutivas entrenando. ¡Sigue así!"`
- **Consistencia:** `"Tu consistencia es del {pct}%. {recomendacion}"`
- **Volumen:** `"Esta semana acumulaste {min} minutos de entrenamiento"`
- **Correlación:** `"A mayor carga académica, tiendes a reportar {tendencia} esfuerzo"`

### 15.7 `AnaliticaRepository`

**Archivo:** `app/lib/features/analitica/infrastructure/analitica_repository.dart` (~220 líneas)

- `obtenerMetricasSemanales(usuarioId, semanas)` → consulta `v_analitica_semanal`
- `obtenerCorrelacionCarga(usuarioId)` → cruza `v_analitica_semanal` con `carga_academica_semanal`, calcula correlación Pearson
- `obtenerCargaAcademicaSemanal(usuarioId)` → consulta `carga_academica_semanal`

---

---

## 16. Pantalla Pomodoro (Sprint 9A)

**Ruta:** `/pomodoro`
**Archivos:** `features/pomodoro/` con domain/application/presentation/

### 16.1 Arquitectura

```
features/pomodoro/
├── domain/
│   └── pomodoro_session.dart       # DTO con estados de la sesión
├── application/
│   └── pomodoro_provider.dart      # StateNotifier con Timer.periodic
└── presentation/
    ├── pomodoro_screen.dart         # Pantalla principal
    └── widgets/
        └── pomodoro_progress_painter.dart  # Anillo CustomPainter
```

### 16.2 Provider `pomodoroProvider`

**Tipo:** `StateNotifierProvider<PomodoroNotifier, PomodoroState>`
**Archivo:** `app/lib/features/pomodoro/application/pomodoro_provider.dart`

Gestiona el ciclo de temporizador Pomodoro (25 minutos de estudio + 5 minutos de descanso):

| Estado | Descripción |
|--------|-------------|
| `idle` | Sin sesión activa |
| `estudio` | Temporizador de estudio (25 min) en curso |
| `descanso` | Temporizador de descanso (5 min) en curso |
| `pausado` | Sesión pausada manualmente |

**Métodos del notifier:**
- `iniciar()` — inicia temporizador de estudio (25 min)
- `pausar()` — pausa el temporizador actual
- `reanudar()` — reanuda desde donde se pausó
- `reiniciar()` — reinicia desde 25:00
- `saltarDescanso()` — salta al siguiente ciclo de estudio
- `skip()` — finaliza la sesión actual

**Implementación:** `Timer.periodic` con intervalo de 1 segundo. Cada tick decrementa el contador y actualiza el estado.

### 16.3 Pantalla `PomodoroScreen`

**Archivo:** `app/lib/features/pomodoro/presentation/pomodoro_screen.dart`

Pantalla de temporizador con diseño minimalista:

- **Anillo CustomPainter** (`PomodoroProgressPainter`): arco circular que decrece visualmente con el tiempo restante. Color dinámico: azul (estudio), verde (descanso).
- **Tiempo restante** en el centro del anillo (formato `MM:SS`), fuente grande.
- **Etiqueta de fase:** "Estudio" / "Descanso"
- **Controles inferiores:** botones Iniciar, Pausar, Reanudar, Reiniciar, Skip
- **Contador de ciclos:** "Ciclo X completado"

---

## 17. Pantalla Escanear (Sprint 9A)

**Ruta:** `/escanear`
**Archivos:** `features/escanear/` con domain/application/infrastructure/presentation/

### 17.1 Arquitectura

```
features/escanear/
├── domain/
│   └── escanear_result.dart        # DTO con texto escaneado y metadatos
├── application/
│   └── escanear_provider.dart      # Provider del servicio de escaneo
├── infrastructure/
│   └── scanner_service.dart        # Abstracción ScannerService
└── presentation/
    └── escanear_screen.dart         # Pantalla dual Web/Mobile
```

### 17.2 Abstracción `ScannerService`

**Archivo:** `app/lib/features/escanear/infrastructure/scanner_service.dart`

Define la interfaz de escaneo con dos implementaciones condicionales por plataforma:

| Plataforma | Comportamiento |
|-----------|----------------|
| **Web** | Muestra mensaje informativo: "El escaneo con cámara no está disponible en Web. Escribe o pega el texto manualmente." |
| **Mobile (Android/iOS)** | Permite escribir/pegar texto libremente en un `TextField` multilínea |

### 17.3 Pantalla `EscanearScreen`

**Archivo:** `app/lib/features/escanear/presentation/escanear_screen.dart`

Flujo completo de escaneo → guardado como apunte Markdown:

1. **Entrada de texto:** `TextField` multilínea donde el usuario escribe o pega el contenido
2. **Selección de asignatura:** dropdown con las asignaturas del usuario (desde `asignaturasProvider`)
3. **Título opcional:** campo de texto para el título del apunte
4. **Botón "Guardar":** crea un apunte Markdown vinculado a la asignatura seleccionada en `apuntes`
5. **Confirmación:** SnackBar "Apunte guardado correctamente" y navegación de vuelta

---

## 18. Feed Social con Comentarios (Sprint 9C)

**Archivos:** `features/social/` ahora con las 4 capas completas (domain, infrastructure, application, presentation)

### 18.1 Arquitectura

```
features/social/
├── domain/
│   └── social_dto.dart             # DTOs Publicacion y Comentario
├── infrastructure/
│   └── social_repository.dart      # CRUD real: feed, likes, comentarios
├── application/
│   └── social_provider.dart        # 6 providers + mutaciones
└── presentation/
    ├── muro_social_screen.dart      # ConsumerStatefulWidget con filtros
    └── widgets/
        ├── feed_item_card.dart      # Card de publicación con comentarios
        ├── comentario_card.dart     # Card individual de comentario
        └── comentario_input.dart    # Barra de input de comentario
```

### 18.2 Migración: tabla `comentarios_feed`

**Archivo:** `supabase/migrations/20260616_0002_social_moderacion.sql`

- Tabla `comentarios_feed`: `id`, `publicacion_id` (FK → `actividades_sociales`), `usuario_id`, `contenido`, `creado_en`, `editado_en`, `eliminado`
- RLS: autor puede editar/eliminar sus comentarios. Lectura: cualquier usuario autenticado.
- Soft delete con columna `eliminado`.

### 18.3 SocialRepository con CRUD real

**Archivo:** `app/lib/features/social/infrastructure/social_repository.dart`

| Método | Descripción |
|--------|-------------|
| `obtenerFeed(usuarioId, pagina, limite, tipoFiltro)` | Feed paginado con JOINs: `actividades_sociales` + `usuarios` + conteo de likes y comentarios |
| `toggleLike(publicacionId, usuarioId)` | Alterna like: INSERT si no existe, DELETE si existe. Retorna nuevo conteo |
| `obtenerLikeState(publicacionId, usuarioId)` | Verifica si el usuario dio like a una publicación |
| `publicarEnFeed(usuarioId, tipo, contenido)` | INSERT en `actividades_sociales` |
| `obtenerComentarios(publicacionId)` | SELECT con JOIN a `usuarios` para avatar/nombre |
| `enviarComentario(publicacionId, usuarioId, contenido)` | INSERT en `comentarios_feed` |
| `editarComentario(comentarioId, nuevoContenido)` | UPDATE soft |
| `eliminarComentario(comentarioId)` | UPDATE `eliminado = true` |

### 18.4 Providers Riverpod

**Archivo:** `app/lib/features/social/application/social_provider.dart`

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `socialFeedProvider` | `FutureProvider<List<Publicacion>>` | Feed paginado con JOINs (usuarios, conteos, mi_like) |
| `socialCommentsProvider.family` | `FutureProvider.family<List<Comentario>, String>` | Comentarios de una publicación por ID |
| `likeStateProvider.family` | `FutureProvider.family<bool, String>` | Estado de like del usuario para una publicación |

**Mutaciones:**
| Mutación | Descripción |
|----------|-------------|
| `toggleLike(publicacionId, ref)` | Alterna like y revalida `socialFeedProvider` |
| `publicarEnFeed(contenido, tipo, ref)` | Crea publicación y revalida feed |
| `enviarComentario(publicacionId, contenido, ref)` | Inserta comentario y revalida `socialCommentsProvider` |
| `editarComentarioMutation(comentarioId, nuevoContenido, ref)` | Edita comentario y revalida |
| `eliminarComentarioMutation(comentarioId, ref)` | Soft delete y revalida |

### 18.5 Widgets

#### `FeedItemCard`
**Archivo:** `app/lib/features/social/presentation/widgets/feed_item_card.dart`

- Avatar del autor + nombre + tiempo relativo
- Contenido de la publicación con tipo (logro, sesión, reto, etc.)
- Botón de like con animación (`AnimatedScale` + color)
- Conteo de likes y comentarios
- Sección de comentarios expandible: al tocar "X comentarios", se despliega con `socialCommentsProvider`
- `ComentarioInput` integrado al final de la sección expandida

#### `ComentarioCard`
**Archivo:** `app/lib/features/social/presentation/widgets/comentario_card.dart`

- Avatar pequeño + nombre del autor
- Contenido del comentario
- Botones de editar/eliminar visibles solo para el autor del comentario
- Indicador "editado" si `editado_en != null`

#### `ComentarioInput`
**Archivo:** `app/lib/features/social/presentation/widgets/comentario_input.dart`

- `TextField` con validación 1-500 caracteres
- Botón de enviar (deshabilitado si está vacío)
- Teclado optimizado para texto

### 18.6 MuroSocialScreen refactorizado

**Archivo:** `app/lib/features/social/presentation/muro_social_screen.dart`

Convertido a `ConsumerStatefulWidget`:
- **Filtros temporales:** chips Horizontales (3 días, 7 días, 30 días, Todo)
- **RefreshIndicator:** pull-to-refresh en el feed
- **FAB funcional:** abre `BottomSheet` con formulario para crear publicación (contenido + tipo)
- **Integración con retos:** al completar un reto, se publica automáticamente en el feed con tipo `logro`

---

## 19. Insignias y Rachas (Sprint 9D)

**Ruta:** `/insignias`
**Archivos:** `features/insignias/` completo con las 4 capas

### 19.1 Arquitectura

```
features/insignias/
├── domain/
│   └── insignia_dto.dart           # DTOs Insignia y RachaState
├── infrastructure/
│   ├── insignias_repository.dart   # Consulta catálogo + usuario_insignias
│   ├── insignia_engine.dart        # Motor de evaluación (12 criterios)
│   └── racha_service.dart          # Cálculo de rachas diarias
├── application/
│   └── insignias_provider.dart     # 6 providers Riverpod
└── presentation/
    ├── insignias_screen.dart        # Pantalla principal con grid
    └── widgets/
        ├── insignia_card.dart       # Card con color por rareza
        └── racha_indicator.dart     # Widget de racha con progreso
```

### 19.2 Migración: tablas `insignias` + `usuario_insignias`

**Archivo:** `supabase/migrations/20260616_0003_insignias.sql`

- **`insignias` (catálogo público, 15 insignias seed):**

| Categoría | Insignias |
|-----------|-----------|
| 🏋️ Entrenamiento | Primer Entreno, Cien Sesiones, Bestia del Gym, Guerrera de Hierro |
| 🧠 Académico | Estudiante Dedicado, Mente Brillante, Máquina de Apuntes |
| 🎯 Retos | Retador Novato, Maestro de Retos, Imparable |
| 💪 Esfuerzo | Sin Excusas, Consistencia de Acero, Madrugador |
| 🔥 Rachas | Racha Imparable |
| ☑️ Social | Social Butterfly |

- **`usuario_insignias` (M:N):** `usuario_id`, `insignia_id`, `obtenida_en`. UNIQUE constraint previene duplicados.
- **RLS:** catálogo público (lectura), `usuario_insignias` solo propietario.

**Campos de `insignias`:**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID | PK |
| `nombre` | TEXT | Nombre de la insignia |
| `descripcion` | TEXT | Cómo obtenerla |
| `categoria` | TEXT | entrenamiento, academico, retos, esfuerzo, rachas, social |
| `rareza` | TEXT | comun, rara, epica, legendaria |
| `icono` | TEXT | Emoji representativo |
| `color_hex` | TEXT | Color primario en hex |
| `criterio` | TEXT | Criterio de evaluación |

**Colores por rareza:**
| Rareza | Color | Borde |
|--------|-------|-------|
| Común | Gris `#9E9E9E` | Sutil |
| Rara | Azul `#42A5F5` | Brillo leve |
| Épica | Púrpura `#AB47BC` | Glow medio |
| Legendaria | Dorado `#FFD700` | Glow intenso + partículas |

### 19.3 InsigniaEngine (Motor de Evaluación)

**Archivo:** `app/lib/features/insignias/infrastructure/insignia_engine.dart` (~170 líneas)

Evalúa 12 criterios contra la base de datos y otorga insignias automáticamente cuando se cumplen:

| # | Criterio | Consulta | Insignia |
|---|----------|----------|----------|
| 1 | Primera sesión completada | `COUNT sesiones_registradas >= 1` | Primer Entreno |
| 2 | 100 sesiones completadas | `COUNT sesiones_registradas >= 100` | Cien Sesiones |
| 3 | 10 check-ins | `COUNT estado_diario_usuario >= 10` | Sin Excusas |
| 4 | RPE promedio ≥ 8 (últimas 10 sesiones) | `AVG(rpe) >= 8` | Bestia del Gym |
| 5 | 50 sesiones + check-ins | `COUNT >= 50` | Guerrera de Hierro |
| 6 | Racha ≥ 7 días | `racha_actual >= 7` | Racha Imparable |
| 7 | 10+ bloques de estudio | `COUNT horarios_academicos tipo='estudio' >= 10` | Estudiante Dedicado |
| 8 | 5+ apuntes creados | `COUNT apuntes >= 5` | Máquina de Apuntes |
| 9 | 3+ retos completados | `COUNT retos estado='completado' >= 3` | Retador Novato |
| 10 | 10+ retos completados | `COUNT >= 10` | Maestro de Retos |
| 11 | 5+ publicaciones en feed | `COUNT actividades_sociales >= 5` | Social Butterfly |
| 12 | 10+ insignias obtenidas | `COUNT usuario_insignias >= 10` | Imparable |

**Método principal:** `evaluarInsignias(usuarioId, client)` — ejecuta los 12 criterios, compara con las ya obtenidas, e inserta las nuevas vía UNIQUE constraint.

### 19.4 RachaService

**Archivo:** `app/lib/features/insignias/infrastructure/racha_service.dart`

Servicio de cálculo de rachas de actividad diaria:

- **`calcularRacha(usuarioId)`:** consulta `sesiones_registradas` + `estado_diario_usuario` + `horarios_academicos` (estudio). Cuenta días consecutivos hacia atrás desde hoy. Retorna `RachaState`.
- **Detección de riesgo:** si la última actividad fue hace <4 horas, el usuario está en zona de riesgo de perder la racha.
- **Hitos de racha:** 7 días, 30 días, 100 días, 365 días.
- **Mejor racha histórica:** consulta `usuarios.mejor_racha` como récord personal.
- **DTO `RachaState`:** `diasConsecutivos`, `mejorRacha`, `hitosAlcanzados`, `riesgo` (bool), `progreso` (float 0-1 hacia el siguiente hito).

### 19.5 Providers Riverpod

**Archivo:** `app/lib/features/insignias/application/insignias_provider.dart`

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `insigniasRepositoryProvider` | `Provider<InsigniasRepository>` | Instancia única del repositorio |
| `catalogoInsigniasProvider` | `FutureProvider<List<Insignia>>` | Catálogo completo de 15 insignias |
| `insigniasUsuarioProvider` | `FutureProvider<List<Insignia>>` | Insignias obtenidas por el usuario (LEFT JOIN) |
| `insigniasCountProvider` | `Provider<int>` | Conteo: obtenidas/total |
| `rachaStateProvider` | `FutureProvider<RachaState>` | Estado de racha actual del usuario |
| `insigniasRecienObtenidasProvider` | `StateProvider<List<Insignia>>` | Cola de insignias recién obtenidas para mostrar toast |

**Acción `evaluarInsignias(usuarioId, ref)`:**
- Ejecuta `InsigniaEngine.evaluarInsignias(usuarioId, client)`
- Compara resultado con `insigniasUsuarioProvider` para detectar nuevas
- Añade nuevas a `insigniasRecienObtenidasProvider` y muestra toast animado
- Revalida `insigniasUsuarioProvider` y `insigniasCountProvider`

**Integración en rutina_provider y retos_provider:**
- `finalizarSesion()` → al finalizar, llama `evaluarInsignias()`
- `completarReto()` → al completar, llama `evaluarInsignias()`
- Ambas funciones son puntos de entrada del motor de insignias

### 19.6 Widgets

#### `InsigniasScreen`
**Archivo:** `app/lib/features/insignias/presentation/insignias_screen.dart`

`ConsumerStatefulWidget` con:
- **Filtro por categoría:** 6 `FilterChip`s horizontales (Todas, Entrenamiento, Académico, Retos, Esfuerzo, Social)
- **Grid 2 columnas:** `SliverGrid` con `InsigniaCard` para cada insignia
- **Contador:** "X / 15 insignias" en el header
- **Detalle BottomSheet:** al tocar una insignia, muestra nombre, descripción, categoría, rareza y fecha de obtención

#### `InsigniaCard`
**Archivo:** `app/lib/features/insignias/presentation/widgets/insignia_card.dart`

- **Obtenida:** color vibrante según rareza, icono grande, nombre y fecha
- **Bloqueada:** escala de grises, icono de candado, descripción del criterio
- **Animación:** `AnimatedScale` al aparecer en el grid

#### `InsigniaToast` (animación slide-up)
- Se muestra brevemente (3s) cuando se obtiene una nueva insignia
- Animación: slide desde abajo + fade in
- Muestra icono, nombre y rareza de la insignia obtenida
- Auto-descarta tras 3 segundos

#### `RachaIndicator`
**Archivo:** `app/lib/features/insignias/presentation/widgets/racha_indicator.dart`

- **Barra de progreso:** `LinearProgressIndicator` hacia el siguiente hito (7, 30, 100, 365)
- **Contador:** "🔥 X días consecutivos"
- **Alerta de riesgo:** si quedan <4h para perder la racha, fondo rojo + texto "¡No pierdas tu racha!"
- **Récord:** "🏆 Mejor racha: X días"
- **Integrado en:** perfil (sección superior), dashboard (StreakRow)

### 19.7 Integración con Dashboard

- **StreakRow** ahora consume `rachaStateProvider` para mostrar racha real (antes era placeholder)
- **InsigniaToast** se dispara automáticamente desde `insigniasRecienObtenidasProvider` al obtener una nueva insignia
- El toast usa `Overlay` para aparecer sobre cualquier pantalla

---

## 20. Panel de Administración (v6.8 — Fase 3 Final)

**Ruta:** `/admin`
**Archivos:** `features/admin/` con 34 archivos en 4 capas (7 DTOs, 6 repositorios, 6 provider files, 15 widgets/pantallas)

### 20.1 Arquitectura

```
features/admin/
├── domain/
│   ├── admin_dto.dart                      # UsuarioAdmin (existente)
│   ├── admin_kpi_dto.dart                  # AdminMetricasGlobales (10 campos)
│   ├── admin_contenido_dto.dart            # ContenidoReportado
│   ├── admin_auditoria_dto.dart            # AuditoriaRegistro + enum AccionAuditoria
│   ├── admin_ejercicio_dto.dart            # AdminEjercicio (con campo activo)
│   ├── admin_usuario_estadisticas_dto.dart # AdminUsuarioEstadisticas + AdminDataPoint
│   └── admin_timeline_dto.dart             # AdminTimelineEntry + enum TimelineTipoAdmin
├── infrastructure/
│   ├── admin_repository.dart               # listarUsuarios, obtenerDetalle, deleteUser, resetXp, setNivel
│   ├── admin_metricas_repository.dart      # obtenerMetricasGlobales, obtenerRegistrosDiarios
│   ├── admin_auditoria_repository.dart     # insertarAuditoria, consultarLogs
│   ├── admin_contenido_repository.dart     # listarContenidoReportado, aprobarContenido, eliminarContenido
│   ├── admin_ejercicio_repository.dart     # listarEjercicios, toggleActivo
│   └── admin_usuario_stats_repository.dart # obtenerRpeSemanal, obtenerVolumenSemanal, obtenerTimeline
├── application/
│   ├── admin_provider.dart                 # esAdminProvider, adminUsuariosPaginados, adminUsuarioDetalle + mutaciones (eliminarUsuario, editarNombreUsuario, editarEmailUsuario)
│   ├── admin_metricas_provider.dart        # adminMetricasProvider, adminRegistrosDiariosProvider
│   ├── admin_auditoria_provider.dart       # adminAuditoriaProvider, registrarAuditoria
│   ├── admin_contenido_provider.dart       # adminContenidoReportadoProvider + moderarPublicacion, moderarComentario
│   ├── admin_ejercicio_provider.dart       # adminEjerciciosProvider, adminEjercicioToggleProvider
│   └── admin_usuario_stats_provider.dart   # adminUsuarioStatsProvider, adminUsuarioTimelineProvider
└── presentation/
    ├── admin_hub_screen.dart               # Hub principal con TabBar (5 tabs)
    ├── admin_panel_screen.dart             # Pestaña "Usuarios" con búsqueda, filtros, ordenamiento y botón eliminar
    ├── admin_usuario_detalle.dart          # 3 sub-pestañas + configuración de usuario + botón eliminar
    └── widgets/
        ├── admin_kpi_dashboard.dart        # Grid 2×3 KPIs + gráfico tendencia 30 días (fl_chart LineChart)
        ├── admin_kpi_card.dart             # Card individual de KPI
        ├── admin_auditoria_list.dart       # Lista paginada de registros de auditoría
        ├── admin_log_entry.dart            # Fila de log con badge por tipo de acción
        ├── admin_paginacion_bar.dart       # Barra de paginación reutilizable
        ├── admin_wipe_dialog.dart          # Diálogo de confirmación de wipe/delete
        ├── admin_contenido_card.dart       # Card de contenido reportado con aprobar/eliminar
        ├── admin_contenido_list.dart       # Lista paginada de contenido reportado
        ├── admin_ejercicio_card.dart       # Card con Switch activo/inactivo
        ├── admin_ejercicio_list.dart       # Lista paginada de ejercicios con búsqueda
        ├── admin_graficos_usuario.dart     # Gráficos fl_chart (LineChart RPE + BarChart volumen)
        └── admin_timeline_usuario.dart     # Timeline vertical de actividad del usuario
```

### 20.2 AdminHubScreen — Punto de entrada con TabBar

**Archivo:** `app/lib/features/admin/presentation/admin_hub_screen.dart`

`ConsumerStatefulWidget` con `TabController(length: 5)` que reemplaza al antiguo `AdminPanelScreen` como punto de entrada único al panel:

| Tab | Contenido | Widget principal |
|-----|-----------|-----------------|
| **KPIs** | Métricas globales de la plataforma | `AdminKpiDashboard` |
| **Usuarios** | Búsqueda, listado y gestión | `AdminListaUsuarios` (refactor del antiguo `AdminPanelScreen`) |
| **Contenido** | Moderación de publicaciones/comentarios | `AdminContenidoList` |
| **Ejercicios** | Catálogo admin con toggle activo | `AdminEjercicioCard` (lista) |
| **Logs** | Registros de auditoría | `AdminLogEntry` (lista cronológica) |

**Protección de ruta:** La ruta `/admin` en GoRouter verifica `esAdminProvider` antes de renderizar. Si el usuario no es admin, redirige a `/dashboard`.

### 20.3 AdminKpiDashboard — Grid de KPIs + Gráfico de Tendencia

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_kpi_dashboard.dart`

Grid 2×3 de `AdminKpiCard` con 6 métricas principales desde `adminMetricasProvider`:
1. **Total usuarios** — `v_admin_metricas.total_usuarios`
2. **Activos hoy** — `v_admin_metricas.usuarios_activos_hoy`
3. **Sesiones hoy** — `v_admin_metricas.sesiones_hoy`
4. **Rutinas activas** — `v_admin_metricas.rutinas_activas`
5. **Retos activos** — `v_admin_metricas.retos_activos`
6. **Reportado pendiente** — `v_admin_metricas.contenido_reportado_pendiente`

**Gráfico de tendencia 30 días (Fase 3):** Bajo el grid de KPIs, un `LineChart` de `fl_chart` que muestra la tendencia de registros diarios de los últimos 30 días, consumiendo `adminRegistrosDiariosProvider`. Eje X: días, eje Y: cantidad de registros. Tooltips con fecha y valor exacto.

**Estados del provider:**
- `AsyncLoading` → 6 skeletons de cards (shimmer) + skeleton del gráfico
- `AsyncError` → mensaje "Error al cargar métricas" + botón reintentar
- `AsyncData` → grid con valores reales + gráfico de tendencia

### 20.4 AdminKpiCard

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_kpi_card.dart`

Card individual con:
- Icono representativo (person, trending_up, fitness_center, flag, bar_chart, stars)
- Valor numérico destacado (tamaño grande, bold)
- Etiqueta descriptiva
- Color dinámico según tipo de métrica (verde=positivo, ámbar=neutral, azul=info)
- Tendencia (↑/↓) si aplica comparación intermensual

### 20.5 AdminListaUsuarios — Búsqueda, filtros y ordenamiento

**Archivo:** `app/lib/features/admin/presentation/admin_panel_screen.dart` (refactorizado como pestaña "Usuarios")

- **Búsqueda:** `TextField` con debounce 300ms para filtrar por email o nombre
- **Filtros (Fase 3):** chips de filtro por rol (`admin`/`usuario`), estado (activo/inactivo)
- **Ordenamiento (Fase 3):** `PopupMenuButton` con opciones: "Más recientes", "Más antiguos", "Mayor nivel", "Mayor XP"
- **Paginación:** 20 usuarios por página, `AdminPaginacionBar` con botones ← → y contador "Página X de Y"
- **Lista:** `ListView.builder` con cards de usuario mostrando avatar, nombre, email, rol, nivel, racha
- **Acciones por usuario:** `PopupMenuButton` con "Ver detalle" (→ `AdminUsuarioDetalle`), "Cambiar rol", "Eliminar datos (Wipe)"
- **Botón eliminar (Fase 3):** opción "Eliminar usuario" (hard delete vía RPC `delete_user`) con diálogo de confirmación
- **`errorBuilder`:** todos los `Image.network` de avatares tienen fallback a inicial del nombre
- **Providers:** `adminUsuariosProvider(query)` (datos + búsqueda), ordenamiento gestionado en cliente

### 20.6 AdminUsuarioDetalle — Perfil, Estadísticas, Timeline y Configuración

**Archivo:** `app/lib/features/admin/presentation/admin_usuario_detalle.dart`

Enriquecido con `TabController(length: 3)` y sección de configuración:

| Pestaña | Contenido | Datos |
|---------|-----------|-------|
| **Perfil** | Datos del usuario (email, nombre, nivel, XP, racha) + **sección de configuración (Fase 3):** editar nombre, editar email, reset XP, cambiar nivel, botón eliminar usuario + conteos de actividad (sesiones, rutinas, retos, insignias) | `usuarios` + `perfil_bienestar_usuario` + `perfil_academico_usuario` + subconsultas COUNT |
| **Estadísticas** | `AdminGraficosUsuario`: LineChart RPE semanal + BarChart volumen semanal | `adminUsuarioStatsProvider` → `v_analitica_semanal` filtrado por usuario |
| **Timeline** | `AdminTimelineUsuario`: actividad cronológica (sesiones, retos, publicaciones, check-ins) | `adminUsuarioTimelineProvider` → queries múltiples |

**Configuración de usuario (Fase 3):**
- **Editar nombre:** diálogo con `TextField` pre-rellenado, llama a `editarNombreUsuario()`
- **Editar email:** diálogo con validación de formato, llama a `editarEmailUsuario()`
- **Reset XP:** botón con confirmación, setea `xp_total = 0`, registra en `admin_auditoria`
- **Cambiar nivel:** diálogo con selector numérico, registra en `admin_auditoria`
- **Eliminar usuario:** botón rojo con diálogo de confirmación "Esta acción es irreversible", invoca RPC `delete_user`
- **`errorBuilder`:** fallback a inicial del nombre si `url_avatar` es inválido

### 20.7 AdminContenidoList — Moderación de contenido

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_contenido_list.dart`

Lista las publicaciones y comentarios con `reportado = true`, consumiendo `adminContenidoReportadoProvider`:

- **Publicaciones reportadas:** muestra autor, contenido, fecha y quién reportó. Acciones: "Ocultar" (`esta_eliminado = true`), "Restaurar" (`esta_eliminado = false`), "Ignorar reporte" (`reportado = false`).
- **Comentarios reportados:** muestra autor, contenido, fecha. Acciones: "Eliminar" (soft delete), "Ignorar reporte".
- Cada acción de moderación inserta un registro en `admin_auditoria`.

### 20.8 AdminEjercicioCard — Catálogo admin

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_ejercicio_card.dart`

Lista del catálogo completo consumiendo `adminEjerciciosProvider`:

- Cada ejercicio muestra: nombre, dificultad, músculos objetivo, estado actual (activo/inactivo)
- **Toggle:** `Switch` que llama a `adminEjercicioToggleProvider` → UPDATE `ejercicios.activo`
- Al desactivar: el ejercicio se oculta de búsquedas y recomendaciones IA (filtradas por `WHERE activo = true`)
- **Indicador visual:** ejercicios inactivos en gris con opacidad reducida
- **Búsqueda/filtro:** `TextField` para filtrar por nombre, chips de filtro por dificultad y grupo muscular

### 20.9 AdminLogEntry — Logs de auditoría

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_log_entry.dart`

Lista cronológica (más reciente primero) de `admin_auditoria`:

- Cada entrada muestra: admin (email), usuario afectado (email o "N/A"), acción (badge coloreado), detalles (JSONB expandible), fecha/hora
- **Badges por acción:** wipe (rojo), reset_xp (naranja), set_nivel (azul), ocultar_ejercicio (gris), moderar (ámbar)
- **Filtro:** chips para filtrar por tipo de acción
- **Provider:** `adminAuditoriaProvider`

### 20.10 AdminGraficosUsuario + AdminTimelineUsuario

**Archivos:**
- `app/lib/features/admin/presentation/widgets/admin_graficos_usuario.dart`
- `app/lib/features/admin/presentation/widgets/admin_timeline_usuario.dart`

Widgets usados dentro de `AdminUsuarioDetalle` (pestañas Estadísticas y Timeline):

- **Gráficos:** `fl_chart` — `LineChart` con RPE semanal (eje Y: 1-10, eje X: semanas) y `BarChart` con volumen semanal en minutos. Datos desde `adminUsuarioStatsProvider`.
- **Timeline:** `ListView` con items tipo `TimelineItem` (sesiones, retos, publicaciones, check-ins, estudio) ordenados cronológicamente. Máximo 50 items.

### 20.11 AdminPaginacionBar

**Archivo:** `app/lib/features/admin/presentation/widgets/admin_paginacion_bar.dart`

Componente reutilizable para paginación:
- Botones ← Anterior / Siguiente → (deshabilitados en extremos)
- Indicador "Página X de Y (Z resultados)"
- Selector de items por página (10/25/50)
- Usado por: `AdminListaUsuarios`, `AdminContenidoList`, `AdminEjercicioCard`

### 20.12 Providers nuevos y extendidos

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `esAdminProvider` | `FutureProvider<bool>` | Verifica si el usuario autenticado tiene `rol = 'admin'` |
| `adminMetricasProvider` | `FutureProvider<AdminMetricasGlobales>` | Métricas desde `v_admin_metricas` |
| `adminRegistrosDiariosProvider` | `FutureProvider<List<RegistroDiario>>` | Registros diarios últimos 30 días (para gráfico de tendencia) |
| `adminFiltroUsuariosProvider` | `StateProvider<String>` | Filtro de búsqueda de usuarios |
| `adminUsuariosPaginadosProvider` | `FutureProvider<List<UsuarioAdmin>>` | Usuarios paginados y filtrados |
| `adminContenidoReportadoProvider` | `FutureProvider<List<dynamic>>` | Publicaciones y comentarios reportados |
| `adminEjerciciosProvider` | `FutureProvider<List<EjercicioAdmin>>` | Catálogo completo con campo `activo` |
| `adminAuditoriaProvider` | `FutureProvider<List<AuditoriaRegistro>>` | Logs de auditoría cronológicos |
| `adminUsuarioStatsProvider` | `FutureProvider.family<UsuarioEstadisticas, String>` | RPE y volumen por usuario |
| `adminUsuarioTimelineProvider` | `FutureProvider.family<List<TimelineItem>, String>` | Timeline de actividad por usuario |

**Mutaciones extendidas en `admin_provider.dart`:**
| Mutación | Descripción | Fase |
|----------|-------------|------|
| `resetXpUsuario(usuarioId, ref)` | Resetea XP a 0 sin cambiar nivel. Inserta en `admin_auditoria`. | Fase 1 |
| `setNivelUsuario(usuarioId, nuevoNivel, ref)` | Cambia nivel manualmente. Inserta en `admin_auditoria`. | Fase 1 |
| `listarUsuariosFiltrado(filtro, pagina, ref)` | Búsqueda paginada con filtro. | Fase 1 |
| `contarUsuarios(filtro, ref)` | Conteo total para paginación. | Fase 1 |
| `ocultarEjercicio(ejercicioId, ref)` | UPDATE `activo = false`. Inserta en `admin_auditoria`. | Fase 2 |
| `mostrarEjercicio(ejercicioId, ref)` | UPDATE `activo = true`. Inserta en `admin_auditoria`. | Fase 2 |
| `moderarPublicacion(publicacionId, accion, ref)` | Soft delete/restaurar/ignorar reporte. Inserta en `admin_auditoria`. | Fase 2 |
| `moderarComentario(comentarioId, accion, ref)` | Soft delete/ignorar reporte. Inserta en `admin_auditoria`. | Fase 2 |
| `eliminarUsuario(usuarioId, ref)` | Hard delete vía RPC `delete_user`. Inserta en `admin_auditoria`. Invalida listado. | **Fase 3** |
| `editarNombreUsuario(usuarioId, nombre, ref)` | UPDATE `usuarios.nombre_completo`. Inserta en `admin_auditoria`. | **Fase 3** |
| `editarEmailUsuario(usuarioId, email, ref)` | UPDATE `usuarios.email`. Inserta en `admin_auditoria`. | **Fase 3** |

**Validación de imágenes (Fase 3):**
Todos los `Image.network` en widgets del panel admin incluyen `errorBuilder` que muestra un fallback con la inicial del nombre del usuario (avatar placeholder accesible).

---

## 21. Sistema de Time-Blocking Académico — Lienzo Continuo (v7.1)

**Archivos base:** `app/lib/features/academico/`
**Rutas nuevas:** `/academico/planificar`, `/academico/planificar/canvas`
**Sin dependencias externas:** 0 nuevas en `pubspec.yaml`. Usa widgets nativos de Flutter: `Stack`, `Positioned`, `Draggable`, `DragTarget`.

### 21.1 Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|-----------|-----------|
| **Grid Canvas** | Flutter nativo: `Stack` + `Positioned` | Renderizar bloques sobre una cuadrícula horaria semanal |
| **Drag & Drop** | `Draggable` + `DragTarget` | Reorganizar bloques entre días y horas sin dependencia externa |
| **IA (Time-Blocking)** | Gemini Flash (mismo `RecomendacionIaService`) | Generar la distribución semanal óptima desde reglas N1-N10 |
| **Estado** | Riverpod (`StateNotifierProvider`) | Inbox config, grid state, horarios fijos, resultado IA |
| **Persistencia** | Supabase `horarios_academicos` | Guardar/recuperar el plan semanal |
| **Gamificación** | Widgets nativos + `fl_chart` (ya instalado) | Barra de progreso de productividad |

### 21.2 Rutas de Navegación

| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/academico/planificar` | `InboxScreen` | Inbox: sliders de intenciones + entregas + horarios fijos |

| `/academico/planificar/canvas` | `CanvasScreen` | Canvas semanal infinito: visualización, drag & drop, navegación temporal, guardar |
### 21.3 Providers del Módulo Planificador

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `inboxConfigProvider` | `StateNotifierProvider<InboxConfigNotifier, InboxConfig>` | Estado del formulario inbox: horas de estudio, días de deporte, entregas pendientes |
| `entregasPendientesProvider` | `FutureProvider` | Entregas y exámenes próximos desde `entregas_examenes` |
| `asignaturasActivasInboxProvider` | `FutureProvider` | Asignaturas activas del usuario para asignar a bloques de estudio |
| `rutinasActivasInboxProvider` | `FutureProvider` | Rutinas activas para asignar a bloques de deporte |
| `horariosFijosProvider` | `FutureProvider<List<HorarioAcademicoDb>>` | Consulta `horarios_academicos WHERE es_fijo = true` |
| `calendarGridProvider` | `StateNotifierProvider<CalendarGridNotifier, CalendarGridState>` | Estado mutable del canvas: bloques posicionados, DnD, resize, navegación semanal infinita |
| `bloque_estudio_provider.dart` | Funciones de mutación | `toggleBloqueCompletado()` — marca bloques como completados con checkbox, otorga XP |

### 21.4 Matemática del Grid Hora ↔ Píxel

El canvas usa un sistema de coordenadas basado en constantes fijas para convertir horas a posiciones y viceversa:

```dart
// Constantes del grid (definidas en planificador_constants.dart)
const double PIXELS_PER_HOUR = 80.0;    // 80px = 1 hora de bloque
const int HOUR_START = 7;               // El grid empieza a las 07:00
const int HOUR_END = 23;                // El grid termina a las 23:00
const double COLUMN_WIDTH = 120.0;      // Ancho de cada columna (día)
const double HOUR_LABEL_WIDTH = 48.0;   // Ancho de la columna de etiquetas horarias
const double HEADER_HEIGHT = 40.0;      // Alto del header con días de la semana

// Fórmulas de conversión
double horaToY(DateTime hora) {
  final totalMinutes = hora.hour * 60 + hora.minute;
  final startMinutes = HOUR_START * 60;
  return (totalMinutes - startMinutes) / 60.0 * PIXELS_PER_HOUR;
}

double duracionToHeight(int duracionMinutos) {
  return (duracionMinutos / 60.0) * PIXELS_PER_HOUR;
}

DateTime yToHora(double y) {
  final totalMinutes = (y / PIXELS_PER_HOUR * 60.0).round() + (HOUR_START * 60);
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  return DateTime(2024, 1, 1, hour.clamp(HOUR_START, HOUR_END - 1), minute);
}

// Posicionamiento de columna por día
double diaToX(int diaSemana) {
  // diaSemana: 1=Lunes..7=Domingo
  return HOUR_LABEL_WIDTH + (diaSemana - 1) * COLUMN_WIDTH;
}

// Ancho total del canvas
double get canvasWidth => HOUR_LABEL_WIDTH + 7 * COLUMN_WIDTH;
double get canvasHeight => (HOUR_END - HOUR_START) * PIXELS_PER_HOUR;
```

**Snap al grid:** Al soltar un bloque (`DragTarget.onAcceptWithDetails`), las coordenadas se redondean al slot horario más cercano con precisión de 15 minutos (20px). El bloque se ancla a `diaSemana` y `horaInicio` exactos.

### 21.5 Flujo de Usuario

```mermaid
flowchart TD
    A["Usuario accede a /academico/planificar"] --> B["INBOX: Configurar intenciones"]
    
    B --> B1["Slider: Horas de estudio / semana"]
    B1 --> B2["Slider: Días de deporte / semana"]
    B2 --> B3["Lista: Entregas próximas (desde entregas_examenes)"]
    B3 --> B4["Horarios fijos: solo lectura (clases, compromisos)"]
    B4 --> B5["Barra de energía: indica disponibilidad cognitiva"]
    B5 --> C["Botón 'Ir al Canvas' → /academico/planificar/canvas"]
    
    C --> D["CANVAS: Lienzo Continuo con navegación semanal infinita"]
    
    D --> D1["Primera columna = Hoy. Barra de navegación: < Anterior | Fechas | Siguiente > | Hoy"]
    D1 --> D2["Visualizar semana completa con bloques coloreados"]
    D2 --> D3{"¿Ajustes manuales?"}
    D3 -->|"Drag & Drop"| D4["Mover bloques entre días/horas"]
    D3 -->|"Resize"| D5["Ajustar duración desde borde inferior"]
    D3 -->|"Checkbox"| D6["Marcar bloque como completado → XP + SyncHub"]
    D3 -->|"No"| E["Barra inferior: Volver + Guardar"]
    D4 --> E
    D5 --> E
    D6 --> E
    
    E --> F["UPSERT en horarios_academicos (es_fijo = false)"]
    F --> G["Dashboard: Timeline muestra plan del día"]
```

### 21.6 Widgets Clave

#### 21.6.1 `InboxScreen`

**Archivo:** `app/lib/features/academico/presentation/inbox_screen.dart`

Formulario de intenciones académicas con diseño de "Inbox" minimalista:

| Campo | Widget | Rango | Propósito |
|-------|--------|-------|-----------|
| Horas de estudio | `Slider` + label | 0–50 h/semana | Define carga semanal de estudio auto-dirigido |
| Días de deporte | `Slider` + label | 1–6 días/semana | Reserva huecos para entrenamiento (no colisionan con fijos) |
| Entregas próximas | `Chips` + fechas | Desde `entregas_examenes` | La IA prioriza bloques pre-entrega |
| Horarios fijos | `ListView` (read-only) | Desde `horariosFijosProvider` | Clases y compromisos inamovibles |

**Barra de energía:** Indicador visual de disponibilidad cognitiva basado en `estadoEnergeticoProvider`. Ayuda al usuario a decidir cuántas horas de estudio planificar.

**Botón "Ir al Canvas":** `FilledButton` con `Icons.grid_view` que navega a `/academico/planificar/canvas` llevando la configuración del inbox. El canvas se inicializa con los horarios fijos y la IA genera la distribución automáticamente al cargar.

#### 21.6.2 `CanvasScreen` (Lienzo Continuo — Grid semanal infinito)

**Archivo:** `app/lib/features/academico/presentation/canvas_screen.dart`

Lienzo semanal de 7 columnas × 16 horas con navegación temporal infinita. Fondo oscuro `#1A1A2E` para reducir fatiga visual en sesiones largas de planificación.

**Navegación semanal infinita:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  < Anterior  |  Sem 15-21 Jun 2026  |  Siguiente >  |  [Hoy]               │
├────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──────────┬──┤
│  07:00 │          │          │          │          │          │          │  │
│  08:00 │ ████████ │          │ ████████ │          │ ████████ │          │  │
│  09:00 │ Matemát. │          │  Física  │          │ Matemát. │          │  │
│  10:00 │          │ ████████ │          │ ████████ │          │          │  │
│  11:00 │ ████████ │ Estudio  │          │ Estudio  │          │          │  │
│  ...   │   ...    │   ...    │   ...    │   ...    │   ...    │   ...    │  │
│  20:00 │ ████████ │          │          │          │          │ ████████ │  │
│        │ Deporte  │          │          │          │          │ Deporte  │  │
├────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┴──┤
│                              [ Volver ]  [ Guardar ]                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Características del Lienzo Continuo:**

| Característica | Descripción |
|----------------|-------------|
| **Primera columna = Hoy** | La columna izquierda siempre corresponde al día actual, facilitando orientación inmediata |
| **Navegación infinita** | Botones `< Anterior` / `Siguiente >` permiten navegar semanas hacia adelante y atrás sin límite |
| **Selector de fechas** | La barra superior muestra el rango de fechas de la semana visible (ej: "Sem 15-21 Jun 2026") |
| **Botón Hoy** | Retorna instantáneamente a la semana actual |
| **Eje horario inline** | Las horas (07:00, 08:00...) flotan sobre las líneas del grid en la columna izquierda |
| **Fondo oscuro** | `#1A1A2E` (dark navy) — reduce fatiga visual, mejora contraste de bloques coloreados |
| **Barra inferior simplificada** | Solo 2 botones: `Volver` (navega al inbox) y `Guardar` (persiste la semana) |

**Capas del `Stack`:**
1. **GridLinesPainter** (`CustomPainter`): Líneas de hora (gris suave, 1px) y líneas de día (gris medio, 2px).
2. **Bloques fijos** (`Positioned`): Horarios inamovibles con opacidad 90%. No aceptan drag.
3. **Bloques IA** (`Draggable > Positioned`): Bloques generados por IA. Draggable, feedback con opacidad 70%.
4. **Bloques inamovibles** (`Positioned`): Bloques con `esHitoInamovible = true` (exámenes, entregas). No aceptan drag, protegidos contra edición accidental.
5. **DragTargets** por celda: Cada intersección hora×día es un `DragTarget` que acepta `TimeBlock`.

**Checkbox de completado:** Cada bloque de estudio/deporte incluye un checkbox. Al marcarlo:
- `toggleBloqueCompletado()` actualiza `horarios_academicos.completado = true`
- Otorga XP: `ceil(mins/30) × 10`
- Emite evento `bloqueEstudioCompletado` al SyncHub para invalidar providers relacionados

#### 21.6.3 `TimeBlockWidget`

**Archivo:** `app/lib/features/academico/presentation/widgets/time_block_widget.dart`

Tarjeta de bloque con soporte drag. Renderiza:

| Propiedad | Descripción |
|-----------|-------------|
| Color | Por tipo de bloque (ver §21.7) |
| Título | Texto en negrita blanco, 13px |
| Duración | Subtítulo: "1h 30m" en opacidad 80% |
| Asignatura | Badge pequeño con nombre de asignatura |
| Handle de resize | Borde inferior con `GestureDetector` para redimensionar |
| Feedback de drag | Misma card con opacidad 70% y sombra elevada |
| **Indicador de rutina** | **NUEVO v7.1** — Bloques de deporte con `diaRutinaId != null` muestran: barra vertical blanca semitransparente a la izquierda (pertenencia a rutina), nombre del día de la rutina en el header (ej: "Torso"), nombre de la rutina en el subtitle en texto tenue (ej: "Push Pull Legs") |

**Implementación Drag:**
```dart
Draggable<BloquePlanificadoData>(
  data: bloque,
  feedback: Material(child: DraggableBlockCard(bloque: bloque, isFeedback: true)),
  childWhenDragging: Opacity(opacity: 0.3, child: DraggableBlockCard(bloque: bloque)),
  child: DraggableBlockCard(bloque: bloque),
)
```

#### 21.6.4 `ProgressGamificationBar`

**Archivo:** `app/lib/features/academico/presentation/widgets/progress_gamification_bar.dart`

Barra de progreso horizontal que muestra la adherencia al plan generado:

- **Estudio planeado vs real:** Barra azul (horas completadas) sobre fondo gris (horas planeadas)
- **Deporte planeado vs real:** Barra naranja
- **Porcentaje global:** "73% de la semana completada"
- **Racha de cumplimiento:** 🔥 "3 semanas seguidas cumpliendo el plan"
- **Insignia:** Al alcanzar 80%+ en 4 semanas consecutivas → insignia "Planificador Maestro"

#### 21.6.5 `AcademicBlockSheet` (Sheet unificado de creación/edición de bloques con distribución de rutina)

**Archivo:** `app/lib/features/academico/presentation/widgets/academic_block_sheet.dart`

Sheet reutilizable que se abre al tocar un hueco vacío en el canvas o al editar un bloque existente. Usa `SegmentedButton` con 5 pestañas: Estudio, Examen, Entrega, Deporte, Reto. La pestaña **"Deporte" integra la distribución completa de rutina** (antes en `RutinaConfigSheet`, que ya no se usa desde el canvas):

**Selector de rutina:**
- Dropdown que lista las rutinas activas del usuario desde `rutinasActivasInboxProvider`.
- Al seleccionar una rutina, se consultan automáticamente los `dias_rutina` reales de la BD usando la columna `semana_id` (corregido de `semana_rutina_id`).

**Switch "Distribuir rutina completa":**
- Al activarlo, muestra:
  - **Selector de días (FilterChips):** chips L-D para elegir qué días de la rutina distribuir en el lienzo.
  - **DatePicker de inicio:** fecha desde la cual empezar a colocar los bloques de deporte.
  - **Resumen de distribución:** total de bloques a crear, días seleccionados, y nombre de la rutina.
- El botón principal cambia dinámicamente: "Crear sesión de deporte" (bloque individual) ↔ "Distribuir X bloques" (distribución completa vía `placeRutinaDistribuida()`).

**Variables de estado:**
| Variable | Tipo | Propósito |
|----------|------|-----------|
| `_distribuirRutina` | `bool` | Switch de distribución completa |
| `_diasDistribucion` | `Set<int>` | Días seleccionados (1=L, 7=D) |
| `_fechaInicioDistribucion` | `DateTime` | Fecha de inicio para distribución |
| `_totalDiasRutina` | `int?` | Total de días reales en la rutina (desde BD) |
| `_cargandoDias` | `bool` | Indicador de carga de consulta a BD |
| `_duracionSemanasRutina` | `int?` | Duración en semanas de la rutina seleccionada |

**Métodos nuevos:**
- `_cargarTotalDias()` — consulta `dias_rutina` con `semana_id` para obtener el total real de días.
- `_buildDistribucionSection()` — renderiza la UI de distribución completa.
- `_buildFechaInicioPicker()` — DatePicker para seleccionar la fecha de inicio.
- `_buildDistribucionResumen()` — muestra conteo de bloques y días seleccionados.

**Flujo de distribución de rutina:**
```
1. Usuario selecciona rutina → se cargan días reales desde BD
2. Activa "Distribuir rutina completa" → elige días y fecha de inicio
3. Pulsa "Distribuir X bloques" → llama a calendarGridProvider.placeRutinaDistribuida()
4. Los bloques de deporte aparecen en el canvas con indicador visual de rutina (barra blanca + nombre del día)
```

### 21.7 Sistema de Colores por Tipo de Bloque (Flat Design)

Cada tipo de bloque se distingue por color plano con opacidad para mantener legibilidad sobre el fondo oscuro del grid:

| Tipo de Bloque | Hex Code | Color | Uso |
|----------------|----------|-------|-----|
| `clase` | `#4A90D9` | Azul acero | Clases presenciales (horarios fijos) |
| `estudio` | `#3B82F6` | Azul estudio | Bloques de estudio generados por IA |
| `deporte` | `#FF8C42` | Naranja cálido | Bloques de entrenamiento |
| `entrega` | `#E74C3C` | Rojo coral | Bloques pre-entrega (2-3 días antes) |
| `descanso` | `#27AE60` | Verde esmeralda | Descanso/comida (12:00-14:00) |
| `libre` | `#95A5A6` | Gris medio | Tiempo libre / buffer |
| `examen` | `#F1C40F` | Amarillo dorado | Preparación de examen (3-5 días antes) |
| `pomodoro` | `#1ABC9C` | Teal | Sesiones Pomodoro (25 min) |

**Regla de opacidad:** Bloques fijos usan opacidad 90% (`withOpacity(0.9)`), bloques IA usan 80% (`withOpacity(0.8)`), bloques en drag usan 70% (`withOpacity(0.7)`). El fondo del grid es `#1A1A2E` (dark navy).

### 21.8 Integración con el Dashboard

Tras guardar la semana desde el canvas:

1. Los bloques con `es_fijo = false` se guardan en `horarios_academicos` con `dia_semana` calculado.
2. `timelineHoyProvider` ahora incluye bloques generados por IA en el tab "Hoy".
3. La barra de carga cognitiva se actualiza con las horas de estudio planeadas vs reales.

---

**Documento compilado:** 27-06-2026
**Última revisión:** v7.2 — Añadido §8.0.2 (calorie chips: SemantiCalorieChip, buildCalorieChip), §8.0.3 (CalorieCalculatorService), §6.2-6.3 actualizados (sistema de laps por timestamp, timer bar "Objetivo: HH:MM:SS", duracionRealPorEjercicio en finalizarSesion).
**Referencia:** Alineado con SRS v5.2, Arquitectura v5.3, Plan Maestro v2.0
