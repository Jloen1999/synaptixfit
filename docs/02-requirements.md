# 02 - Requisitos del Producto (SRS)

Version: 5.1
Estado: COMPLETADO — Panel de administración Fase 1 MVP finalizado
Fecha: 15-06-2026
Referencia cruzada: docs/03-architecture.md, docs/04-data-model.md

## 1. Resumen Ejecutivo

SynaptixFit es una aplicación multiplataforma para estudiantes universitarios que integra organización académica, gamificación de retos y bienestar físico en una sola experiencia. El objetivo es reducir la fragmentación entre apps de estudio, hábitos y comunidad, aumentando la constancia semanal del usuario.

La versión 3.0 incorpora **inteligencia artificial generativa** (Gemini Flash) como entrenador personal digital: genera rutinas personalizadas, sugiere ejercicios, aplica sobrecarga progresiva basada en historial real y adapta el entrenamiento al estado físico diario del usuario mediante un **sistema de check-in de fatiga** y **periodización inteligente automática**.

Este documento define la especificación completa de requisitos (SRS) cubriendo alcance, requisitos funcionales y no funcionales, casos de uso, flujos alternativos, flujos de excepción, reglas de negocio y criterios de aceptación.

## 2. Objetivos del Producto

### 2.1 Objetivo general
Proveer un MVP multiplataforma que permita planificar estudio, registrar progreso personal y reforzar adherencia mediante dinámicas de gamificación, comunidad e inteligencia artificial.

### 2.2 Objetivos específicos
1. Unificar en una sola app planificación académica y bienestar físico.
2. Incrementar la constancia semanal del usuario con recordatorios y seguimiento visible.
3. Incorporar control granular de privacidad por contenido.
4. Sentar una base técnica escalable para fases posteriores.
5. **Ofrecer recomendaciones de entrenamiento personalizadas mediante IA generativa.**
6. **Adaptar el entrenamiento al estado físico y mental diario del usuario.**
7. **Aplicar periodización automática para prevenir sobreentrenamiento y maximizar progreso.**

### 2.3 Métricas de éxito (KPIs)
1. Activación: porcentaje de usuarios que crean su primer plan en menos de 24 horas.
2. Retención semanal: porcentaje de usuarios activos al día 7.
3. Adherencia: porcentaje de usuarios que completan al menos 1 reto y 1 rutina por semana.
4. Interacción social: promedio de likes por publicación de logro.
5. **Adopción IA: porcentaje de rutinas creadas con recomendación IA vs manual.**
6. **Tasa de check-in: porcentaje de sesiones iniciadas con check-in completado.**

## 3. Alcance

### 3.1 Alcance MVP (Fase 1 — COMPLETADO)
1. Registro/login y perfil de usuario.
2. Módulo académico base: asignaturas, planes de estudio, bloques, apuntes Markdown, evaluaciones, calificaciones.
3. Módulo de retos base: retos simples y complejos con hitos, clonación.
4. Módulo bienestar base: catálogo de ejercicios (~1300 ejercicios, 3NF), rutinas, sesiones.
5. Comunidad básica: feed de logros, likes.
6. Notificaciones básicas de recordatorio.
7. **Servicio de IA (Gemini Flash): recomendación de rutinas, ejercicios y progresión.**
8. **Sistema de check-in diario de fatiga con integración IA.**
9. **Periodización inteligente automática con detección de necesidad de descarga.**

### 3.2 Alcance Fase 2 (no bloqueante MVP)
1. Retos complejos con hitos encadenados y dependencias.
2. Comentarios y moderación en feed — Permitir publicar, editar, eliminar comentarios propios. Moderador puede eliminar ajenos. Sistema de reportes.
3. Insignias y rachas avanzadas — Catálogo de 15 insignias con criterios de desbloqueo. Rachas con hitos visuales (7/30/100 días). Riesgo de pérdida de racha.
4. Pomodoro (temporizador de estudio con ciclos work/break) y Escanear (digitalización OCR de apuntes vía cámara).
5. Recomendaciones inteligentes de equilibrio estudio/actividad.
6. Integraciones externas avanzadas (calendarios y wearables).

### 3.3 Fuera de alcance MVP
1. Chat en tiempo real entre usuarios.
2. Marketplace de plantillas.
3. Integración completa con relojes inteligentes.
4. Entrenamiento con vídeos generados por IA.

## 4. Stakeholders y Perfil de Usuario

### 4.1 Stakeholders
1. Estudiante usuario final.
2. Tutor académico (supervisión del TFG).
3. Equipo de desarrollo (frontend/backend).
4. Evaluadores del TFG.
5. **API de Gemini (Google) — proveedor externo de IA.**

### 4.2 Público objetivo
1. Primario: estudiantes universitarios (18-30 años).
2. Secundario: bachillerato y opositores.
3. Perfil común: alta carga académica y necesidad de rutina semanal.

## 5. Fuentes y Hallazgos de Investigación

*(Conservado de v2.9 — secciones 5.1 a 5.7 sin cambios)*

### 5.8 Investigación para integración IA
1. **Modelo seleccionado:** Gemini Flash configurable vía `GEMINI_MODEL` en `.env` (`EnvConfig.geminiModel`); default **`gemini-3.6-flash`** (verificado contra la API real el 31-08-2026). Criterio: equilibrio velocidad/calidad y latencia aceptable (< 3s por prompt) para uso interactivo en entrenamiento. Los modelos hardcodeados anteriores (`gemini-flash-latest`, `gemini-2.x-flash`) fueron retirados por Google (error 404), por lo que todos los servicios de IA construyen la URL dinámicamente.
2. **Prompt engineering:** Se utiliza técnica de "role prompting" (entrenador personal profesional) + "constrained output" (JSON estricto sin Markdown) para garantizar respuestas parseables.
3. **Seguridad biométrica:** El prompt incluye reglas obligatorias basadas en IMC y edad, derivadas de guías clínicas de prescripción de ejercicio (ACSM).
4. **Periodización:** El sistema implementa periodización lineal modificada (adaptación → carga → pico → descarga) basada en literatura de ciencias del deporte (modelo de Matveyev adaptado).

## 6. Requisitos Funcionales

### 6.1 Convenciones
1. Prioridad: MUST (MVP), SHOULD (alto valor), COULD (fase posterior).
2. Todos los requisitos deben tener criterio de aceptación verificable.

*(Secciones 6.2 - 6.4 conservadas de v2.9)*

### 6.5 Módulo bienestar (AMPLIADO v3.0)

#### 6.5.1 Perfil físico y equipamiento
1. RF-BIE-01 (MUST): Registrar perfil físico inicial del estudiante (peso, altura, edad, sexo, nivel de condición, objetivos, equipamiento disponible).
2. RF-BIE-02 (MUST): Registrar contexto de entrenamiento (días disponibles por semana, tiempo por sesión, equipamiento disponible y objetivo principal).

#### 6.5.2 Creación de rutinas y sesiones
3. RF-BIE-03 (MUST): Crear y guardar rutinas periodizadas por objetivo (fuerza, resistencia, hipertrofia, movilidad, fitness_general, perder_peso, ganar_masa).
4. RF-BIE-06 (MUST): Registrar sesión completada con duración real, esfuerzo percibido (RPE 1-10), series ejecutadas (peso, reps reales) en `series_sesion`.
5. RF-BIE-10 (MUST): Mostrar tablero semanal de bienestar con sesiones planificadas vs completadas.
6. RF-BIE-11 (MUST): Buscar, filtrar y seleccionar ejercicios del catálogo normalizado 3NF (~1300 ejercicios).
7. RF-BIE-12 (MUST): Mostrar ficha de ejercicio con GIF animado (R2) e instrucciones.

