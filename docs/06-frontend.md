# 06 - Frontend (Estructura UI, Componentes y Pantallas)

**Proyecto:** SynaptixFit
**Versión:** 4.2
**Fecha:** 19-05-2026
**Referencia:** [03-architecture.md](03-architecture.md), [02-requirements.md](02-requirements.md), [15-ia-recomendacion-sistema.md](15-ia-recomendacion-sistema.md)

---

## 1. Arquitectura de Información (MVP v3.0)

```mermaid
flowchart LR
    Home["🏠 Inicio<br/>Dashboard"] --> Academic["📚 Académico<br/>Plan Semanal"]
    Home --> Challenges["🎯 Retos<br/>Crear/Listar"]
    Home --> Wellness["💪 Bienestar<br/>Rutinas/Ejercicios/IA"]
    Home --> Social["👥 Social<br/>Muro de Logros"]
    Home --> Profile["👤 Perfil<br/>Datos + Bienestar"]

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
| `/academico/asignaturas` | `GestionAsignaturasScreen` | Búsqueda y gestión de asignaturas |
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
| `/bienestar/ejercicio/:id` | `DetalleEjercicioScreen` | Detalle de ejercicio |
| `/bienestar/rutina/:id` | `RutinaDetalleScreen` | **Gestión: semanas, días, ejercicios, progreso, periodización** |
| `/bienestar/rutina/sesion` | `LiveSessionScreen` | **Entrenamiento en vivo + check-in diario** |
| `/bienestar/sesion-completada` | `SesionCompletadaScreen` | Historial de sesiones |
| `/perfil` | `PerfilScreen` | Perfil + bienestar editable + carreras + ajustes |
| `/notificaciones` | `NotificacionesScreen` | Centro de notificaciones |

**Nota importante:** La ruta `/bienestar/rutina/sesion` debe estar definida ANTES de `/bienestar/rutina/:id` en GoRouter para evitar que "sesion" sea capturado como parámetro `:id`.

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

### 3.3 Proveedores del Módulo de Ejercicios

| Provider | Tipo | Propósito | Fuente |
|----------|------|-----------|--------|
| `ejerciciosProvider` | `StreamProvider<List<EjercicioDb>>` | Catálogo completo en tiempo real | `supabase.from('ejercicios').stream()` (Realtime) |
| `catalogosProvider` | `FutureProvider<CatalogosEjercicios>` | Datos maestros: partes_cuerpo, musculos, equipamientos | `partes_cuerpo`, `musculos`, `equipamientos` |
| `ejercicioDetalleProvider` | `FutureProvider.family<EjercicioDb?, String>` | Detalle completo de un ejercicio (incluye instrucciones) | `v_ejercicios_completos` WHERE `id` |
| `ejerciciosFiltradosProvider` | `Family` (lógica en provider) | Búsqueda con filtros por grupo muscular, equipamiento, parte del cuerpo, dificultad, texto | `v_ejercicios_completos` con filtros |

### 3.4 Proveedores del Dashboard

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `proveedorUsuario` | `FutureProvider<UsuarioDb>` | Perfil del usuario autenticado |
| `proveedorTablero` | `FutureProvider` | Datos agregados del dashboard (KPIs, retos, racha) |
| `retosProvider` | `FutureProvider<List<RetoResumen>>` | Retos activos del usuario con `tieneHitos` vía batch query |
| `sesionesProvider` | `FutureProvider` | Sesiones recientes del usuario |

### 3.5 Funciones de Mutación (en `rutina_provider.dart`)

| Función | Operación SQL | Invalidaciones |
|---------|--------------|----------------|
| `crearRutinaCompleta({nombre, objetivo, visibilidad, duracionSemanas, estructura, ref})` | INSERT `rutinas` + `semanas_rutina` (con `tipo_semana`) + `dias_rutina` + `seleccion_de_ejercicios` | `rutinasUsuarioProvider` |
| `eliminarRutina(rutinaId, ref)` | DELETE `rutinas` (CASCADE) | `rutinasUsuarioProvider` |
| `clonarRutina(rutinaId, ref)` | INSERT `rutinas` (copia como privada) + `seleccion_de_ejercicios` | `rutinasUsuarioProvider` |
| `iniciarSesion({rutinaId, diaId, ref})` | INSERT `sesiones_registradas` + UPDATE `dias_rutina.estado='en_progreso'` | `diasDeSemanaProvider` |
| `finalizarSesion({sesionId, diaId, rutinaId, duracionSegundos, rpe, ref})` | UPDATE `sesiones_registradas` (duración, RPE, calorías) + UPDATE `dias_rutina.estado='completado'` (cascada a semana vía trigger `trg_dias_rutina_estado`) | `diasDeSemanaProvider` + `semanasDeRutinaProvider(rutinaId)` |
| `registrarSerie({sesionId, seleccionId, numeroSerie, reps, peso})` | INSERT `series_sesion` | — |
| `guardarEstadoDiario({sueño, estrés, energía, dolor, zonas, listo, ref})` | UPSERT `estado_diario_usuario` ON CONFLICT (`usuario_id`, `fecha`) | `estadoDiarioHoyProvider` |
| `agregarEjercicioADia({rutinaId, diaId, ejercicioId, series, reps, descanso, ref})` | INSERT `seleccion_de_ejercicios` | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
| `quitarEjercicioDeDia(seleccionId, diaId, ref)` | DELETE `seleccion_de_ejercicios` | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
| `actualizarEjercicioDia(seleccionId, patch, diaId, ref)` | UPDATE `seleccion_de_ejercicios` | `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` |
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

**Invalidación selectiva (`PerfilCambio` enum):**
- `PerfilCambio.nombre` → solo `perfilUsuarioProvider` (2 queries vs 7)
- `PerfilCambio.bienestar` → `perfilBienestarCompletoProvider` + `perfilUsuarioProvider` + `perfilBienestarProvider` (3-4 queries vs 7)
- `PerfilCambio.preferencias` → solo `perfilPreferenciasProvider` (1 query vs 7)
- `PerfilCambio.todo` → todos los providers
- Sin `autoDispose` → keepAlive implícito en memoria tras primera carga

## 4. Pantalla: Nueva Rutina con IA (`NuevaRutinaScreen`)

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart`
**Ruta:** `/bienestar/nueva-rutina`

