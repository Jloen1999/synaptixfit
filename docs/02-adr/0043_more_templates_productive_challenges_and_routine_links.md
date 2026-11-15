# ADR 0043 — Más plantillas de rutina, retos productivos que se cuentan solos y compartir una rutina por enlace

- **Fecha:** 2026-11-15
- **Estado:** aceptado

## Contexto

Fase B del plan premium. Había 10 plantillas de rutina (ADR 0032) filtrables solo por días, casa y exámenes; faltaban
el parque, el nivel y los minutos. Los retos se creaban a mano y, salvo los de sesiones (ADR 0009), había que
marcarlos a mano aunque el servidor ya supiera si se habían cumplido. Compartir una rutina solo se podía en la
comunidad (rutina pública), no con un amigo concreto.

## Decisión

### 1. Plantillas de rutina: 14 nuevas, lugar, nivel y días de carrera

- **Lugar** (`GYM`, `HOME`, `OUTDOOR`) y **nivel** (`BEGINNER`, `INTERMEDIATE`) en `plantillas_rutina` (V1060). `en_casa`
  se conserva para las apps anteriores (= lugar `HOME`). Las de antes: `torso_pierna_4`, `cinco_dias` y `fuerza_3` son
  de nivel intermedio.
- **Filtros en la app** (sobre lo que ya llega, sin otra petición): dónde (gimnasio, casa, fuera), días por semana,
  tiempo (hasta 20, 30 o 45 min, o más), nivel y semanas de exámenes.
- **14 plantillas nuevas** (V1061, generada desde `tools/exercises/data/plantillas_rutina_2.json`), solo con ejercicios
  del catálogo. De las 14 propuestas, 6 solapaban con las existentes y se sustituyeron:

  | Propuesta | Decisión |
  |---|---|
  | Cuerpo entero para empezar 2d | Ya existe (`cuerpo_completo_2`) → **Máquinas para empezar · 3 días** |
  | Cuerpo entero en casa 3d | Ya existe (`casa_3`) → **Calistenia en el parque · 3 días** (fuera) |
  | Exprés 20 min casa 3d | Ya existe (`examenes_casa`, 20 min, 3 días) → **En casa · torso y pierna · 4 días** (intermedio) |
  | Torso/Pierna 4d | Ya existe (`torso_pierna_4`) → **Empuje, tirón y pierna · 6 días** (la propuesta «3 o 6 días» entra en sus dos versiones) |
  | Fuerza simple 5×5 | Ya existe (`fuerza_3`, 5×5) → **Una pesa rusa · 3 días** |
  | Semana de exámenes 2×30 min | Ya existe (`examenes_gimnasio`) → **Volver tras los exámenes · 3 días** (pocas series, 3 semanas) |

  Entran tal cual: Exprés 30 min gimnasio, Solo mancuernas, Con gomas elásticas, De 0 a 5 km, Correr y fuerza 2 + 2,
  Espalda sana 10 min 5 días y Glúteo y pierna. Series, repeticiones y descansos: `formulas.md` (ACSM, Ratamess 2009).
- **Correr encaja como «gimnasio + carrera»:** una rutina solo tiene ejercicios con series; correr se graba con el GPS
  en Entreno › Correr y cuenta como actividad (ADR 0037). Por eso una plantilla puede tener **días de carrera**
  (`plantillas_rutina_carreras`: día y código de `RunWorkoutTemplates`). Al usarla, el servidor crea la rutina con los
  días de fuerza y, en la misma transacción, los entrenos de carrera que la persona aún no tenga (uno por código, con
  el nombre de `nombres_entreno_carrera`, el mismo texto que la app). «De 0 a 5 km» = 1 día corto de fuerza + 3
  salidas (alternar andar y correr → 20 min → 30 min seguidos); «Correr y fuerza» = 2 días de gimnasio + rodaje suave
  y cambios de ritmo. Los días por semana cuentan los dos tipos. La app avisa de que las carreras están en Correr.

### 2. Retos productivos: plantillas y regla automática

- **Regla en el dominio** (`ChallengeRule`): «`perUnit` de `metric` cada `unit` (día, semana o total), `target` veces».
  Métricas solo con datos que ya existen: repasos, Pomodoros (minutos o «antes de las 10»), entrenos, Pomodoro + entreno
  el mismo día, tests y simulacros, registro diario, semanas planificadas y carreras con GPS. El recuento se rehace
  desde cero (`ChallengeReferencePort.activity` solo trae datos; qué cuenta lo decide la regla) con cada evento que lo
  puede cambiar (ver `events.md`; nuevo `WeekPlanChanged` del planificador) y al crear o editar el reto.
- **El reto creado es normal** (`Challenge.fromTemplate`): privado, se edita, se completa o se descarta. Si llega a la
  meta se completa con la XP de su dificultad; si se deshace algo y baja, se descompleta. Completarlo a mano antes de
  tiempo no da XP (como los retos por sesiones). Con tareas, mandan las tareas. No admite objetivo de sesiones.
- **Bienestar nunca se comparte:** un reto contado con el registro diario es siempre privado y, al completarse, no sale
  en el muro (`ChallengeCompleted.shareable = false`). Solo se lee la fecha del registro, nunca las respuestas.