#### 6.5.3 Recomendación con Inteligencia Artificial (NUEVO v3.0)
8. **RF-BIE-13 (MUST):** El sistema debe generar recomendaciones de metadatos de rutina mediante IA (nombre, descripción, objetivo, duración, estructura semana×día) basándose en el perfil físico, equipamiento, historial y estado diario del usuario.
   - **Criterio:** La IA recibe como entrada: perfil completo (IMC, edad, sexo, objetivo, nivel, equipamiento, días/semana, minutos/sesión), historial de sesiones (RPE promedio, volumen, ejercicios recientes), estado diario (sueño, estrés, energía, dolor) y catálogo de ejercicios filtrado por equipamiento. La respuesta debe ser JSON parseable con estructura semana×día×ejercicios. Si no hay API key configurada, el sistema muestra un error descriptivo sin bloquear la interfaz.

9. **RF-BIE-14 (MUST):** El sistema debe generar sugerencias de ejercicios adicionales para un día específico de entrenamiento (3-6 ejercicios), sin repetir los ya agregados y respetando el equipamiento del usuario.
   - **Criterio:** La IA recibe el catálogo completo filtrado por equipamiento, los ejercicios ya agregados como lista de exclusión, y el contexto del día (número de día, objetivo de la rutina). Devuelve un array JSON con ejercicios y parámetros (series, reps, descanso, peso sugerido).

10. **RF-BIE-15 (MUST):** El sistema debe generar la estructura completa de ejercicios para una rutina ya configurada (semanas × días × ejercicios) aplicando reglas de periodización, seguridad biométrica y alternancia de grupos musculares.
    - **Criterio:** Cada día contiene 4-7 ejercicios. Los grupos musculares se alternan entre días consecutivos. La IA recibe reglas de periodización específicas por semana (adaptación 70%, carga 85-90%, descarga 60%). Si el historial muestra signos de fatiga, la primera semana es de descarga activa.

11. **RF-BIE-16 (MUST):** El sistema debe sugerir progresión de carga para un ejercicio específico (sobrecarga progresiva) basándose en el historial real del usuario (peso, reps, RPE de sesiones previas).
    - **Criterio:** La progresión sigue reglas objetivas: RPE < 7 → subir peso 5-10% o +1-2 reps; RPE 7-8 → subir 2.5-5%; RPE 8.5-9.5 → mantener; RPE = 10 → no subir. El objetivo de la rutina modula la prioridad (fuerza → peso, hipertrofia → equilibrio, resistencia → reps).

#### 6.5.4 Check-in diario de fatiga (NUEVO v3.0)
12. **RF-BIE-17 (MUST):** El sistema debe permitir al usuario registrar su estado físico y mental antes de cada sesión de entrenamiento mediante un check-in diario con 4 indicadores (calidad del sueño, nivel de estrés, nivel de energía, dolor muscular) en escala 1-5.
    - **Criterio:** El diálogo de check-in se muestra automáticamente al pulsar "Empezar entrenamiento" en la sesión en vivo. El usuario puede omitirlo. Si el dolor muscular es ≥ 3, se muestran chips adicionales para seleccionar zonas de dolor (piernas, espalda, hombros, brazos, pecho, core). Los datos se persisten mediante upsert por usuario+fecha (un solo registro por día).

13. **RF-BIE-18 (MUST):** El sistema debe calcular una puntuación compuesta de fatiga (0-100) basada en los 4 indicadores del check-in, y determinar si el usuario requiere adaptación del entrenamiento (puntuación > 50).
    - **Criterio:** La fórmula es: `(6-sueño)×5 + (estrés-1)×5 + (6-energía)×4 + (dolor-1)×7`, limitada a 0-100. Cuando `requiereAdaptacion == true`, la IA recibe instrucciones de reducir volumen un 30% y evitar ejercicios en las zonas con dolor.

14. **RF-BIE-19 (SHOULD):** El sistema debe mostrar un aviso visual (banner naranja) en la pantalla pre-sesión cuando se detecta fatiga alta, informando al usuario que se recomienda un entrenamiento más ligero.

#### 6.5.5 Periodización inteligente (NUEVO v3.0)
15. **RF-BIE-20 (MUST):** El sistema debe asignar automáticamente un tipo de semana a cada semana de la rutina según reglas de periodización: semana 1 = adaptación, semanas intermedias = carga, semana 3 (de 3) = pico, última semana (de 4+) = descarga.
    - **Criterio:** La asignación ocurre en `crearRutinaCompleta()` al insertar cada `semanas_rutina`. La columna `tipo_semana` acepta: `adaptacion`, `carga`, `pico`, `descarga`. El frontend muestra badges de colores (azul=adapt, verde=carga, naranja=pico, teal=desc).

16. **RF-BIE-21 (MUST):** El sistema debe detectar automáticamente la necesidad de una semana de descarga basándose en: RPE promedio > 8.0 sostenido durante 3+ semanas con volumen decreciente, O puntuación de fatiga diaria > 50.
    - **Criterio:** El algoritmo analiza las sesiones de las últimas 3 semanas (RPE, duración), calcula volumen por semana, detecta tendencia decreciente y cruza con el check-in diario. El resultado se expone vía `estadoPeriodizacionProvider`.

#### 6.5.6 Catálogo de ejercicios y multimedia
*(RF-BIE-11, RF-BIE-12 conservados)*

#### 6.5.7 Mini normas de bienestar
1. **Norma de recomendación IA:** La IA nunca recomienda ejercicios fuera del equipamiento del usuario. Si el usuario solo tiene "peso_corporal", no se sugieren ejercicios con barra, mancuerna o máquina. La validación de compatibilidad ocurre en cliente (`_ejercicioUsaEquipamiento`) antes de enviar el catálogo al prompt.
2. **Norma de seguridad biométrica:** IMC > 30 → evitar saltos pliométricos y carga lumbar excesiva. IMC < 18.5 → evitar déficit calórico extremo. Edad > 50 → priorizar fortalecimiento articular, evitar 1RM. Edad < 18 → priorizar técnica sobre carga.
3. **Norma de check-in:** El check-in es opcional pero recomendado. Si se omite, la IA no recibe datos de fatiga y genera recomendaciones sin adaptación. El usuario puede hacer check-in una sola vez por día (upsert).
4. **Norma de periodización:** Rutinas de 1 semana usan solo tipo "carga". La progresión entre semanas es controlada por la IA dentro de los rangos del tipo de semana. La detección de descarga es sugerencia, no imposición.

### 6.6 Comunidad
*(Conservado de v2.9)*

### 6.7 Notificaciones
*(Conservado de v2.9)*

### 6.8 Analítica y autorregulación académica
*(Conservado de v2.9)*

### 6.9 Seguridad de bienestar y uso responsable
*(Conservado de v2.9)*

## 7. Casos de Uso Detallados

*(CU-01 a CU-15 conservados de v2.9)*

### 7.16 CU-16 Configurar perfil físico y objetivo de entrenamiento
*(Conservado de v2.9)*

### 7.17 CU-17 Generar plan semanal de entrenamiento recomendado
*(Conservado de v2.9)*

### 7.18 CU-18 Recalcular plan por adherencia y fatiga
*(Conservado de v2.9)*

### 7.19 CU-19 Buscar y seleccionar ejercicios para una rutina
*(Conservado de v2.9)*

### 7.20 CU-20 Crear rutina con recomendación IA (ACTUALIZADO v5.0)