### 4.1 Flujo de 3 Pasos

```mermaid
flowchart TD
    Start["Usuario accede a Nueva Rutina"] --> Paso1["PASO 1: Metadatos"]

    Paso1 --> BotonIA1{"¿Pulsa 'Recomendar\nrutina con IA'?"}
    BotonIA1 -->|Sí| IA1["Llama a generarRecomendacionRutina()\nRellena: nombre, desc, objetivo, duración"]
    BotonIA1 -->|No| Manual1["Rellena manualmente:\nnombre, descripción, objetivo\nvisibilidad, semanas, días/sem"]

    IA1 --> BotonIA2{"¿Pulsa 'Recomendar\nejercicios'?"}
    Manual1 --> BotonIA2

    BotonIA2 -->|Sí| IA2["Llama a generarEstructuraCompleta()\nRellena TODA la estructura\n(semanas × días × ejercicios)"]
    BotonIA2 -->|No| Paso2["PASO 2: Estructura"]

    IA2 --> Paso2

    Paso2 --> Semanas["Selector de semanas\n(añadir/eliminar)"]
    Semanas --> Dias["Por cada semana: lista de días\n(añadir/eliminar)"]
    Dias --> BotonIA3{"¿Pulsa 'Sugerir ejercicios\ncon IA' en un día?"}
    BotonIA3 -->|Sí| IA3["Llama a generarRecomendacionEjercicios()\nAñade 3-6 ejercicios sin repetir"]
    BotonIA3 -->|No| Manual3["Añade ejercicios manualmente\ndesde el catálogo"]

    IA3 --> Paso3
    Manual3 --> Paso3

    Paso3["PASO 3: Revisión"] --> Review["Resumen: semanas, días,\nejercicios totales"]
    Review --> Create["Crear Rutina\nllama a crearRutinaCompleta()"]
    Create --> Navigate["Navega a /bienestar/rutina/:id"]
```