- **Un reto por plantilla a la vez** (`CHALLENGE_TEMPLATE_ALREADY_ACTIVE`): dos iguales se contarían con lo mismo y
  darían la XP dos veces. Clonar un reto de plantilla (propio o de la comunidad) pasa por la misma comprobación y por
  el modo de uso. Su inicio no se adelanta a antes de crearlo (se ajusta en silencio): contaría lo de antes. Dos
  peticiones exactamente a la vez podrían crear dos; se acepta ese riesgo (un toque, botón ocupado mientras tanto). Varios retos de plantillas distintas sí (no se limita a uno, como Fabulous: Progreso › Retos
  ya los ordena y el modo de uso filtra los que no se pueden cumplir).
- **10 plantillas** (V1062). De las 14 propuestas:

  | Propuesta | Decisión |
  |---|---|
  | Repasa 20 min/día 14 días (12/14) | **Adaptada** a «Repasa cada día» (un repaso al día, 12 de 14): el repaso no guarda minutos |
  | Tarjetas a cero 7 días | **Descartada:** no hay historial de cuántos repasos quedaban pendientes cada día |
  | Estudio sin móvil 7 días | **Adaptada** a «Un Pomodoro al día» (25 min, 5 de 7): la app no sabe si se salió de ella |
  | 3 entrenos/semana en exámenes 3 sem | **Entra** («Entrena también en exámenes») |
  | Entrega con un día de margen 4 sem | **Descartada:** una entrega no guarda cuándo se marcó como hecha |
  | Duerme 7 h 14 días | **Descartada:** el registro guarda la calidad del sueño (1-5), no horas; además es salud |
  | Primer estudio antes de las 10 (8/10 laborables) | **Entra** (Pomodoro empezado antes de las 10) |
  | Muévete entre estudios 7 días | **Adaptada** a «Estudia y muévete» (Pomodoro y entreno el mismo día, 5 de 7) |
  | Simulacro semanal 4 sem | **Entra** (test o simulacro terminado cada semana) |
  | Apuntes al día 14 días | **Descartada:** «al día» no se puede comprobar con lo que se guarda |
  | Registro diario 21 días (18/21) | **Entra** («¿Qué tal estás? 3 semanas», privado siempre) |
  | Domingo de plan 4 sem | **Adaptada** a «Planifica tu semana» (4 semanas planificadas con la regla de siempre: 3 eventos) |
  | Primeros 5 km 6 sem | **Entra** (18 carreras con GPS en 6 semanas) |
  | 10 horas juntos 2 sem (grupo) | **Adaptada** a «10 horas de concentración» en solitario; la versión en grupo, con la fase C |

- **Galería:** Progreso › Retos tiene la fila «Plantillas de retos» (`/challenges/templates`) con «Empezar este reto»
  en un toque; la que ya está en marcha dice «En marcha». Un reto que se cuenta solo enseña «5 de 12 días», lo que
  falta («Te faltan 7 días») y un «?» con qué cuenta; no tiene botón de completar ni de desmarcar.

### 3. Compartir una rutina por enlace

- El dueño crea un enlace (`POST /routines/{id}/share-links`): **token aleatorio de 256 bits** en base64url, sin datos
  de nadie. Solo se guarda su **huella SHA-256** (`enlaces_rutina`, V1063), como el calendario suscrito (ADR 0020): el
  token en claro solo se ve al crearlo. **Caduca a los 30 días**; «Dejar de compartir» (`DELETE`) revoca todos los
  vigentes; como mucho 5 vigentes por rutina (`ROUTINE_SHARE_LINK_LIMIT`). Se comparten con la hoja nativa
  (`share_plus`), con la dirección de la app web `…/#/training/shared/<token>`: el token va tras `#`, así que no llega
  a ningún servidor ni registro al abrirlo.
- Quien lo abre **con sesión iniciada** ve el resumen (`POST /shared-routines/preview`) y «Añadir a mis rutinas» (el
  verbo de siempre para copiar una rutina ajena; `POST /shared-routines/copy`). El token va **en el cuerpo**, no en la ruta, para que no quede en los registros de
  acceso; nginx limita a 30 peticiones por minuto e IP. Sin sesión, la app guarda el enlace, pide entrar y vuelve a él.
- **Nada del dueño:** ni nombre, ni id, ni foto, ni progreso. Se decidió no enseñar siquiera el nombre visible: quien
  recibe el enlace ya sabe quién se lo mandó y así el enlace reenviado no revela a nadie. La copia es privada, sin
  progreso y **sin procedencia** (`origin` nulo).
- Un enlace no se salta la moderación: no abre si el dueño está eliminado o silenciado o si uno de los dos bloqueó al
  otro. Revocado, caducado, desconocido o de una rutina borrada dan el mismo error (`ROUTINE_SHARE_LINK_NOT_FOUND`).
- **Android App Links quedan fuera:** exigen publicar `assetlinks.json` con la huella de firma y un enlace de ruta (no
  de `#`); el enlace se abre en el navegador con la app web.

## Consecuencias

- Las apps anteriores siguen funcionando: los campos nuevos de plantillas y retos son opcionales y `atHome` se mantiene.
- Un reto de plantilla cuenta lo que pasó desde que se empezó; lo que solo tiene fecha (registro diario) cuenta el día
  entero de inicio.
- Las plantillas de rutina con carreras crean entrenos en Correr; si la persona ya tiene uno de ese código, no se
  duplica.
- **Política de privacidad:** el enlace de rutina es un dato nuevo que se comparte con quien lo recibe (solo la rutina);
  hay que añadirlo a la política en la próxima versión (no se sube `LegalTerms.CURRENT_VERSION` en este cambio).
