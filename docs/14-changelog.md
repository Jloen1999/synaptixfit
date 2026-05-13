# 14 - Historial de Cambios (Changelog)

**Proyecto:** SynaptixFit
**Formato:** [Versionado Semántico](https://semver.org/lang/es/)

---

## [3.4.0] — 14-05-2026

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
- `EjericicioRecienteDto`: `nombreEjercicio`, `pesoPromedio`, `repsPromedio`, `rpePromedio`, `ultimaFecha`

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
