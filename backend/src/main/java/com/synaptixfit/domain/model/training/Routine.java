package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineHasEmptyDaysException;
import com.synaptixfit.domain.exception.training.RoutineWeekLimitException;
import com.synaptixfit.domain.exception.training.RoutineWeekNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Rutina de entrenamiento: agregado rutina → semanas → días → ejercicios planificados.
 *
 * <p>Reglas: entre 1 y {@link #MAX_WEEKS} semanas numeradas de forma consecutiva; el número de
 * ejercicios ({@code cantidad_ejercicios}) siempre es la suma de los de todos los días; solo se
 * puede completar si tiene días y ninguno está vacío; cualquier cambio de estructura sobre una
 * rutina completada la reactiva.
 */
public final class Routine {

    public static final int MAX_WEEKS = 52;

    private final UUID id;
    private final UUID ownerId;
    private String name;
    private String description;
    private Visibility visibility;
    private RoutineStatus status;
    private TrainingGoal goal;
    private LocalDate startDate;
    private final RoutineOrigin origin;
    private final Instant createdAt;
    private Instant deletedAt;
    private final List<RoutineWeek> weeks;

    public Routine(UUID id, UUID ownerId, String name, String description, Visibility visibility,
                   RoutineStatus status, TrainingGoal goal, LocalDate startDate, RoutineOrigin origin,
                   Instant createdAt, Instant deletedAt, List<RoutineWeek> weeks) {
        this.id = Objects.requireNonNull(id, "id");
        this.ownerId = Objects.requireNonNull(ownerId, "ownerId");
        this.name = normalizeName(name);
        this.description = normalizeDescription(description);
        this.visibility = visibility == null ? Visibility.PRIVATE : visibility;
        this.status = status == null ? RoutineStatus.ACTIVE : status;
        this.goal = goal == null ? TrainingGoal.HYPERTROPHY : goal;
        this.startDate = startDate;
        this.origin = origin;
        this.createdAt = createdAt;
        this.deletedAt = deletedAt;
        this.weeks = new ArrayList<>(weeks == null ? List.of() : weeks);
        this.weeks.sort(Comparator.comparingInt(RoutineWeek::number));
    }

    /** Crea una rutina nueva y valida su estructura. Las semanas se numeran por posición. */
    public static Routine create(UUID ownerId, String name, String description, Visibility visibility,
                                 TrainingGoal goal, LocalDate startDate, RoutineOrigin origin,
                                 List<RoutineWeek> weeks, Instant now) {
        if (weeks == null || weeks.isEmpty() || weeks.size() > MAX_WEEKS) {
            throw new RoutineWeekLimitException();
        }
        Routine routine = new Routine(UUID.randomUUID(), ownerId, name, description, visibility,
                RoutineStatus.ACTIVE, goal, startDate, origin, now, null, weeks);
        routine.renumberWeeks();
        routine.weeks.forEach(RoutineWeek::recomputeStatus);
        return routine;
    }

    private static String normalizeName(String name) {
        return Guard.length(name, "name", 3, 120);
    }

    private static String normalizeDescription(String description) {
        if (description == null || description.isBlank()) {
            return null;
        }
        String d = description.strip();
        return d.length() > 2000 ? Guard.length(d, "description", 0, 2000) : d;
    }

    // ------------------------------------------------------------------ datos generales

    public void updateDetails(String newName, String newDescription, Visibility newVisibility,
                              TrainingGoal newGoal, LocalDate newStartDate, boolean clearStartDate) {
        if (newName != null) {
            this.name = normalizeName(newName);
        }
        if (newDescription != null) {
            this.description = normalizeDescription(newDescription);
        }
        if (newVisibility != null) {
            this.visibility = newVisibility;
        }
        if (newGoal != null) {
            this.goal = newGoal;
        }
        if (clearStartDate) {
            this.startDate = null;
        } else if (newStartDate != null) {
            this.startDate = newStartDate;
        }
    }

    public void changeStatus(RoutineStatus target) {
        Guard.notNull(target, "status");
        if (target == RoutineStatus.COMPLETED) {
            boolean hasDays = weeks.stream().anyMatch(w -> !w.days().isEmpty());
            boolean emptyDay = weeks.stream().flatMap(w -> w.days().stream()).anyMatch(RoutineDay::isEmpty);
            if (!hasDays || emptyDay) {
                throw new RoutineHasEmptyDaysException();
            }
        }
        this.status = target;
    }

    /** Oculta la rutina (al pasar el perfil del autor a privado). Devuelve si cambió algo. */
    public boolean privatize() {
        if (visibility == Visibility.PRIVATE) {
            return false;
        }
        visibility = Visibility.PRIVATE;
        return true;
    }

    public void softDelete(Instant when) {
        if (deletedAt == null) {
            deletedAt = Objects.requireNonNull(when);
        }
    }

    /** Primera sesión: fija la fecha de inicio si no la tenía. */
    public void markStarted(LocalDate today) {
        if (startDate == null) {
            startDate = today;
        }
    }

    // ------------------------------------------------------------------ estructura

    public RoutineWeek addWeek(String weekName, WeekType type) {
        if (weeks.size() >= MAX_WEEKS) {
            throw new RoutineWeekLimitException();
        }
        int number = weeks.size() + 1;
        RoutineWeek week = RoutineWeek.create(number, weekName,
                type == null ? WeekType.forPosition(number, number) : type, List.of());
        weeks.add(week);
        structureChanged();
        return week;
    }

    public void removeWeek(UUID weekId) {
        RoutineWeek week = findWeek(weekId).orElseThrow(() -> new RoutineWeekNotFoundException(weekId));
        if (weeks.size() <= 1) {
            throw new RoutineWeekLimitException();
        }
        weeks.remove(week);
        renumberWeeks();
        structureChanged();
    }

    public RoutineWeek week(UUID weekId) {
        return findWeek(weekId).orElseThrow(() -> new RoutineWeekNotFoundException(weekId));
    }

    public Optional<RoutineWeek> findWeek(UUID weekId) {
        return weeks.stream().filter(w -> w.id().equals(weekId)).findFirst();
    }

    public RoutineDay addDay(UUID weekId, int dayNumber, String dayName) {
        RoutineDay day = week(weekId).addDay(dayNumber, dayName);
        structureChanged();
        return day;
    }

    public void removeDay(UUID dayId) {
        RoutineWeek week = weekOfDay(dayId);
        week.removeDay(dayId);
        structureChanged();
    }

    public RoutineDay day(UUID dayId) {
        return findDay(dayId).orElseThrow(() -> new RoutineDayNotFoundException(dayId));
    }

    public Optional<RoutineDay> findDay(UUID dayId) {
        return weeks.stream().flatMap(w -> w.days().stream()).filter(d -> d.id().equals(dayId)).findFirst();
    }

    public RoutineWeek weekOfDay(UUID dayId) {
        return weeks.stream().filter(w -> w.findDay(dayId).isPresent()).findFirst()
                .orElseThrow(() -> new RoutineDayNotFoundException(dayId));
    }

    public PlannedExercise addExercise(UUID dayId, ExerciseRef exercise, ExerciseParameters parameters) {
        PlannedExercise planned = day(dayId).addExercise(exercise, parameters);
        structureChanged();
        return planned;
    }

    public void removeExercise(UUID plannedExerciseId) {
        dayOfExercise(plannedExerciseId).removeExercise(plannedExerciseId);
        structureChanged();
    }

    public void updateExercise(UUID plannedExerciseId, ExerciseParameters parameters) {
        plannedExercise(plannedExerciseId).changeParameters(parameters);
    }

    public void reorderExercises(UUID dayId, List<UUID> orderedIds) {
        day(dayId).reorder(orderedIds);
    }

    public PlannedExercise plannedExercise(UUID plannedExerciseId) {
        return findPlannedExercise(plannedExerciseId)
                .orElseThrow(() -> new RoutineExerciseNotFoundException(plannedExerciseId));
    }

    public Optional<PlannedExercise> findPlannedExercise(UUID plannedExerciseId) {
        return allDays().stream().flatMap(d -> d.exercises().stream())
                .filter(e -> e.id().equals(plannedExerciseId)).findFirst();
    }

    private RoutineDay dayOfExercise(UUID plannedExerciseId) {
        return allDays().stream().filter(d -> d.findExercise(plannedExerciseId).isPresent()).findFirst()
                .orElseThrow(() -> new RoutineExerciseNotFoundException(plannedExerciseId));
    }

    // ------------------------------------------------------------------ progreso

    /** Se ha empezado una sesión del día. */
    public void startDay(UUID dayId, LocalDate today) {
        day(dayId).markInProgress();
        weekOfDay(dayId).recomputeStatus();
        markStarted(today);
    }

    /** Se ha completado una sesión del día. */
    public void completeDay(UUID dayId) {
        day(dayId).markCompleted();
        weekOfDay(dayId).recomputeStatus();
    }

    /** El día vuelve a pendiente (sesión desmarcada o cancelada sin otra completada). */
    public void resetDay(UUID dayId) {
        day(dayId).markPending();
        weekOfDay(dayId).recomputeStatus();
    }

    /** Primer día no completado, recorriendo semanas y días en orden. */
    public Optional<PendingDay> nextPendingDay() {
        for (RoutineWeek week : weeks) {
            for (RoutineDay day : week.days()) {
                if (day.status() != ProgressStatus.COMPLETED) {
                    return Optional.of(new PendingDay(this, week, day));
                }
            }
        }
        return Optional.empty();
    }

    // ------------------------------------------------------------------ copias

    /**
     * Copia profunda para otro usuario (clonar) o el mismo (duplicar): ids nuevos, progreso a cero,
     * privada, activa y sin fecha de inicio.
     */
    public Routine copyFor(UUID newOwnerId, String newName, RoutineOrigin newOrigin, Instant now) {
        String copyName = newName == null || newName.isBlank() ? truncate(name + " (copia)") : newName;
        return new Routine(UUID.randomUUID(), newOwnerId, copyName, description, Visibility.PRIVATE,
                RoutineStatus.ACTIVE, goal, null, newOrigin, now, null,
                weeks.stream().map(RoutineWeek::copyReset).toList());
    }

    private static String truncate(String value) {
        return value.length() > 120 ? value.substring(0, 120) : value;
    }

    // ------------------------------------------------------------------ helpers

    private void renumberWeeks() {
        weeks.sort(Comparator.comparingInt(RoutineWeek::number));
        for (int i = 0; i < weeks.size(); i++) {
            weeks.get(i).renumber(i + 1);
        }
    }

    private void structureChanged() {
        if (status == RoutineStatus.COMPLETED) {
            status = RoutineStatus.ACTIVE;
        }
    }

    public List<RoutineDay> allDays() {
        return weeks.stream().flatMap(w -> w.days().stream()).toList();
    }

    public int exerciseCount() {
        return allDays().stream().mapToInt(d -> d.exercises().size()).sum();
    }

    public int totalDays() {
        return allDays().size();
    }

    public int completedDays() {
        return (int) allDays().stream().filter(d -> d.status() == ProgressStatus.COMPLETED).count();
    }

    public boolean isOwnedBy(UUID userId) {
        return ownerId.equals(userId);
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    public UUID id() { return id; }
    public UUID ownerId() { return ownerId; }
    public String name() { return name; }
    public String description() { return description; }
    public Visibility visibility() { return visibility; }
    public RoutineStatus status() { return status; }
    public TrainingGoal goal() { return goal; }
    public LocalDate startDate() { return startDate; }
    public RoutineOrigin origin() { return origin; }
    public Instant createdAt() { return createdAt; }
    public Instant deletedAt() { return deletedAt; }
    public int durationWeeks() { return weeks.size(); }
    public List<RoutineWeek> weeks() { return List.copyOf(weeks); }
}
