package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.user.UsageFocus;
import java.util.Arrays;
import java.util.List;
import java.util.function.Predicate;

/**
 * Tipo de un evento del calendario ({@link CalendarBlock}). La persona lo ve con el nombre del tipo («Estudio»,
 * «Entreno», «Personal»…) y, en genérico, como «evento» (ver {@code docs/05-design/vocabulario.md}).
 *
 * <p>{@link #code()} es el código canónico del vocabulario del producto (el que guarda la base de
 * datos y viaja en los eventos de dominio, p. ej. {@code "clase"}).
 */
public enum ActivityType {
    STUDY("estudio"),
    SPORT("deporte"),
    CLASS("clase"),
    REST("descanso"),
    MEAL("comida"),
    SLEEP("sueno"),
    EXAM("examen"),
    DELIVERY("entrega"),
    REVIEW("repaso"),
    /**
     * El día a día que no es ni estudio ni deporte (médico, trabajo, recados…), con nombre libre en los temas
     * (ADR 0035). No da XP ni carga de estudio, se ve con cualquier modo de uso y se marca como hecho.
     */
    PERSONAL("personal");

    private final String code;

    ActivityType(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    public static ActivityType fromCode(String code) {
        return Arrays.stream(values()).filter(t -> t.code.equals(code)).findFirst().orElse(STUDY);
    }

    /**
     * Completar el bloque da experiencia. Descanso, comida y sueño no la dan (evita farmeo), y lo personal
     * tampoco: la XP premia el estudio y el deporte, no apuntar recados.
     */
    public boolean grantsExperience() {
        return this != REST && this != MEAL && this != SLEEP && this != PERSONAL;
    }

    /**
     * Cuenta en el plan de la semana («12 de 18 hechos», Inicio y Progreso): lo que se planifica para hacerse y se
     * marca. Descanso, comida y sueño no; lo personal sí, aunque no dé XP.
     */
    public boolean countsInWeekPlan() {
        return grantsExperience() || this == PERSONAL;
    }

    /**
     * Actividad con esfuerzo cognitivo: se calcula su gasto calórico y su carga cognitiva. Es la
     * definición única que usan también los indicadores (estado cognitivo, kcal de estudio).
     */
    public boolean isCognitive() {
        return this == STUDY || this == CLASS || this == REVIEW || this == EXAM || this == DELIVERY;
    }

    /**
     * Cuenta como tiempo de estudio personal: carga académica semanal (y su objetivo de horas),
     * rachas de estudio, insignia de bloques de estudio y contexto académico del entrenamiento.
     * Clases, exámenes y entregas quedan fuera a propósito: la clase es asistencia, y exámenes y
     * entregas ya se cuentan aparte como evaluaciones de la semana.
     */
    public boolean countsAsStudy() {
        return this == STUDY || this == REVIEW;
    }

    /**
     * Si el tipo pertenece a un ámbito que la persona usa: lo académico (estudio, clase, repaso,
     * exámenes y entregas) solo con estudios, el deporte solo con deporte; descanso, comida, sueño y lo
     * personal siempre.
     */
    public boolean visibleFor(UsageFocus focus) {
        if (isCognitive()) {
            return focus.includesAcademic();
        }
        return this != SPORT || focus.includesFitness();
    }

    /** {@link #visibleFor(UsageFocus)} a partir del código de BD; un código desconocido se muestra. */
    public static boolean visibleCodeFor(String code, UsageFocus focus) {
        return Arrays.stream(values()).filter(t -> t.code.equals(code)).findFirst()
                .map(t -> t.visibleFor(focus)).orElse(true);
    }

    /** {@link #isCognitive()} a partir del código de BD; un código desconocido no es cognitivo. */
    public static boolean isCognitiveCode(String code) {
        return Arrays.stream(values()).anyMatch(t -> t.code.equals(code) && t.isCognitive());
    }

    /** {@link #countsAsStudy()} a partir del código de BD; un código desconocido no cuenta. */
    public static boolean countsAsStudyCode(String code) {
        return Arrays.stream(values()).anyMatch(t -> t.code.equals(code) && t.countsAsStudy());
    }

    /**
     * Tiene seguimiento: si pasa sin completarse queda «Sin hacer» ({@link ItemTimeStatus#MISSED}).
     * Exámenes y entregas se siguen por su entrega; descanso, comida y sueño no se marcan.
     */
    public boolean isTrackable() {
        return this == STUDY || this == REVIEW || this == SPORT || this == CLASS || this == PERSONAL;
    }

    /** Necesita un nombre propio (en los temas): lo personal no tiene asignatura ni rutina que lo nombre. */
    public boolean requiresName() {
        return this == PERSONAL;
    }

    /**
     * Se puede repetir cada semana al crearlo. Exámenes y entregas no: cada uno crea su propia
     * entrega con fecha y no se repiten.
     */
    public boolean canRepeatWeekly() {
        return this != EXAM && this != DELIVERY;
    }

    /** Códigos de BD de los tipos que cumplen {@code filter} (para consultas SQL de otros módulos). */
    public static List<String> codesWhere(Predicate<ActivityType> filter) {
        return Arrays.stream(values()).filter(filter).map(ActivityType::code).toList();
    }
}