### 4.2 Datos de Entrada al Prompt IA

Los siguientes datos se recopilan antes de cada llamada a la IA:

| Dato | Provider/Origen | Uso en el prompt |
|------|----------------|------------------|
| Edad, sexo, peso, altura, IMC | `perfilBienestarProvider` | Reglas de seguridad biométrica |
| Objetivo principal | `perfilBienestarProvider` | Reglas de programación (reps, descanso, tipo de ejercicios) |
| Nivel de actividad | `perfilBienestarProvider` | Intensidad base de la rutina |
| Equipamiento disponible | `perfilBienestarProvider` | Filtro de compatibilidad (solo se envían ejercicios del equipamiento) |
| Días disponibles / semana | `perfilBienestarProvider` | Número de días en la estructura |
| Minutos por sesión | `perfilBienestarProvider` | Volumen total por día |
| Historial de sesiones | `historialSesionUsuarioProvider` | RPE promedio, volumen, ejercicios recientes, semanas consecutivas |
| Estado diario (hoy) | `estadoDiarioHoyProvider` | Sueño, estrés, energía, dolor, zonas → adaptación |
| Catálogo de ejercicios | `ejerciciosProvider` | Filtrado por equipamiento, enviado como JSON al prompt |
| Ejercicios ya agregados | Estado local del formulario | Lista de exclusión para no repetir |

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
// Si tiene ejercicios → muestra _CheckInDialog → inicia sesión
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

## 6. Pantalla: Sesión en Vivo (`LiveSessionScreen`)

**Archivo:** `app/lib/features/bienestar/presentation/sesion_en_vivo_screen.dart`
**Ruta:** `/bienestar/rutina/sesion`

### 6.1 Check-in Diario (durante el primer descanso) + Adaptación IA

El check-in ya no bloquea el inicio de la sesión. El cronómetro aparece **inmediatamente** al pulsar "Empezar entrenamiento", y el check-in se muestra durante el **primer descanso** (tras completar la primera serie). **Si el usuario ya hizo check-in hoy, el overlay no se muestra en absoluto** (verificación silenciosa antes de mostrar).

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
| `fatiga > 50` | Reducir 1 serie por ejercicio | `_seriesReducidas = true` → todas las cards muestran 1 serie menos |
| `fatiga > 50` | Bajar peso 10% en compuestos | Sugerencia visual (no se aplica automáticamente al peso del TextField) |
| `dolor ≥ 3` + zonas | Evitar ejercicios de [zonas] | `_ejerciciosEvitados` se rellena. Banner rojo visible. |
| `energía ≤ 2` | Reducir intensidad general | `_seriesReducidas = true` (mismo efecto) |

**Banners de estado durante la sesión:**
- Banner naranja: "Sesión adaptada: -1 serie por ejercicio" (visible si `_seriesReducidas == true`)
- Banner rojo: "Se evitarán ejercicios de: [zonas]" (visible si `_ejerciciosEvitados` no está vacío)

### 6.2 Funcionalidad Durante la Sesión

| Componente | Comportamiento |
|------------|---------------|
| **Cronómetro** | Se inicia automáticamente al entrar. Muestra `HH:MM:SS` en AppBar. |
| **Lista de ejercicios** | Cada ejercicio muestra sus series como filas con: checkbox circular, campo de peso (kg) editable, campo de reps editable. |
| **Check de serie** | Al marcar completada → `registrarSerie()` + inicia cronómetro de descanso (90s). |
| **Cronómetro de descanso** | Cuenta atrás visible. Botones: `+15s`, `-15s`, `Saltar`. Al llegar a 0, desaparece automáticamente. |
| **Edición de peso/reps** | Campos editables inline durante la sesión. Se guardan en `series_sesion`. |

### 6.3 Diálogo de Finalización

