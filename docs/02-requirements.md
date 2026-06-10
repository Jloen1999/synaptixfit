# 02 - Requisitos del Producto (SRS)

Version: 3.2
Estado: IN_PROGRESS — Sprint 6 (Motor de Recomendaciones Fases 0-10) completado
Fecha: 07-06-2026
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
2. Comentarios y moderación en feed.
3. Insignias y rachas avanzadas.
4. Recomendaciones inteligentes de equilibrio estudio/actividad.
5. Integraciones externas avanzadas (calendarios y wearables).

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
1. **Modelo seleccionado:** Gemini Flash (`gemini-flash-latest`) por equilibrio velocidad/calidad y latencia aceptable (< 3s por prompt) para uso interactivo en entrenamiento.
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
Workout debe navegar a sesión en vivo, Nuevo Reto a creación de reto simple. Pomodoro y Escanear muestran placeholder.

### CA-20 — PlanWeekBar condicional
Solo se muestra si hay rutina activa. Si no, se oculta sin afectar el layout.

### CA-21 — CognitiveLoadBar condicional
Solo se muestra si hay datos académicos. Si no, se oculta sin afectar el layout.

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

## 17. Restricciones, Supuestos y Dependencias
*(Conservado de v2.9)*

Añadido en v3.0:
3. **Dependencia:** Disponibilidad de la API de Gemini Flash. Si el servicio no está disponible, la funcionalidad de creación manual de rutinas sigue funcionando normalmente.

---

**Documento compilado:** 11-05-2026
**Versión:** 3.0
**Clasificación:** PÚBLICO — Equipo jloen
