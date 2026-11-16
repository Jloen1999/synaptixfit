# ADR 0054 — Plantillas reales, peso de partida y calibración de la primera sesión

- **Fecha:** 2026-11-16
- **Estado:** aceptado (propuesta y maqueta aprobadas por el propietario, fase 3A)

## Contexto

La auditoría de las plantillas (15-11-2026) encontró que las 24 plantillas de rutina y las 10 de reto no servían bien a
estudiantes reales: «De 0 a 5 km» pedía 20 y 30 min seguidos en la semana 1; días sin nombre («Día 1»); repeticiones
fijas sin decir cuánto esfuerzo; volúmenes desequilibrados; minutos que no cuadraban; ningún peso de partida (la
sugerencia de carga solo aparecía tras una sesión con peso y RPE); la progresión usaba el rango del objetivo (6-15) en
vez del de cada ejercicio, subía un 5 % redondeado a 0,5 kg (mancuernas de 6,5 kg que no existen) y repartía las series
en 50 % / 75 % / 100 % (de 3 series de trabajo quedaba una); y cientos de ejercicios del catálogo tenían músculos de
otro ejercicio (prensa de piernas → pectoral, gemelos → deltoides), lo que desviaba la generación automática.

## Decisión

### Catálogo de plantillas

- **Retirar sin borrar:** columna `activa` en `plantillas_rutina` y `plantillas_reto` (V1072). El catálogo solo ofrece y
  deja usar las activas; las retiradas se siguen leyendo (un reto con amigos en curso enseña su plantilla). Las rutinas
  y los retos creados con ellas son copias propias y no cambian: un reto guarda su propia regla (V1062).
- **12 rutinas reales** (V1073, generadas desde `tools/exercises/data/plantillas_rutina_3.json`): máquinas para empezar,
  pesas libres, poco tiempo, parte de arriba y piernas, empujar-tirar-piernas, en casa sin material, en casa con
  mancuernas, calistenia en el parque, mantenerte en exámenes (gimnasio y casa, 2 días), empieza a correr y espalda y
  movilidad. Nombres sin cifras; cada día con el **nombre de su sesión** (`plantillas_rutina_dias_textos`, pasa a
  `dias_rutina.nombre`); cada ejercicio con **rango** (`rep_min`-`rep_max`) y **repeticiones que deben sobrar**
  (`rir_objetivo`), que viajan a la rutina (`seleccion_de_ejercicios`) y al cliente (`repMin`, `repMax`,
  `repsInReserve`). Se empieza por el mínimo del rango.
- **«Empieza a correr»**: 9 semanas del esquema clásico de Couch to 5K del NHS; `plantillas_rutina_carreras.semana`
  (0 = todas) y 13 entrenos de carrera `C25K_W1`…`C25K_W9` (las semanas 5 y 6 cambian de una salida a otra). No se
  ofrecen sueltos en «Crear entreno» (`RunWorkoutTemplates.COUCH_TO_5K`, `find`): los crea la plantilla, uno por salida.
- **10 retos** (V1074): nuevo «Tu primer mes entrenando» (2 entrenos/semana, 4 semanas); «Entrena también en
  exámenes» pasa a 2/semana, «Estudia y muévete» a 3 de 7 días y «Tus primeros 5 km» a «Empieza a correr» (3 salidas/
  semana, 8 de 9 semanas). Los que cambian entran con código nuevo y el viejo se retira; «Primer estudio antes de las
  10» se retira.

### Peso de partida (`StartingLoad`, `GetStartingLoadsUseCase`)

Historial de 6 semanas → fracción del peso corporal (tabla `cargas_iniciales_ejercicio`) → peso por defecto; sin kilos
en máquinas, poleas, peso corporal y gomas, ni para nivel intermedio sin historial; redondeo hacia abajo al material y
tope del primer día. Lo usan las plantillas y la generación de rutinas, que ya no estima por el nombre del ejercicio
(`bodyWeightShare` desaparece). Detalle y tabla en `formulas.md`.

