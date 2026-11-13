package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Plan semanal (de lunes a domingo) que agrupa los bloques y entregas de esa semana.
 *
 * <p>Planificar la semana da {@code 100 + 5 × nº de eventos planificados} puntos una sola vez por
 * semana ({@code xp_planificacion_otorgado}), sin botón: el planificador lo concede al llegar a
 * {@link #MIN_PLANNED_EVENTS} eventos planificados en la semana actual o la siguiente (ADR 0038). Hay
 * como mucho un plan por usuario y semana (índice único). Se guarda cuánta experiencia se dio para
 * restarla exactamente si se borra el plan; borrar eventos después no la quita.
 */
public final class StudyPlan {

    public static final int BASE_EXPERIENCE = 100;
    public static final int EXPERIENCE_PER_BLOCK = 5;

    private final UUID id;
    private final UUID userId;
    private String name;
    private final LocalDate weekStart;
    private Visibility visibility;
    private boolean xpAwarded;
    private int xpPoints;

    public StudyPlan(UUID id, UUID userId, String name, LocalDate weekStart, Visibility visibility, boolean xpAwarded,
                     int xpPoints) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.name = Guard.length(name, "name", 2, 120);
        this.weekStart = PlannerZone.mondayOf(Guard.notNull(weekStart, "weekStart"));
        this.visibility = visibility == null ? Visibility.PRIVATE : visibility;
        this.xpAwarded = xpAwarded;
        this.xpPoints = Math.max(0, xpPoints);
    }

    /**
     * Eventos planificados (no fijos ni importados, de los que cuentan en el plan) que hacen falta para
     * dar la experiencia. Uno solo no es planificar la semana y, con 3, crear y borrar eventos sueltos
     * no la da antes de tiempo.
     */
    public static final int MIN_PLANNED_EVENTS = 3;

    /** Eventos de la semana que planificó la persona ({@link CalendarBlock#plannedByPerson()}). */
    public static int plannedEvents(List<CalendarBlock> weekBlocks) {
        return (int) weekBlocks.stream().filter(CalendarBlock::plannedByPerson).count();
    }

    public static int experienceFor(int blockCount) {
        return BASE_EXPERIENCE + EXPERIENCE_PER_BLOCK * Math.max(0, blockCount);
    }

    /**
     * ¿Se puede dar ya la experiencia de planificar la semana del lunes {@code monday}? Solo la semana de
     * {@code today} y la siguiente: planificar meses vacíos por adelantado no es planificar y, sin ese
     * límite, bastarían 3 eventos por semana futura para ganarla 52 veces seguidas.
     */
    public static boolean rewardable(int plannedEvents, LocalDate monday, LocalDate today) {
        LocalDate current = PlannerZone.mondayOf(today);
        LocalDate week = PlannerZone.mondayOf(monday);
        return plannedEvents >= MIN_PLANNED_EVENTS && !week.isBefore(current) && !week.isAfter(current.plusWeeks(1));
    }

    public void rename(String newName) {
        if (newName != null) {
            this.name = Guard.length(newName, "name", 2, 120);
        }
    }

    public void changeVisibility(Visibility newVisibility) {
        if (newVisibility != null) {
            this.visibility = newVisibility;
        }
    }

    /** Deja de compartir el plan. Devuelve true si cambia. */
    public boolean privatize() {
        if (visibility == Visibility.PRIVATE) {
            return false;
        }
        visibility = Visibility.PRIVATE;
        return true;
    }

    public void markExperienceAwarded(int points) {
        this.xpAwarded = true;
        this.xpPoints = Math.max(0, points);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String name() { return name; }
    public LocalDate weekStart() { return weekStart; }
    public LocalDate weekEnd() { return weekStart.plusDays(6); }
    public Visibility visibility() { return visibility; }
    public boolean xpAwarded() { return xpAwarded; }
    public int xpPoints() { return xpPoints; }
}
