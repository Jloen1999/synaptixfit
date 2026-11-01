package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.AddRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.ChangeRoutineStatusUseCase;
import com.synaptixfit.application.port.input.training.CloneRoutineUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.DuplicateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineUseCase;
import com.synaptixfit.application.port.input.training.ListCommunityRoutinesUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.application.port.input.training.PrivatizeUserRoutinesUseCase;
import com.synaptixfit.application.port.input.training.RemoveRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.RenameRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.ReorderRoutineExercisesUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.application.port.input.training.ReplaceRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineWeekUseCase;
import com.synaptixfit.domain.exception.training.ExerciseInactiveException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineWeekLimitException;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineOrigin;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.event.training.RoutineDaysRemoved;
import com.synaptixfit.domain.event.training.RoutineDeactivated;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

/**
 * Rutinas: alta, edición de estructura, estados, copias y comunidad.
 *
 * <p>Solo una rutina está en curso: una nueva (creada, generada, duplicada o clonada) solo queda en
 * curso si no hay otra, y activar una pausa la anterior ({@link RoutineLifecycle}). La visibilidad
 * nunca supera la del perfil del autor ({@link EffectiveVisibility}), como en los apuntes.
 */
public class RoutineService implements CreateRoutineUseCase, GetRoutineUseCase, ListMyRoutinesUseCase,
        UpdateRoutineUseCase, ChangeRoutineStatusUseCase, DeleteRoutineUseCase, DuplicateRoutineUseCase,
        CloneRoutineUseCase, ListCommunityRoutinesUseCase, AddRoutineWeekUseCase, UpdateRoutineWeekUseCase,
        DeleteRoutineWeekUseCase, AddRoutineDayUseCase, RenameRoutineDayUseCase, DeleteRoutineDayUseCase,
        AddRoutineExerciseUseCase, UpdateRoutineExerciseUseCase, RemoveRoutineExerciseUseCase,
        ReorderRoutineExercisesUseCase, ReplaceRoutineExerciseUseCase, PrivatizeUserRoutinesUseCase {

    private final RoutineRepositoryPort routines;
    private final ExerciseRepositoryPort exercises;
    private final UserRepositoryPort users;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final RoutineLifecycle lifecycle;

    public RoutineService(RoutineRepositoryPort routines, ExerciseRepositoryPort exercises, UserRepositoryPort users,
                          DomainEventPublisherPort events, Clock clock) {
        this.routines = routines;
        this.exercises = exercises;
        this.users = users;
        this.events = events;
        this.clock = clock;
        this.lifecycle = new RoutineLifecycle(routines, events, clock);
    }

    // ------------------------------------------------------------------ alta y consulta

    @Override
    public Routine create(CreateRoutineUseCase.Command c) {
        List<RoutineStructureInput.Week> input = c.weeks() == null ? List.of() : c.weeks();
        if (input.isEmpty() || input.size() > Routine.MAX_WEEKS) {
            throw new RoutineWeekLimitException();
        }
        Map<UUID, Exercise> catalog = exercises.findByIds(input.stream()
                .flatMap(w -> w.days().stream()).flatMap(d -> d.exercises().stream())
                .map(RoutineStructureInput.Exercise::exerciseId).distinct().toList());
        List<RoutineWeek> weeks = new ArrayList<>();
        for (int i = 0; i < input.size(); i++) {
            RoutineStructureInput.Week w = input.get(i);
            int number = i + 1;
            List<RoutineDay> days = new ArrayList<>();
            for (RoutineStructureInput.Day d : w.days()) {
                RoutineDay day = RoutineDay.create(d.dayNumber(), d.name());
                for (RoutineStructureInput.Exercise e : d.exercises()) {
                    day.addExercise(usable(catalog, e.exerciseId()).toRef(), e.parameters());
                }
                days.add(day);
            }
            WeekType type = w.type() == null ? WeekType.forPosition(number, input.size()) : w.type();
            weeks.add(RoutineWeek.create(number, w.name(), type, days));
        }
        Routine routine = Routine.create(c.userId(), c.name(), c.description(),
                allowedVisibility(c.userId(), c.visibility()),
                c.goal() == null ? TrainingGoal.HYPERTROPHY : c.goal(), c.startDate(), null, weeks, clock.instant());
        return lifecycle.saveNew(routine);
    }

    @Override
    public VisibleRoutine get(UUID userId, UUID routineId) {
        RoutineRepositoryPort.AuthoredRoutine found = routines.findWithAuthor(routineId, userId)
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
        Routine routine = found.routine();
        // La propia siempre; la ajena, según la regla única de contenido compartido.
        if (!routine.isOwnedBy(userId) && !EffectiveVisibility.canView(routine.visibility(), found.audience())) {
            throw new RoutineNotFoundException(routineId);
        }
        return new VisibleRoutine(routine, found.authorName());
    }

    @Override
    public PageResult<Routine> listMine(UUID userId, RoutineStatus status, PageRequest page) {
        return routines.findByOwner(userId, status, page);
    }

    @Override
    public PageResult<VisibleRoutine> listCommunity(UUID userId, String text, TrainingGoal goal, PageRequest page) {
        return routines.findCommunity(userId, text == null || text.isBlank() ? null : text.strip(), goal, page);
    }

    // ------------------------------------------------------------------ datos generales y estado

    @Override
    public Routine update(UpdateRoutineUseCase.Command c) {
        Routine routine = owned(c.userId(), c.routineId());
        Visibility visibility = c.visibility() == null ? null : allowedVisibility(c.userId(), c.visibility());
        routine.updateDetails(c.name(), c.description(), visibility, c.goal(), c.startDate(), c.clearStartDate());
        return routines.save(routine);
    }

    @Override
    public Routine changeStatus(UUID userId, UUID routineId, RoutineStatus status) {
        return mutate(userId, routineId, r -> r.changeStatus(status));
    }

    @Override
    public void delete(UUID userId, UUID routineId) {
        Routine routine = owned(userId, routineId);
        routine.softDelete(clock.instant());
        routines.save(routine);
        // Borrada (en curso o no): el calendario retira sus bloques futuros pendientes.
        events.publish(new RoutineDeactivated(userId, routineId, RoutineDeactivated.Reason.DELETED, clock.instant()));
    }

    @Override
    public Routine duplicate(UUID userId, UUID routineId, String newName) {
        Routine source = owned(userId, routineId);
        return lifecycle.saveNew(source.copyFor(userId, newName, source.origin(), clock.instant()));
    }

    @Override
    public Routine cloneRoutine(UUID userId, UUID routineId) {
        VisibleRoutine visible = get(userId, routineId);
        Routine source = visible.routine();
        if (source.isOwnedBy(userId)) {
            return lifecycle.saveNew(source.copyFor(userId, null, source.origin(), clock.instant()));
        }
        String authorName = visible.authorName() != null ? visible.authorName()
                : users.findById(source.ownerId()).map(User::fullName).orElse(null);
        RoutineOrigin origin = new RoutineOrigin(source.id(), source.ownerId(), authorName);
        String name = source.name().length() > 108 ? source.name().substring(0, 108) : source.name();
        return lifecycle.saveNew(source.copyFor(userId, name + " (copiada)", origin, clock.instant()));
    }

    @Override
    public int privatizeAll(UUID userId) {
        int changed = 0;
        for (Routine routine : routines.findAllByOwner(userId)) {
            if (routine.privatize()) {
                routines.save(routine);
                changed++;
            }
        }
        return changed;
    }

    // ------------------------------------------------------------------ estructura

    @Override
    public Routine addWeek(UUID userId, UUID routineId, String name, WeekType type) {
        return mutate(userId, routineId, r -> r.addWeek(name, type));
    }

    @Override
    public Routine updateWeek(UUID userId, UUID routineId, UUID weekId, String name, WeekType type) {
        return mutate(userId, routineId, r -> {
            RoutineWeek week = r.week(weekId);
            if (name != null) {
                week.rename(name);
            }
            if (type != null) {
                week.changeType(type);
            }
        });
    }

    @Override
    public Routine deleteWeek(UUID userId, UUID routineId, UUID weekId) {
        Routine routine = owned(userId, routineId);
        List<UUID> dayIds = routine.week(weekId).days().stream().map(RoutineDay::id).toList();
        RoutineStatus before = routine.status();
        routine.removeWeek(weekId);
        routine.finishCycleIfDone();
        announceRemovedDays(routine, dayIds);
        return lifecycle.save(routine, before);
    }

    @Override
    public Routine addDay(UUID userId, UUID routineId, UUID weekId, int dayNumber, String name) {
        return mutate(userId, routineId, r -> r.addDay(weekId, dayNumber, name));
    }

    @Override
    public Routine renameDay(UUID userId, UUID routineId, UUID dayId, String name) {
        return mutate(userId, routineId, r -> r.day(dayId).rename(name));
    }

    @Override
    public Routine deleteDay(UUID userId, UUID routineId, UUID dayId) {
        Routine routine = owned(userId, routineId);
        RoutineStatus before = routine.status();
        routine.removeDay(dayId);
        routine.finishCycleIfDone();
        announceRemovedDays(routine, List.of(dayId));
        return lifecycle.save(routine, before);
    }

    @Override
    public Routine addExercise(UUID userId, UUID routineId, UUID dayId, UUID exerciseId, ExerciseParameters parameters) {
        Exercise exercise = usable(exercises.findByIds(List.of(exerciseId)), exerciseId);
        return mutate(userId, routineId, r -> r.addExercise(dayId, exercise.toRef(), parameters));
    }

    @Override
    public Routine updateExercise(UUID userId, UUID routineId, UUID plannedExerciseId, ExerciseParameters parameters) {
        return mutate(userId, routineId, r -> r.updateExercise(plannedExerciseId, parameters));
    }

    @Override
    public Routine replaceExercise(UUID userId, UUID routineId, UUID plannedExerciseId, UUID exerciseId) {
        Exercise exercise = usable(exercises.findByIds(List.of(exerciseId)), exerciseId);
        return mutate(userId, routineId, r -> r.replaceExercise(plannedExerciseId, exercise.toRef()));
    }

    @Override
    public Routine removeExercise(UUID userId, UUID routineId, UUID plannedExerciseId) {
        return mutate(userId, routineId, r -> r.removeExercise(plannedExerciseId));
    }

    @Override
    public Routine reorder(UUID userId, UUID routineId, UUID dayId, List<UUID> orderedPlannedExerciseIds) {
        return mutate(userId, routineId, r -> r.reorderExercises(dayId, orderedPlannedExerciseIds));
    }

    // ------------------------------------------------------------------ helpers

    /**
     * Aplica un cambio a una rutina propia y la guarda con {@link RoutineLifecycle}: un cambio de
     * estructura puede reactivar una rutina completada, y entonces pausa la que estuviera en curso.
     */
    private Routine mutate(UUID userId, UUID routineId, Consumer<Routine> change) {
        Routine routine = owned(userId, routineId);
        RoutineStatus before = routine.status();
        change.accept(routine);
        return lifecycle.save(routine, before);
    }

    /**
     * Avisa de los días quitados <b>antes</b> de guardar: al borrarlos, la base de datos desenlaza sus
     * bloques del calendario y el planificador ya no podría encontrarlos.
     */
    private void announceRemovedDays(Routine routine, List<UUID> dayIds) {
        if (!dayIds.isEmpty()) {
            events.publish(new RoutineDaysRemoved(routine.ownerId(), routine.id(), dayIds, clock.instant()));
        }
    }

    /** Visibilidad pedida rebajada a la privacidad del perfil (un perfil privado no comparte nada). */
    private Visibility allowedVisibility(UUID userId, Visibility requested) {
        Visibility profile = users.findById(userId).map(User::privacy).orElse(Visibility.PRIVATE);
        return EffectiveVisibility.of(requested, profile);
    }

    private Routine owned(UUID userId, UUID routineId) {
        return routines.findById(routineId).filter(r -> r.isOwnedBy(userId))
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
    }

    private static Exercise usable(Map<UUID, Exercise> catalog, UUID exerciseId) {
        Exercise exercise = catalog.get(exerciseId);
        if (exercise == null) {
            throw new ExerciseNotFoundException(exerciseId);
        }
        if (!exercise.active()) {
            throw new ExerciseInactiveException();
        }
        return exercise;
    }
}