1. **Actor principal:** Estudiante.
2. **Precondiciones:** Usuario autenticado, perfil de bienestar configurado. La API key de Gemini (`GEMINI_API_KEY`) es opcional — sin ella, el motor de reglas determinista funciona igual.
3. **Disparador:** El usuario accede a "Nueva rutina" y pulsa "⚡ Generar rutina rápida" o "✨ Recomendar rutina con IA" en el Paso 1.
4. **Flujo principal (motor determinista):**
   1. El sistema sanitiza el objetivo con `sanitizarObjetivo()`.
   2. El sistema determina el split de entrenamiento según días/semana y nivel de actividad.
   3. El sistema selecciona ejercicios mediante 5 filtros encadenados + scoring ponderado.
   4. El sistema aplica ajustes de contexto (modo exámenes, FCT, racha, fatiga, tendencia de peso).
   5. El sistema aplica transición de objetivo si el usuario cambió recientemente.
   6. El sistema calcula sobrecarga progresiva basada en historial real.
   7. El sistema rellena automáticamente los campos del formulario Paso 1 y la estructura completa (semanas × días × ejercicios).
5. **Flujo alternativo (con refinamiento IA):**
   - Si el usuario tiene API key configurada y pulsa "✨ Recomendar rutina con IA", tras el pipeline determinista se ejecuta `refinarRutina()` con Gemini para mejorar nombres, variar ejercicios y reordenar.
6. **Flujo de excepción:**
   - E1 — Sin ejercicios compatibles con el equipamiento: mostrar error específico con el equipamiento listado.
   - E2 — Gemini no responde o timeout: se usa la estructura del motor de reglas sin refinar.
   - E3 — Gemini devuelve ejercicios inválidos: `_validarYReparar()` revierte al ejercicio original del motor de reglas.
7. **Postcondiciones:** Metadatos de rutina rellenos, estructura completa de ejercicios rellena. El usuario puede continuar al Paso 2 o 3.
8. **Requisitos relacionados:** RF-BIE-13, RF-BIE-14, RF-BIE-15, RF-BIE-22, RF-BIE-23.

### 7.21 CU-21 Realizar check-in diario antes de entrenar (NUEVO v3.0)

1. **Actor principal:** Estudiante.
2. **Precondiciones:** Usuario autenticado, día de entrenamiento con ejercicios asignados.
3. **Disparador:** El usuario pulsa "Empezar entrenamiento" en `RutinaDetalleScreen`.
4. **Flujo principal:**
   1. El sistema muestra el diálogo `_CheckInDialog` con 4 sliders (1-5): calidad del sueño, nivel de estrés, nivel de energía, dolor muscular.
   2. Si el slider de dolor muscular ≥ 3, se muestran chips de selección múltiple para zonas de dolor (piernas, espalda, hombros, brazos, pecho, core).
   3. El usuario ajusta los sliders y toca "Empezar".
   4. El sistema calcula `listoParaEntrenar = sueño > 1 OR energía > 2`.
   5. El sistema persiste el check-in vía `guardarEstadoDiario()` (upsert por usuario+fecha).
   6. El sistema invalida `estadoDiarioHoyProvider` para que la IA consuma los datos actualizados.
   7. El sistema inicia la sesión con `iniciarSesion()` y navega a `LiveSessionScreen`.
5. **Flujo alternativo:**
   - A1 — El usuario pulsa "Omitir": se inicia la sesión sin check-in. La IA no recibe datos de fatiga para esta sesión.
   - A2 — El usuario ya hizo check-in hoy: se carga el check-in existente y se muestra en el diálogo para posible edición.
6. **Flujo de excepción:**
   - E1 — Error de conexión al persistir: se muestra toast de error y se permite continuar sin guardar.
   - E2 — Usuario no autenticado: no se muestra el diálogo.
7. **Postcondiciones:** Check-in persistido (o sesión iniciada sin check-in). El estado diario está disponible para la IA.
8. **Requisitos relacionados:** RF-BIE-17, RF-BIE-18, RF-BIE-19.

## 8. Requisitos No Funcionales
*(Conservado de v2.9 con adiciones)*

### 8.1 Plataforma y arquitectura
*(Sin cambios)*

### 8.2 Seguridad y privacidad
*(Sin cambios)*

### 8.3 Rendimiento (AMPLIADO)
1. RNF-REN-01: Carga inicial ≤ 3 s en móvil gama media con red estable.
2. RNF-REN-02: Interacciones locales frecuentes ≤ 300 ms.
3. RNF-REN-03: Feed paginado para controlar memoria y latencia.
4. **RNF-REN-04: Respuesta de IA (Gemini) ≤ 8 s por prompt. Timeout de 15 s con Dio.**

### 8.4 Confiabilidad
*(Sin cambios)*

### 8.5 Accesibilidad y UX
*(Sin cambios)*

### 8.6 Mantenibilidad y calidad
*(Sin cambios)*

### 8.7 Observabilidad y operación
*(Sin cambios)*

### 8.8 Salvaguardas de bienestar (AMPLIADO)
1. RNF-SAF-01: Evitar lenguaje punitivo en mensajes de incumplimiento.
2. RNF-SAF-02: Incluir mecanismos para reducir presión social (ocultar rachas, desactivar autopost).
3. RNF-SAF-03: Mantener separación explícita entre recomendaciones de bienestar y consejo clínico.
4. **RNF-SAF-04: La IA debe incluir un disclaimer en el prompt recordando que es un entrenador virtual y no sustituye evaluación profesional.**
5. **RNF-SAF-05: Las recomendaciones de peso/carga de la IA usan `null` por defecto. Solo se sugieren pesos concretos cuando existe historial real del usuario.**

## 9. Reglas de Negocio
*(RB-01 a RB-20 conservados de v2.9)*

21. **RB-21:** La IA solo recomienda ejercicios cuyo equipamiento sea compatible con el equipamiento declarado por el usuario. La validación ocurre en cliente antes de enviar el prompt.
22. **RB-22:** El check-in diario es único por usuario y fecha (upsert). Un nuevo check-in en el mismo día sobrescribe el anterior.
23. **RB-23:** La periodización asigna automáticamente el tipo de semana. El usuario no puede cambiarlo manualmente.
24. **RB-24:** La detección de necesidad de descarga es una sugerencia, no una imposición. El usuario puede ignorarla.
25. **RB-25:** Las respuestas de la IA siempre se parsean como JSON. Si el parsing falla, se muestra un error genérico sin exponer detalles internos del modelo.

## 10. Requisitos de Datos y Trazabilidad

### 10.1 Entidades mínimas
*(Conservado de v2.9)*

Añadidas en v3.0:
- `semanas_rutina` (con `tipo_semana`)
- `dias_rutina`
- `series_sesion`
- `estado_diario_usuario`

### 10.2 Trazabilidad de eventos clave
*(Conservado de v2.9)*

Añadidos en v3.0:
- Check-in diario completado/omitido.
- Recomendación IA solicitada (metadatos, estructura completa, sugerencia por día).
- Error de parsing JSON de IA.
- Detección de necesidad de descarga.

## 11. Requisitos de Integración (AMPLIADO)
*(RI-01 a RI-10 conservados)*

11. **RI-11:** Integración con Gemini Flash API (`generativelanguage.googleapis.com`) vía HTTP POST con `X-goog-api-key`. No se usa SDK de Google; se usa `dio` para peticiones HTTP directas.
12. **RI-12:** La API key de Gemini se lee de `GEMINI_API_KEY` en `.env` mediante `EnvConfig.geminiApiKey`. Si no está configurada, los métodos de IA devuelven un resultado con error descriptivo sin lanzar excepción.

## 12. Historias de Usuario (AMPLIADO)
*(HU-01 a HU-32 conservadas)*

