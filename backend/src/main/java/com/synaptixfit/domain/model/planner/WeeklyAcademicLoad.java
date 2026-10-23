package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Carga académica de una semana (única por usuario y lunes).
 *
 * <p>Las horas y los recuentos se calculan a partir de los bloques y entregas; el estrés y el sueño
 * los introduce el usuario. Regla de experiencia (heredada): {@link #STUDY_EXPERIENCE} puntos una
 * sola vez por semana cuando las horas reales de estudio alcanzan el 80 % del objetivo semanal del
 * perfil académico; se retiran si la semana vuelve a quedar por debajo.
 */
public final class WeeklyAcademicLoad {

    public static final int STUDY_EXPERIENCE = 150;
    public static final double STUDY_GOAL_RATIO = 0.8;
    private static final int MAX_HOURS = 120;
    private static final int MAX_COUNT = 20;

    private final UUID id;
    private final UUID userId;
    private final LocalDate weekStart;
    private int plannedHours;
    private int actualHours;
    private int exams;
    private int deliveries;
    private int stressLevel;
    private double sleepHours;
    private String notes;
    private boolean xpAwarded;

    public WeeklyAcademicLoad(UUID id, UUID userId, LocalDate weekStart, int plannedHours, int actualHours,
                              int exams, int deliveries, int stressLevel, double sleepHours, String notes,
                              boolean xpAwarded) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.weekStart = PlannerZone.mondayOf(Guard.notNull(weekStart, "weekStart"));
        this.plannedHours = clamp(plannedHours, MAX_HOURS);
        this.actualHours = clamp(actualHours, MAX_HOURS);
        this.exams = clamp(exams, MAX_COUNT);
        this.deliveries = clamp(deliveries, MAX_COUNT);
        this.stressLevel = Guard.range(stressLevel, "stressLevel", 1, 10);
        this.sleepHours = Guard.range(sleepHours, "sleepHours", 0, 14);
        this.notes = notes;
        this.xpAwarded = xpAwarded;
    }

    public static WeeklyAcademicLoad empty(UUID id, UUID userId, LocalDate weekStart) {
        return new WeeklyAcademicLoad(id, userId, weekStart, 0, 0, 0, 0, 5, 7, null, false);
    }

    /** Actualiza los datos derivados de bloques y entregas (minutos → horas redondeadas). */
    public void refresh(long plannedMinutes, long actualMinutes, int examCount, int deliveryCount) {
        this.plannedHours = clamp((int) Math.round(plannedMinutes / 60.0), MAX_HOURS);
        this.actualHours = clamp((int) Math.round(actualMinutes / 60.0), MAX_HOURS);
        this.exams = clamp(examCount, MAX_COUNT);
        this.deliveries = clamp(deliveryCount, MAX_COUNT);
    }

    /** Estrés (1-10), sueño medio (0-14 h) y notas; los nulos se conservan. */
    public void updateWellbeing(Integer newStress, Double newSleepHours, String newNotes) {
        if (newStress != null) {
            this.stressLevel = Guard.range(newStress, "stressLevel", 1, 10);
        }
        if (newSleepHours != null) {
            this.sleepHours = Guard.range(newSleepHours, "sleepHours", 0, 14);
        }
        if (newNotes != null) {
            if (newNotes.length() > 2000) {
                throw new FieldValidationException("notes", "INVALID_LENGTH", "notes must have at most 2000 characters");
            }
            this.notes = newNotes.isBlank() ? null : newNotes.strip();
        }
    }

    /** ¿Corresponde ya la experiencia de estudio semanal? Solo una vez por semana. */
    public boolean qualifiesForStudyExperience(int weeklyGoalHours) {
        return !xpAwarded && weeklyGoalHours > 0
                && actualHours >= (int) Math.round(weeklyGoalHours * STUDY_GOAL_RATIO);
    }

    public void markExperienceAwarded() {
        this.xpAwarded = true;
    }

    /**
     * ¿Hay que retirar la experiencia semanal ya concedida? Cuando las horas reales vuelven a quedar
     * por debajo del 80 % del objetivo (bloques desmarcados o borrados). Idempotente: solo mientras
     * esté concedida.
     */
    public boolean losesStudyExperience(int weeklyGoalHours) {
        return xpAwarded && weeklyGoalHours > 0
                && actualHours < (int) Math.round(weeklyGoalHours * STUDY_GOAL_RATIO);
    }

    public void markExperienceRevoked() {
        this.xpAwarded = false;
    }

    private static int clamp(int value, int max) {
        return Math.max(0, Math.min(max, value));
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public LocalDate weekStart() { return weekStart; }
    public int plannedHours() { return plannedHours; }
    public int actualHours() { return actualHours; }
    public int exams() { return exams; }
    public int deliveries() { return deliveries; }
    public int stressLevel() { return stressLevel; }
    public double sleepHours() { return sleepHours; }
    public String notes() { return notes; }
    public boolean xpAwarded() { return xpAwarded; }
}