Al pulsar "Finalizar sesión":
1. Muestra duración total en formato legible (ej: "45 min 30 s")
2. **Slider RPE** (1-10): Rate of Perceived Exertion
3. **ChoiceChips de persistencia:**
   - "Solo hoy": los cambios de peso/reps NO se guardan en `seleccion_de_ejercicios` (solo en `series_sesion`)
   - "Para siempre": los cambios de peso/reps SÍ se actualizan en `seleccion_de_ejercicios` para futuras sesiones
4. Al confirmar → `finalizarSesion()` actualiza `sesiones_registradas` (duración, RPE, calorías) y marca el día como `completado`
5. Navegación de vuelta a `RutinaDetalleScreen`

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

`ListView` con grid de 2 columnas de tarjetas de métricas (glass cards):

| Métrica | Valor | Color | Subtítulo |
|---------|-------|-------|-----------|
| **XP Total** | `usuario.xpTotal` | `#72FE8G` (verde) | "Nivel X" |
| **Sesiones** | `sesiones` (COUNT desde `sesiones_registradas`) | `#60A5FA` (azul) | — |
| **Retos** | `logros` (COUNT retos completados) | `#E8A838` (dorado) | — |
| **Calorías** | `caloriasAcumuladas` (SUM `calorias_quemadas`) | `#FF6B35` (naranja) | — |
| **Racha actual** | `usuario.rachaActual` | `#A78BFA` (violeta) | "días consecutivos" |

Estilo de tarjeta `_metricCard()`:
- `BorderRadius.circular(16)`, padding 16px
- Fondo: `color.withValues(alpha: 0.06)`, borde: `color.withValues(alpha: 0.12)`
- Valor numérico: `fontSize: 28`, `FontWeight.w800`, color semántico, `letterSpacing: -1`
- Label: 13px, `FontWeight.w600`, color `#94A3B8`. Subtítulo opcional: 11px, `#64748B`

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

**Parser de duración libre (`_parseDuracion()`):** Acepta formatos como `"5m 30s"`, `"5:30"`, `"300"` (segundos puros), `"5 min"`, `"5m"`. Se almacena en segundos en `duracionSegundos`.

### 8.3 Widget `_MiniGifPreview`

**Archivo:** `app/lib/features/bienestar/presentation/nueva_rutina_screen.dart:1544-1623`

Muestra una miniatura del GIF del ejercicio con tamaño configurable:

| Ubicación | Tamaño | Comportamiento |
|-----------|--------|---------------|
| Buscador de ejercicios (`_BuscadorEjerciciosSheet`) | 48px | Tap → diálogo 280px con GIF a tamaño completo |
| Tarjeta de ejercicio compacta (`_EjercicioCompacto`) | 42px | Tap → mismo diálogo ampliado |

Usa `CachedNetworkImage` con `placeholder` (icono de imagen) y `errorWidget` (icono de pesa). El diálogo de vista ampliada tiene fondo negro semitransparente, borde redondeado 20px, y botón de cierre en la esquina superior derecha.

## 9. Manejo de Errores

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

## 10. Métricas de Rendimiento

| Pantalla | Objetivo | Notas |
|----------|---------|-------|
| Dashboard | < 2s carga inicial | `Future.wait` paraleliza queries |
| Explorador de Ejercicios | < 3s con filtros | Vista materializada `mv_ejercicios_completos` |
| Detalle de Ejercicio | < 1.5s carga GIF R2 | URL pública de R2, sin firma |
| Recomendación IA | < 8s por prompt | Gemini Flash ~2-3s + parsing |
| Interacciones locales | < 300ms | Sin llamadas de red |

## 11. Cobertura de Casos de Uso (v3.0)

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
| **CU-21** | **Check-in diario antes de entrenar** | **RutinaDetalleScreen → _CheckInDialog → LiveSessionScreen** | ✅ |

---

**Documento compilado:** 19-05-2026
**Última revisión:** v4.2
**Referencia:** Alineado con SRS v3.0, Arquitectura v3.1