33. **HU-33:** Como estudiante quiero que la IA me recomiende una rutina completa basada en mi perfil y equipamiento para no tener que diseñarla desde cero.
34. **HU-34:** Como estudiante quiero que la IA me sugiera ejercicios adicionales para un día sin repetir los que ya tengo.
35. **HU-35:** Como estudiante quiero que la IA analice mi historial y me diga cuánto peso añadir esta semana.
36. **HU-36:** Como estudiante quiero registrar cómo me siento antes de entrenar (sueño, estrés, dolor) para que la IA adapte mi entrenamiento.
37. **HU-37:** Como estudiante quiero ver de un vistazo en qué fase de periodización estoy (adaptación, carga, pico, descarga).
38. **HU-38:** Como estudiante quiero que la app me avise cuando detecte que necesito una semana de descanso.

## 13. Criterios de Aceptación Global del MVP (AMPLIADO)
*(CA-01 a CA-13 conservados)*

14. **CA-14:** El usuario puede crear una rutina completa (metadatos + estructura de ejercicios) con 1 clic: "⚡ Generar rutina rápida" (motor determinista, <2s). Opcionalmente, con "✨ Recomendar rutina con IA" se añade refinamiento IA.
15. **CA-15:** La IA nunca recomienda ejercicios que requieran equipamiento no declarado por el usuario.
16. **CA-16:** El check-in diario se persiste correctamente y la puntuación de fatiga se calcula según la fórmula documentada.
17. **CA-17:** Los badges de tipo de semana se muestran correctamente en el selector de semanas con los colores asignados.

### CU-22 Dashboard Rediseñado (v6.0)

**Actor:** Usuario autenticado
**Precondición:** Sesión activa, datos de bienestar y academia cargados
**Flujo principal:**
1. El usuario abre la app y ve el dashboard rediseñado con layout de cards
2. SaludoCard muestra avatar, nivel, XP y streaks (🔥 entrenamiento + 🧠 estudio)
3. SmartBannerCard muestra consejo IA generado por Gemini o fallback
4. QuickActionsRow ofrece 4 accesos rápidos (Pomodoro, Workout, Escanear, Nuevo reto)
5. PlanWeekBar muestra "Semana X de Y" si hay rutina activa
6. CognitiveLoadBar muestra el nivel de carga cognitiva actual
7. EstadoSection muestra 3 MetricGauges (Energético, Adherencia, Carga Cognitiva)
8. Secciones de KPIs, Bienestar, Retos y Rutinas completan el dashboard
**Postcondición:** El usuario puede navegar a cualquier sección desde los accesos rápidos o las cards.

### HU-39 — Progreso semanal
Como estudiante quiero ver de un vistazo mi progreso semanal ("Semana X de Y") para planificar mi día.

### HU-40 — Consejo IA
Como estudiante quiero recibir un consejo personalizado de IA al abrir la app para motivarme.

### HU-41 — Acceso rápido
Como estudiante quiero acceder rápido a Pomodoro, Workout y Nuevo Reto desde el inicio.

### CA-18 — SmartBanner se muestra on-load
El SmartBanner debe mostrar un consejo (Gemini o fallback) al cargar el dashboard sin bloquear otros widgets.

### CA-19 — QuickActions funcionales
Workout debe navegar a sesión en vivo, Nuevo Reto a la pantalla de creación de retos (`/retos/crear`). Pomodoro y Escanear muestran placeholder.

### CA-20 — PlanWeekBar condicional
Solo se muestra si hay rutina activa. Si no, se oculta sin afectar el layout.

### CA-21 — CognitiveLoadBar condicional
Solo se muestra si hay datos académicos. Si no, se oculta sin afectar el layout.

### CU-23 Línea de Tiempo Enriquecida con 3 Tabs (v6.2)

**Actor:** Usuario autenticado
**Precondición:** Sesión activa, datos de academia y bienestar cargados
**Flujo principal:**
1. El usuario abre el dashboard y ve la sección "Línea de tiempo" con 3 pestañas
2. Tab "Hoy" muestra bloques académicos del día, sesiones completadas y entrenamiento pendiente destacado
3. Tab "Semana" muestra entregas de los próximos 7 días agrupadas cronológicamente
4. Tab "Retos" muestra retos activos con barra de progreso y días restantes
5. El entrenamiento pendiente se destaca con una tarjeta naranja y botón "Comenzar" que navega a sesión en vivo
**Postcondición:** El usuario puede planificar su día desde cualquier tab y acceder rápido a su entrenamiento.

### HU-42 — Entrenamiento pendiente destacado
Como estudiante quiero ver mi próximo entrenamiento pendiente destacado en la timeline para no perdérmelo.

### HU-43 — Retos activos integrados
Como estudiante quiero ver mis retos activos integrados en la timeline para seguir su progreso sin salir del dashboard.

### HU-44 — Entregas próximos 7 días
Como estudiante quiero ver las entregas de los próximos 7 días para planificar mi semana.

### CA-22 — Tab "Hoy" completo
El tab "Hoy" debe mostrar bloques académicos + sesiones + entrenamiento pendiente destacado, ordenados cronológicamente.

### CA-23 — Tab "Semana" con entregas
El tab "Semana" debe mostrar entregas de los próximos 7 días agrupadas cronológicamente, con máximo 7 items.

### CA-24 — Tab "Retos" con progreso
El tab "Retos" debe mostrar retos activos con barra de progreso porcentual y días restantes, con máximo 5 items.

### CU-24 Retos con dependencias entre hitos

**Actor:** Usuario autenticado
**Precondición:** Usuario en pantalla de detalle de un reto con hitos
**Flujo principal:**
1. El usuario ve el grafo de dependencias de hitos con nodos coloreados por estado
2. El sistema muestra los hitos bloqueados con candado y la condición requerida (AND/OR/X_OF_Y)
3. Al completar un hito, el trigger `trg_hito_completado` evalúa las dependencias y desbloquea los hitos posteriores
4. El usuario solo puede iniciar hitos en estado `disponible`
5. El grafo se actualiza en tiempo real reflejando los nuevos estados
**Flujo alternativo:**
- A1 — Condición X_OF_Y (ej. 2 de 3): el hito se desbloquea cuando se cumple el número requerido de predecesores completados
- A2 — Red de dependencias compleja: el sistema navega el grafo de dependencias recursivamente para determinar transitivamente qué hitos son alcanzables
**Postcondición:** Los hitos se desbloquean automáticamente al cumplir sus condiciones. El progreso del reto refleja el estado real de cada hito.

### CU-25 Dashboard de analítica de rendimiento

**Actor:** Usuario autenticado
**Precondición:** Usuario con historial de entrenamiento (sesiones registradas) y datos académicos
**Flujo principal:**
1. El usuario accede a la nueva sección "Analítica" en el dashboard o desde navegación
2. El sistema muestra tabs: Semanal, Mensual, Insights
3. Tab Semanal: gráficos de tendencia RPE (LineChart), volumen semanal (BarChart), calorías por sesión
4. Tab Mensual: agregación mensual con comparativa intermensual
5. Tab Insights: correlaciones generadas (carga académica vs RPE, sueño vs rendimiento) con IA (Gemini)
6. Los gráficos usan `fl_chart` (LineChart, BarChart, ScatterChart)
**Flujo alternativo:**
- A1 — Sin datos suficientes: mostrar estado vacío con mensaje "Completa más sesiones para ver tu analítica"
- A2 — Sin API key de Gemini: los insights se generan con reglas deterministas (tendencias simples)
**Postcondición:** El usuario puede visualizar su progreso histórico, identificar patrones y recibir recomendaciones basadas en datos.

### CU-26 Sincronización offline