**Peso del perfil y consentimiento de salud.** El peso corporal es un dato de salud (art. 9 RGPD). Decisión tomada por
el propietario: **solo se usa para el peso de partida si la persona tiene el consentimiento de salud vigente**
(`consentimientos_salud`, V1044: dado y no retirado) **y aceptado con el texto que lo incluye**: el texto del permiso
(`trainingHealthConsentBody`) dice ahora que el peso también es dato de salud y que se usa para proponer con cuántos
kilos empezar. Como el RGPD pide un consentimiento específico para cada finalidad, se guarda qué versión del texto se
aceptó (`version_texto`, V1076; `HealthConsent.textVersion`, versión actual 2) y solo la versión 2 o posterior cubre
el peso (`HealthConsent.coversBodyWeight`). Quien aceptó el texto anterior sigue con su consentimiento para el registro
diario, pero recibe el peso por defecto, que es igual de seguro (solo menos afinado); volver a aceptar guarda la
versión nueva (`giveHealthConsent` lo guarda si la vigente es de un texto anterior). Las kcal ya usaban el peso del
perfil antes de este ADR y no cambian aquí.

**Volver a pedirlo (decisión del propietario, 16 nov 2026).** `GET /me/health-consent` devuelve `outdated` (dado con un
texto anterior). La pantalla que pide aceptar la política nueva (`LegalAcceptancePage`, versión legal `2026-11-16`)
enseña a esas personas, aparte y con una casilla **sin marcar**, el texto nuevo: así lo ven una sola vez y junto a la
política. No es obligatorio ni condiciona aceptar la política, porque el consentimiento de salud tiene que ser libre y
separado (art. 7.2 y 9.2.a RGPD); si no la marcan, todo sigue como antes. En Ajustes › Privacidad y datos, la fila del
permiso dice «sin tu peso» y ofrece «Usar también mi peso» además de «Retirar».

### Calibración de la primera sesión (`ExerciseCalibration`)

Tras la primera serie de trabajo de un ejercicio con kilos que no se ha hecho con peso en 6 semanas, la sesión en vivo
pregunta «¿Cuántas más podrías haber hecho?» (0 · 1-2 · 3 · 4 o más), en el panel del descanso. El **servidor** decide:
4 o más sube un escalón, 0 o no llegar al mínimo baja uno, lo demás se queda (`GET|POST
/training/sessions/{id}/calibrations`). El peso resultante es la cifra de partida de la serie siguiente y pasa a la
rutina en los días de ese ejercicio que aún no se han hecho. La respuesta se guarda en `calibraciones_ejercicio`
(exportación de datos `exerciseCalibrations`; se borra con la cuenta). Responder es opcional y, sin conexión, el peso no
cambia. El servidor solo acepta la primera serie de trabajo de un ejercicio que se calibra (o cambiar la respuesta ya
dada en esa sesión) en una sesión no abandonada (`ExerciseCalibration.accepts`): si no, o si la serie aún no se ha
guardado, `SESSION_SET_NOT_FOUND` (sin código nuevo) y la rutina no cambia. Al editar un ejercicio sin enviar el rango
(el editor no lo cambia, ni las apps anteriores), el hueco conserva el suyo (`PlannedExercise.changeParameters`).

### Doble progresión e incrementos por material

Con rango, `ProgressionCalculator` aplica la doble progresión (tope del rango con el esfuerzo pedido → un escalón del
material y vuelta al mínimo; si no, +1 repetición; dos sesiones seguidas sin llegar al mínimo → −10 %). Sin rango, las
reglas de siempre, pero subir peso es un **escalón del material** (`LoadStep`, perfil de carga en `ExerciseRef.load`)
en vez de +5 %. Se quita la rampa 50/75/100 %: el calentamiento ya va aparte (ADR 0031) y todas las series de trabajo
llevan el mismo peso.

### Músculos del catálogo

V1075 (generada con `tools/exercises/build_muscle_fix_migration.py`) corrige los 138 ejercicios de V2 que tenían un
juego de músculos por defecto que no les correspondía, con reglas por nombre; los que acertaban se quedan igual.

## Consecuencias

- El cliente solo pinta: rango («3 series · 8–12 reps»), «Te deben sobrar 2 repeticiones en cada serie», el nombre de
  la sesión y la pregunta de calibración con su resultado. Ninguna regla de pesos vive en el cliente.
- Las rutinas ya creadas con plantillas viejas no tienen rango: siguen con las reglas sin rango (ahora con escalones de
  material y sin rampa).
- Pendiente (fases 3B/3C y siguientes): rediseño de Gimnasio/Correr, fotos e iconos; «por pierna / por lado» en
  zancadas y planchas laterales; variante más fácil por ejercicio (flexión en pared); métrica de minutos activos (OMS
  150 min) para un reto; editar el rango a mano en el editor de rutinas.
