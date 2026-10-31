# 0019. Progreso justo: topes de XP, rachas y repaso que reflejan actividad real

* **Estado:** Aprobado
* **Fecha:** 2026-10-25
* **Autores:** SynaptixFit

## Contexto
Una revisión funcional (2026-10-24) encontró formas de subir de nivel, mantener rachas o «dominar» un
material sin hacer la actividad: sesiones de entrenamiento de un segundo (~100 XP), tests de una
pregunta repetibles (30 XP), retos propios con 12 tareas marcadas a mano (840 XP), bloques de 24 h
(480 XP), entregas creadas y completadas en serie, Pomodoros registrados con cualquier fecha pasada
(rachas inventadas) y repasos adelantados que dejaban el material «dominado» en un minuto. Además, la
fatiga física podía convertir un repaso suspendido en aprobado y una sola sesión antigua bastaba como
línea base del ACWR, con avisos falsos de sobreentrenamiento a usuarios nuevos.

## Decisión
Las reglas viven en el dominio y el cliente solo muestra lo que decide el servidor:

* **Entrenamiento** (`TrainingRewards`): una sesión de menos de 10 min se guarda pero no da XP ni cuenta
  para retos, insignias ni racha; solo las 2 primeras sesiones de cada día dan XP.
* **Tests** (`PracticeRewards`): XP solo con 5 preguntas o más y como mucho 5 tests con XP cada 24 h (solo
  cuentan los que dieron XP). La práctica de un banco da XP una sola vez por banco y no entra en ese tope.
* **Retos** (`Challenge.MAX_XP`): un reto da como mucho 140 XP entre todas sus tareas; un reto de sesiones
  marcado a mano antes del objetivo no da XP hasta que las sesiones lo alcanzan.
* **Bloques** (`CalendarBlock`): puntúan como mucho 4 h y los bloques dan como mucho 200 XP al día (todo o
  nada por bloque, para restar exactamente lo dado al desmarcar). Un bloque hecho no puede cambiar de tipo
  ni empezar o dejar de reflejar una sesión de rutina o un repaso (su XP depende de ello).
* **Quitar del repaso** (`StudyMaterial.abandon`): el material queda «abandonado» y conserva su historial
  (borrarlo hacía desaparecer días de racha ya vividos y dejaba bloques de repaso huérfanos que daban XP).
* **Entregas** (`Deadline`): como mucho 5 con XP cada 24 h.
* **Pomodoro** (`FocusSession`): solo se registra con fecha de hoy o de ayer, y para la racha cuenta una
  fase de foco de al menos 10 min.
* **Repaso SM-2** (`SpacedRepetition`, `StudyMaterial`): el fallo lo decide la calidad real; el ajuste por
  fatiga solo suaviza el factor de facilidad. Un acierto antes de la fecha no adelanta el calendario
  (estado, intervalo y fecha se conservan); un fallo sí reinicia.
* **ACWR** (`CrossRegulationState`): hace falta carga en 2 de las 3 semanas anteriores a la aguda.
* **Racha única** (`UserActivityPort.activeDays`): entrenamiento (sesiones y bloques de deporte),
  registro diario, Pomodoro y estudio (bloques de estudio o repaso, repasos SM-2 y tests).

## Consecuencias
* **Positivas:** el nivel, las rachas y el estado «dominado» vuelven a significar actividad real; la
  regulación cruzada no alarma a quien acaba de empezar.
* **Negativas:** algunas actividades legítimas muy cortas (una movilidad de 8 min, un test de 3
  preguntas) dejan de puntuar. Los bloques que dieron XP con la regla anterior restan el valor nuevo
  (con tope) al desmarcarlos, no el antiguo.
* **A vigilar:** si los topes resultan cortos (época de exámenes con muchas entregas), se ajustan en las
  constantes del dominio sin migración.