**Actor:** Usuario autenticado
**Precondición:** App abierta con o sin conexión a internet
**Flujo principal:**
1. El sistema detecta el estado de red vía `connectivity_plus`
2. Con conexión: operaciones normales contra Supabase
3. Sin conexión: la app sigue funcionando con datos cacheados en Hive
4. Las mutaciones (crear/editar/eliminar) se encolan en `offline_queue` (Hive box)
5. Al reconectar: `sync_merge_engine.dart` procesa la cola en orden FIFO
6. Conflictos se resuelven con estrategia last-write-wins (timestamp de operación)
7. Un indicador visual (`OfflineIndicator`) muestra el estado de conexión y operaciones pendientes
**Flujo alternativo:**
- A1 — Cola llena (>50 operaciones): advertir al usuario y sugerir conectar
- A2 — Conflicto irresoluble: notificar al usuario y permitir elegir versión (local vs remota)
**Flujo de excepción:**
- E1 — Reconexión intermitente: el sistema espera conexión estable (>3s) antes de sincronizar
- E2 — Error de merge: se notifica al usuario y se preserva la operación en cola para reintento
**Postcondición:** Los datos del usuario están sincronizados con el servidor. Las operaciones offline se integran sin pérdida de datos.

### CU-27 — Pomodoro (temporizador de estudio)
**Prioridad:** MUST
**Actor:** Estudiante
**Precondición:** Usuario autenticado en el dashboard.
**Flujo principal:**
1. El usuario pulsa "Pomodoro" en QuickActions del dashboard.
2. El sistema muestra la pantalla de temporizador con anillo de progreso circular.
3. El usuario pulsa "Iniciar" → comienza ciclo work de 25 min.
4. Al completar work, el sistema notifica y transiciona automáticamente a descanso corto de 5 min.
5. Tras 4 ciclos work completados, el descanso es largo (15 min).
6. El usuario puede pausar, reanudar, reiniciar o saltar descanso en cualquier momento.
7. Cada sesión focus completada se registra en `sesiones_pomodoro`.
**Postcondición:** Sesión Pomodoro registrada. El usuario vuelve al dashboard o continúa otro ciclo.

### CU-28 — Escanear apuntes con OCR
**Prioridad:** SHOULD
**Actor:** Estudiante
**Precondición:** Usuario autenticado. Dispositivo móvil (Android/iOS). Permiso de cámara concedido.
**Flujo principal:**
1. El usuario pulsa "Escanear" en QuickActions del dashboard.
2. El sistema abre la cámara con overlay de guía de escaneo.
3. El usuario captura una imagen del documento/apunte.
4. El sistema procesa la imagen con OCR (ML Kit) y extrae el texto.
5. El usuario previsualiza el texto extraído y selecciona una asignatura destino.
6. El sistema guarda el texto como apunte Markdown en la tabla `apuntes`.
**Flujo alternativo (Web):**
- E1 — Plataforma Web: el sistema muestra mensaje "Esta función requiere la app móvil".
**Postcondición:** Apunte creado con el texto extraído. Visible en la sección de apuntes del usuario.

### CU-29 — Comentarios en feed social
**Prioridad:** MUST
**Actor:** Estudiante
**Precondición:** Usuario autenticado. Existe al menos una publicación en el feed.
**Flujo principal:**
1. El usuario ve una publicación en el feed social.
2. El usuario pulsa el botón de comentarios → se expande la sección de comentarios.
3. El usuario escribe un comentario (1-500 caracteres) y pulsa enviar.
4. El sistema guarda el comentario en `comentarios_feed` y lo muestra en tiempo real.
5. El autor de la publicación recibe una notificación de nuevo comentario.
**Flujo alternativo:**
- E1 — Editar: el usuario pulsa "Editar" en su propio comentario, modifica el texto y confirma. Se actualiza `editado_en`.
- E2 — Eliminar: el usuario pulsa "Eliminar" en su propio comentario. Se marca `eliminado = true` (soft delete).
**Postcondición:** Comentario visible en la publicación. Notificación enviada al autor.

### CU-30 — Insignias y rachas avanzadas
**Prioridad:** MUST
**Actor:** Estudiante
**Precondición:** Usuario autenticado. Existen 15 insignias en el catálogo.
**Flujo principal:**
1. El usuario completa una acción que cumple un criterio de insignia (ej: 1ª sesión).
2. El `InsigniaEngine` evalúa los criterios y detecta que se cumple "Primeros pasos".
3. El sistema otorga la insignia (INSERT en `usuario_insignias`) y muestra toast animado "¡Nueva insignia!".
4. El usuario puede ver su colección en `/insignias` — grid con obtenidas a color y bloqueadas en gris.
5. El sistema muestra la racha actual con indicador de progreso hacia el próximo hito (7/30/100 días).
6. Si quedan <4h para perder la racha, el sistema notifica "¡No pierdas tu racha!".
**Postcondición:** Insignia otorgada y notificada. Racha actualizada.

### HU-45 — Hitos bloqueados visibles
Como estudiante quiero ver qué hitos están bloqueados y qué necesito completar para desbloquearlos, para planificar mi progreso en el reto.

### HU-46 — Gráficos de rendimiento
Como estudiante quiero ver gráficos de mi rendimiento (RPE, volumen, calorías) para entender mi progreso semanal y mensual.

### HU-47 — Insights inteligentes
Como estudiante quiero recibir insights generados sobre mi rendimiento (ej. "cuando duermes más de 7h, tu RPE baja 1 punto") para optimizar mi entrenamiento.

### HU-48 — App funcional sin internet
Como estudiante quiero poder usar la app sin conexión (registrar sesiones, ver mi rutina) y que sincronice automáticamente al reconectar.

### HU-49 — Indicador de estado offline
Como estudiante quiero ver un indicador claro de si estoy offline y cuántas operaciones pendientes tengo, para saber si mis datos están sincronizados.

### HU-50 — Resolución de conflictos transparente
Como estudiante quiero que la app resuelva conflictos de sincronización automáticamente sin que yo tenga que preocuparme, y solo pedirme intervenir en casos excepcionales.

### HU-51 — Temporizador Pomodoro para estudio
Como estudiante quiero usar un temporizador Pomodoro con ciclos de concentración (25 min) y descanso (5 min) para gestionar mis sesiones de estudio de forma eficaz.

### HU-52 — Escanear apuntes con la cámara
Como estudiante quiero digitalizar mis apuntes en papel usando la cámara del móvil para tenerlos disponibles en la app sin tener que transcribirlos manualmente.

### HU-53 — Comentar logros de compañeros
Como estudiante quiero comentar las publicaciones de logros de mis compañeros en el feed social para felicitarlos e interactuar con la comunidad.

### HU-54 — Editar y eliminar mis comentarios
Como estudiante quiero poder editar o eliminar un comentario que haya publicado si me equivoco o ya no refleja lo que quiero decir.

### HU-55 — Coleccionar insignias por mis logros
Como estudiante quiero desbloquear insignias al alcanzar hitos (primer entrenamiento, 10 sesiones, racha de 7 días) y ver mi colección en el perfil.

### HU-56 — Ver mi racha con hitos visuales
Como estudiante quiero ver mi racha actual de días consecutivos con actividad, cuántos días faltan para el próximo hito (7/30/100) y recibir alertas si estoy en riesgo de perderla.

### CA-25 — Grafo de dependencias funcional
El grafo de dependencias debe mostrar nodos coloreados por estado (rojo=bloqueado, azul=disponible, amarillo=en_progreso, verde=completado) con aristas que muestren la condición (AND/OR/X_OF_Y).

