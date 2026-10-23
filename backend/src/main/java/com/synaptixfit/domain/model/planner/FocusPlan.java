package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.neuro.CrossRegulation;

/**
 * Duraciones recomendadas para el Pomodoro de hoy. Parte del ciclo de atención de 52/17 min (la
 * atención baja a la mitad tras 52 min seguidos, ver {@code CognitiveLoad}) y lo recorta si la
 * regulación cruzada limita hoy los bloques de estudio ({@link CrossRegulation#maxStudyMinutes}).
 * Inicio y el Pomodoro muestran la misma recomendación.
 *
 * @param focusMinutes          minutos de cada bloque de concentración
 * @param shortBreakMinutes     pausa entre bloques
 * @param longBreakMinutes      pausa larga tras {@code cyclesBeforeLongBreak} bloques
 * @param cyclesBeforeLongBreak bloques antes de la pausa larga
 * @param limitedByFatigue      el bloque es más corto de lo habitual por la carga física
 */
public record FocusPlan(int focusMinutes, int shortBreakMinutes, int longBreakMinutes, int cyclesBeforeLongBreak,
                        boolean limitedByFatigue) {

    /** Ciclo de trabajo de DeskTime: 52 min de trabajo y 17 de descanso. */
    public static final int ATTENTION_CYCLE_MINUTES = 52;
    public static final int ATTENTION_REST_MINUTES = 17;

    /** Con bloques de 52 min, tres seguidos ya son casi tres horas: toca una pausa larga. */
    static final int CYCLES_BEFORE_LONG_BREAK = 3;
    static final int LONG_BREAK_MINUTES = 30;
    static final int MIN_BREAK_MINUTES = 5;

    /** Límites para ajustar el bloque a mano en el Pomodoro. */
    public static final int MIN_FOCUS_MINUTES = 15;
    public static final int MAX_FOCUS_MINUTES = 90;

    /**
     * @param maxStudyMinutes tope de minutos por bloque de hoy según la regulación cruzada (entre
     *                        25 y 90)
     */
    public static FocusPlan of(int maxStudyMinutes) {
        int cap = Math.max(CrossRegulation.MIN_STUDY_MINUTES, maxStudyMinutes);
        int focus = Math.min(ATTENTION_CYCLE_MINUTES, cap);
        // La pausa guarda la proporción 52/17 del ciclo de atención.
        int shortBreak = Math.max(MIN_BREAK_MINUTES,
                (int) Math.round(focus * (double) ATTENTION_REST_MINUTES / ATTENTION_CYCLE_MINUTES));
        return new FocusPlan(focus, shortBreak, LONG_BREAK_MINUTES, CYCLES_BEFORE_LONG_BREAK,
                cap < ATTENTION_CYCLE_MINUTES);
    }

    /** Recomendación de hoy a partir de la regulación cruzada; sin datos de carga física, la estándar. */
    public static FocusPlan of(CrossRegulationView regulation) {
        return regulation == null || regulation.zone() == AcwrZone.NO_DATA ? standard()
                : of(regulation.state().maxStudyMinutes());
    }

    /** Sin datos de carga física (o solo estudios): el ciclo de atención completo. */
    public static FocusPlan standard() {
        return of(CrossRegulation.DEFAULT_STUDY_MINUTES);
    }
}
