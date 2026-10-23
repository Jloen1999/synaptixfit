package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Plan semanal (de lunes a domingo) que agrupa los bloques y entregas de esa semana.
 *
 * <p>Guardarlo da {@code 100 + 5 × nº de bloques} puntos una sola vez por plan
 * ({@code xp_planificacion_otorgado}). Hay como mucho un plan por usuario y semana: guardar de nuevo
 * reutiliza el existente. Se guarda cuánta experiencia se dio para restarla exactamente si se borra
 * el plan (si no, borrar y volver a guardar permitiría ganarla de nuevo).
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

    public static int experienceFor(int blockCount) {
        return BASE_EXPERIENCE + EXPERIENCE_PER_BLOCK * Math.max(0, blockCount);
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