### CA-26 — Charts de analítica renderizados
Los gráficos Semanal y Mensual deben renderizarse con `fl_chart` mostrando datos reales del usuario. Sin datos, mostrar estado vacío.

### CA-27 — Cola offline funcional
Al desconectar internet, las operaciones de escritura deben encolarse automáticamente. Al reconectar, deben sincronizarse sin intervención del usuario.

### CA-28 — OfflineIndicator visible
El widget `OfflineIndicator` debe ser visible en todas las pantallas principales cuando no hay conexión, mostrando un badge con el número de operaciones pendientes.

### CA-29 — Pomodoro funcional
El temporizador debe mostrar un anillo de progreso circular con el tiempo restante. Los botones Iniciar, Pausar, Reanudar y Reiniciar deben responder en <200ms. Al completar un ciclo work, debe sonar una notificación y transicionar automáticamente a descanso. Las sesiones completadas deben persistir en `sesiones_pomodoro`.

### CA-30 — Escanear funcional
La cámara debe abrirse al pulsar "Escanear". La imagen capturada debe procesarse con OCR y mostrar el texto extraído en <3s. La precisión de OCR debe ser >80% en texto impreso en español. El resultado debe poder guardarse como apunte en una asignatura. En Web, debe mostrarse un mensaje informativo sin crashear.

### CA-31 — Comentarios funcionales con RLS
Los comentarios deben aparecer bajo cada publicación ordenados cronológicamente. Solo el autor puede editar o eliminar su comentario. El texto debe limitarse a 500 caracteres. Al publicar un comentario, el autor de la publicación debe recibir una notificación.

### CA-32 — Insignias y rachas visibles
El catálogo de 15 insignias debe ser visible en `/insignias`. Las obtenidas se muestran a color con fecha; las bloqueadas en gris con candado. Al desbloquear una insignia, debe mostrarse un toast animado. La racha actual debe mostrar días consecutivos y progreso hacia el próximo hito (barra de progreso). Si quedan <4h para perder la racha, debe enviarse una notificación.

### CU-31 — Panel de administración: Wipe de datos de usuario (NUEVO v5.0)

**Actor:** Administrador del sistema (rol `admin` en `usuarios.rol`)
**Precondición:** Usuario administrador autenticado. Usuario objetivo identificado por `id`.
**Flujo principal:**
1. El administrador accede al panel de administración y busca al usuario por email o id.
2. El administrador pulsa "Wipe de datos" en la ficha del usuario.
3. El sistema muestra un diálogo de confirmación con el resumen de lo que se conservará y lo que se eliminará.
4. El administrador confirma escribiendo el email del usuario.
5. El sistema ejecuta `wipe_user_data(p_usuario_id)` que:
   - **Conserva:** `id`, `email`, `nombre_completo`, `url_avatar`, `rol`, `nivel_privacidad`, `creado_en`, `perfil_bienestar_usuario`, `perfil_academico_usuario`, `usuario_carreras`
   - **Resetea:** `nivel` → 1, `xp_total` → 0, `racha_actual` → 0
   - **Elimina:** `sesiones_registradas`, `series_sesion`, `rutinas` (CASCADE → `semanas_rutina`, `dias_rutina`, `seleccion_de_ejercicios`), `retos` (CASCADE → `hitos_de_reto`, `progreso_de_reto`), `planes_estudio` (CASCADE → `horarios_academicos`), `apuntes`, `estado_diario_usuario`, `actividades_sociales` (CASCADE → `interacciones_sociales`), `notificaciones`, `usuario_insignias`, `historial_peso`, `historial_objetivos`, `recomendaciones_pendientes`, `insights_analitica`, `sesiones_focus`, `carga_academica_semanal`
6. El sistema muestra un toast de confirmación: "Datos de [email] eliminados correctamente. Usuario reseteado a nivel 1."
**Flujo alternativo:**
- A1 — El administrador cancela la confirmación: no se ejecuta ninguna acción.
- A2 — El usuario objetivo no existe: se muestra error "Usuario no encontrado".
**Flujo de excepción:**
- E1 — Error de BD durante el wipe: se muestra el error y se hace rollback de la transacción.
- E2 — El administrador intenta hacer wipe de su propio usuario: se bloquea la acción con mensaje "No puedes eliminar tus propios datos".
**Postcondiciones:** El usuario objetivo conserva sus datos personales y de perfil, pero todo su historial de actividad es eliminado. Los valores dinámicos (nivel, XP, racha) son reseteados. El usuario ve la app como si acabara de registrarse.

### HU-57 — Conservar datos personales en wipe
Como administrador quiero que al hacer wipe de un usuario se conserven sus datos personales estáticos (email, nombre, avatar, preferencias de perfil) para no tener que recrear manualmente su cuenta.

### HU-58 — Resetear valores dinámicos en wipe
Como administrador quiero que al hacer wipe de un usuario se resetee su nivel a 1, su XP a 0 y su racha a 0 para que el usuario comience desde cero sin perder su identidad.

### HU-59 — Eliminar historial completo en wipe
Como administrador quiero que al hacer wipe de un usuario se elimine todo su historial de actividad (sesiones, rutinas, retos, apuntes, publicaciones, comentarios, notificaciones, insignias) para cumplir con solicitudes de privacidad o corrección de datos corruptos.

### HU-60 — Política de wipe solo datos dinámicos
Como administrador quiero eliminar todo el historial de un usuario y resetear sus valores dinámicos (nivel, XP, racha) preservando solo sus datos personales y perfil, para mantener la integridad de la cuenta mientras se limpia su actividad.

### CA-33 — Wipe conserva datos personales
Tras ejecutar el wipe, el usuario debe conservar: `id`, `email`, `nombre_completo`, `url_avatar`, `rol`, `nivel_privacidad`, `creado_en`, y los registros en `perfil_bienestar_usuario`, `perfil_academico_usuario` y `usuario_carreras`.

### CA-34 — Wipe resetea valores dinámicos
Tras ejecutar el wipe, `usuarios.nivel` debe ser 1, `usuarios.xp_total` debe ser 0 y `usuarios.racha_actual` debe ser 0.

### CA-35 — Usuario ve la app como recién registrado
El usuario afectado ve su app como si acabara de registrarse: nivel 1, XP 0, racha 0, sin rutinas, sin sesiones, sin retos, sin apuntes, sin publicaciones, sin insignias. Mantiene su email, nombre, avatar y preferencias de perfil (bienestar, académico, carreras).

### CU-32 — Dashboard de métricas globales (NUEVO v5.1)

**Actor:** Administrador del sistema (rol `admin`)
**Precondición:** Usuario administrador autenticado. Vista `v_admin_metricas` creada en BD.
**Flujo principal:**
1. El administrador accede al panel de administración → pestaña "KPIs".
2. El sistema muestra un grid 2×3 con 6 KPIs principales: total usuarios, nuevos esta semana, usuarios activos semana, sesiones esta semana, retos creados semana, nivel promedio.
3. El administrador ve un gráfico de registros diarios (últimos 30 días) debajo de los KPIs.
4. Los KPIs se actualizan en tiempo real al recargar la pestaña.
**Flujo alternativo:**
- A1 — Sin datos: se muestra "Sin datos disponibles" con icono informativo.
**Postcondiciones:** El administrador puede monitorear la salud global de la plataforma.

### CU-33 — Moderación de contenido (NUEVO v5.1)

**Actor:** Administrador del sistema (rol `admin`)
**Precondición:** Usuario administrador autenticado. Existen publicaciones o comentarios reportados.
**Flujo principal:**
1. El administrador accede al panel → pestaña "Contenido".
2. El sistema lista publicaciones y comentarios marcados como `reportado = true`.
3. El administrador revisa el contenido reportado y decide:
   - **Ocultar publicación:** soft delete (`esta_eliminado = true`). El contenido desaparece del feed público.
   - **Restaurar publicación:** revertir soft delete. El contenido vuelve a ser visible.
   - **Eliminar comentario:** soft delete del comentario reportado.
4. Cada acción de moderación se registra en `admin_auditoria` con `accion = 'moderar'` y detalles en JSONB.
**Postcondiciones:** El contenido inapropiado es ocultado de la plataforma. Se mantiene trazabilidad de las acciones de moderación.

### CU-34 — Catálogo de ejercicios admin (NUEVO v5.1)

**Actor:** Administrador del sistema (rol `admin`)
**Precondición:** Usuario administrador autenticado. Catálogo de ejercicios poblado.
**Flujo principal:**
1. El administrador accede al panel → pestaña "Ejercicios".
2. El sistema lista el catálogo completo con toggle `activo`/`inactivo` por ejercicio.
3. El administrador puede ocultar un ejercicio (desmarcar `activo = false`) — el ejercicio deja de aparecer en búsquedas y recomendaciones IA.
4. El administrador puede reactivar un ejercicio (marcar `activo = true`).
5. Cada cambio se registra en `admin_auditoria` con `accion = 'ocultar_ejercicio'`.
**Postcondiciones:** El catálogo se adapta sin eliminar ejercicios. Los usuarios solo ven ejercicios con `activo = true`.

### CU-35 — Logs de auditoría (NUEVO v5.1)

**Actor:** Administrador del sistema (rol `admin`)
**Precondición:** Usuario administrador autenticado. Tabla `admin_auditoria` con registros.
**Flujo principal:**
1. El administrador accede al panel → pestaña "Logs".
2. El sistema muestra los registros de auditoría en orden cronológico inverso.
3. Cada entrada muestra: admin que ejecutó, usuario afectado, acción, detalles (JSONB), fecha/hora.
4. El administrador puede filtrar por tipo de acción o por admin.
**Postcondiciones:** Todas las acciones administrativas quedan registradas con trazabilidad completa.

### HU-61 — Ver métricas globales
Como administrador quiero ver un dashboard con métricas globales (usuarios totales, nuevos, activos, sesiones, retos) para monitorear la salud de la plataforma.

### HU-62 — Moderar publicaciones reportadas
Como administrador quiero ver las publicaciones reportadas por la comunidad y poder ocultarlas o restaurarlas para mantener un entorno seguro.

### HU-63 — Moderar comentarios reportados
Como administrador quiero ver los comentarios reportados y poder eliminarlos si infringen las normas de la comunidad.

### HU-64 — Gestionar catálogo de ejercicios
Como administrador quiero poder ocultar o reactivar ejercicios del catálogo sin eliminarlos permanentemente, para curar el contenido disponible.

### HU-65 — Ver logs de auditoría
Como administrador quiero consultar un registro de todas las acciones administrativas realizadas en el sistema (wipes, moderación, cambios de ejercicios) con trazabilidad de quién y cuándo.

### HU-66 — Ver estadísticas de un usuario
Como administrador quiero ver gráficos de rendimiento (RPE, volumen) y timeline de actividad de cualquier usuario para diagnosticar problemas o verificar uso.

### HU-67 — Resetear XP y nivel de usuario
Como administrador quiero poder resetear el XP o cambiar el nivel de un usuario específico desde el panel, para corregir datos inconsistentes sin necesidad de un wipe completo.

### HU-68 — Buscar usuarios con paginación
Como administrador quiero buscar usuarios por email o nombre con paginación para gestionar eficientemente una base de usuarios grande.

### CA-36 — KPIs visibles en dashboard admin
El grid de KPIs debe mostrar 6 métricas con valores reales desde `v_admin_metricas`. Los valores deben actualizarse al recargar la pestaña. Sin datos, mostrar estado vacío.

### CA-37 — Moderación funcional con RLS
Al ocultar una publicación, `esta_eliminado = true` debe persistirse en BD y la publicación debe desaparecer del feed público en la siguiente recarga. La acción debe registrarse en `admin_auditoria`.

### CA-38 — Toggle de ejercicios funcional
Al desactivar un ejercicio (`activo = false`), debe desaparecer de las búsquedas del explorador y de las recomendaciones IA. Al reactivarlo, debe reaparecer. El cambio debe registrarse en auditoría.

### CA-39 — Logs de auditoría con trazabilidad
Cada entrada en `admin_auditoria` debe incluir `admin_id`, `target_usuario_id` (si aplica), `accion` válida, `detalles` JSONB y `creado_en`. Los logs deben ser visibles solo para admins.

### CA-40 — AdminUsuarioDetalle con 3 sub-pestañas
La pantalla de detalle de usuario debe mostrar 3 pestañas: Perfil (datos + acciones), Estadísticas (gráficos RPE/volumen con fl_chart), Timeline (actividad cronológica). Los gráficos deben usar datos reales del usuario.

### CA-41 — Búsqueda de usuarios paginada
La búsqueda de usuarios debe soportar paginación (10 por página) y filtro por email o nombre. El conteo total de resultados debe mostrarse. La navegación entre páginas debe ser fluida.

### CU-36 — Planificar semana con Time-Blocking (NUEVO v7.0)

**Actor:** Usuario autenticado
**Precondición:** Usuario con horarios fijos configurados (clases, compromisos) y perfil académico activo.
**Flujo principal:**
1. El usuario accede a `/academico/planificar` → pantalla "Inbox".
2. El usuario configura intenciones: horas de estudio (slider 5-40h), días de deporte (slider 1-6), preferencia horaria (mañana/tarde/noche).
3. El sistema muestra las entregas próximas detectadas automáticamente desde `entregas_examenes`.
4. Los horarios fijos se muestran en una lista de solo lectura.
5. El usuario pulsa "✨ Generar mi semana".
6. El sistema llama a `TimeBlockIaService` (Gemini Flash) con reglas N1-N10 y las intenciones del usuario.
7. El sistema muestra pantalla de carga con animación y mensajes de progreso.
8. La IA genera un JSON con la distribución semanal de bloques.
9. El sistema valida el JSON (no solapamientos, horas totales, reglas N3/N4).
10. El usuario es redirigido al Canvas (`/academico/planificar/canvas`) con el plan visualizado.
**Flujo alternativo:**
- A1 — Sin API key de Gemini: se ejecuta el algoritmo de fallback determinista (distribución equitativa). Se muestra banner "Plan generado con distribución equilibrada".
- A2 — Gemini falla o timeout: se ejecuta fallback. Se muestra toast "No se pudo conectar con la IA. Se ha usado un plan por defecto."
**Flujo de excepción:**
- E1 — Sin horarios fijos configurados: el sistema muestra un banner "No tienes horarios fijos configurados. La IA usará toda la semana como disponible."
- E2 — JSON inválido de Gemini (sin bloques válidos): se usa fallback determinista.
**Postcondiciones:** Plan semanal visualizado en el Canvas. Los bloques se guardan como `horarios_academicos` con `es_fijo = false`.

### CU-37 — Ajustar plan semanal en Canvas (NUEVO v7.0)

**Actor:** Usuario autenticado
**Precondición:** Plan semanal generado y visualizado en `/academico/planificar/canvas`.
**Flujo principal:**
1. El usuario ve el Canvas con la cuadrícula semanal de 7 días × 16 horas (7:00-23:00).
2. Los bloques se distinguen por color: azul=fijos, púrpura=estudio, naranja=deporte, rojo=entrega, verde=descanso.
3. El usuario arrastra un bloque a otro día/hora (drag & drop con snap a intervalos de 15 min).
4. El usuario redimensiona un bloque arrastrando su borde inferior.
5. El usuario añade un bloque manual pulsando un hueco vacío.
6. El usuario elimina un bloque deslizando a la izquierda o pulsando el icono de papelera.
7. La barra de progreso inferior se actualiza en tiempo real mostrando horas planeadas por tipo.
8. El usuario pulsa "Guardar semana" → UPSERT en `horarios_academicos`.
**Flujo alternativo:**
- A1 — El usuario sale sin guardar: se muestra diálogo "¿Guardar cambios antes de salir?"
**Postcondiciones:** Plan semanal persistido. Timeline del Dashboard refleja los bloques del día.

### CU-38 — Visualizar y cumplir plan semanal (NUEVO v7.0)

**Actor:** Usuario autenticado
**Precondición:** Plan semanal guardado. Dashboard cargado.
**Flujo principal:**
1. El usuario ve sus bloques del día en la Línea de Tiempo del Dashboard (pestaña "Hoy").
2. Cada bloque muestra tipo, asignatura, duración y estado (pendiente/completado).
3. El usuario marca bloques como completados ✅ durante el día.
4. La barra `ProgressGamificationBar` en el dashboard muestra el progreso semanal.
5. Al cumplir ≥80% del plan, la semana se marca como completada y se otorga XP de estudio (150 XP).
6. Tras 4 semanas consecutivas con ≥80% de adherencia, se desbloquea la insignia "Planificador Maestro".
**Flujo alternativo:**
- A1 — Sin plan guardado: la pestaña "Hoy" muestra solo clases y sesiones, sin bloques de estudio.
**Postcondiciones:** Progreso semanal visible. XP académico otorgado al completar la semana. Insignia desbloqueada al alcanzar el hito.

### HU-69 — Configurar horarios fijos
Como estudiante quiero configurar mis clases y compromisos fijos una sola vez para que la IA los respete al planificar mi semana.

### HU-70 — Generar semana con IA
Como estudiante quiero que la IA me distribuya las horas de estudio automáticamente en mi semana, respetando mis clases y mis preferencias, para no tener que hacerlo manualmente.

### HU-71 — Ajustar plan con drag & drop
Como estudiante quiero poder arrastrar bloques en el calendario semanal para ajustar el plan generado por la IA a mis necesidades cambiantes.

### HU-72 — Ver mi progreso semanal
Como estudiante quiero ver mi progreso de cumplimiento del plan semanal en el Dashboard para mantenerme motivado y consistente.

### CA-42 — Time-Blocking funcional con IA
El botón "Generar mi semana" debe producir un plan semanal con bloques distribuidos en ≤8s (con Gemini) o ≤1s (fallback). Los bloques no deben solaparse con horarios fijos. La validación post-IA debe aprobar ≥90% de los bloques generados.

### CA-43 — Canvas interactivo con drag & drop
El Canvas debe permitir arrastrar bloques entre días/horas con respuesta táctil <100ms. Los bloques deben hacer snap a intervalos de 15 min. El redimensionamiento debe ser fluido (60fps). El estado del grid debe persistir al navegar entre pantallas.

### CA-44 — Progreso visible en Dashboard
La barra de progreso semanal debe mostrar el porcentaje de bloques completados. Al completar ≥80% del plan, debe otorgarse XP de estudio y mostrarse feedback positivo. La insignia "Planificador Maestro" debe desbloquearse tras 4 semanas consecutivas de cumplimiento.

## 14. Matriz de Trazabilidad (AMPLIADO)
*(Conservado de v2.9)*

8. **Objetivo O9 (IA generativa):** RF-BIE-13/14/15/16 + RI-11/12 → CU-20.
9. **Objetivo O10 (adaptación por fatiga):** RF-BIE-17/18/19 + RB-22 → CU-21.
10. **Objetivo O11 (periodización):** RF-BIE-20/21 + RB-23/24 → CU-20.

## 15. Riesgos y Mitigaciones
*(Conservado de v2.9)*

7. **Riesgo: Latencia de IA degrade experiencia de usuario.**
   - Mitigación: Gemini Flash seleccionado por baja latencia (~2-3s). Timeout de 15s. Indicador de carga con animación durante la espera.
8. **Riesgo: Respuestas de IA no parseables (JSON malformado).**
   - Mitigación: `_extraerJson()` con múltiples estrategias de extracción (regex para bloques de código, búsqueda de llaves/corchetes). Fallback a error genérico sin crashear.
9. **Riesgo: Coste de API de Gemini en producción.**
   - Mitigación: Gemini Flash tiene capa gratuita generosa. Los prompts se mantienen minimalistas (solo IDs de ejercicio, no texto completo de instrucciones).
10. **Riesgo: Fatiga mal calibrada si el usuario no hace check-in.**
    - Mitigación: El check-in es opcional. Sin check-in, la IA usa solo datos de historial. La detección de descarga usa tanto check-in como datos de sesiones (RPE).

## 16. Plan por Fases (AMPLIADO)

1. **Fase 1 (MVP, 3-5 meses):** auth y perfil extendido, asignaturas, planes, bloques, apuntes/notas rápidas, evaluaciones y calificaciones base, perfil físico de bienestar, recomendación semanal básica de entrenos, seeding de catálogo `ejercicios` en Supabase, carga de multimedia de ejercicios en bucket R2, rutinas y registro de sesiones, retos simples, feed y likes, notificaciones básicas.

2. **Fase 1.5 (Sprint 5 — IA + Periodización, COMPLETADO):** Integración del servicio IA (Gemini Flash) para recomendación de rutinas y ejercicios, sistema de periodización automática, check-in diario de fatiga integrado en sesión en vivo, sobrecarga progresiva asistida por IA, detección automática de necesidad de descarga, perfil de bienestar editable desde PerfilScreen, barra de progreso de rutina con tiempo acumulado.

3. **Fase 2 (crecimiento):** retos complejos con dependencias, comentarios en feed, insignias avanzadas, integraciones ampliadas, notificaciones push nativas.

4. **Fase 3 (administración — COMPLETADO):** Panel de administración con wipe de datos de usuario (función `wipe_user_data`), dashboard de métricas globales (`v_admin_metricas`), moderación de contenido (columnas `reportado`/`reportado_por` en `actividades_sociales` y `comentarios_feed`), catálogo de ejercicios admin (columna `activo`), logs de auditoría (`admin_auditoria`), búsqueda de usuarios con paginación, estadísticas y timeline por usuario.

5. **Fase 4 (planificación inteligente — PLANIFICADO):** Sistema de Time-Blocking académico con IA (Gemini Flash). Custom Grid nativo (Stack + Positioned + Draggable + DragTarget, 0 dependencias nuevas). Inbox de intenciones (sliders horas/días + entregas). Canvas semanal interactivo con drag & drop. Reglas N1-N10 de planificación académica. Integración con Dashboard (Timeline + barra de progreso). Insignia "Planificador Maestro". Columnas `es_fijo` y `dia_semana` en `horarios_academicos`.

## 17. Restricciones, Supuestos y Dependencias
*(Conservado de v2.9)*

Añadido en v3.0:
3. **Dependencia:** Disponibilidad de la API de Gemini Flash. Si el servicio no está disponible, la funcionalidad de creación manual de rutinas sigue funcionando normalmente.

---

**Documento compilado:** 17-06-2026
**Versión:** 5.2
**Estado:** VIGENTE — Sprint Time-Blocking planificado. Añadidos CU-36/37/38 (planificación semanal IA + Canvas + progreso), HU-69-72, CA-42-44 y Fase 4 en §16.
**Clasificación:** PÚBLICO — Equipo jloen
