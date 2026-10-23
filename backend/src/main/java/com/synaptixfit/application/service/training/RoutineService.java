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
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineUseCase;
import com.synaptixfit.application.port.input.training.ListCommunityRoutinesUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.application.port.input.training.PrivatizeUserRoutinesUseCase;
import com.synaptixfit.application.port.input.training.RemoveRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.RenameRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.ReorderRoutineExercisesUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.application.port.input.training.UpdateRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineWeekUseCase;
import com.synaptixfit.domain.exception.training.ExerciseInactiveException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineWeekLimitException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineOrigin;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Rutinas: alta, edición de estructura, estados, copias, comunidad y día pendiente. */
public class RoutineService implements CreateRoutineUseCase, GetRoutineUseCase, ListMyRoutinesUseCase,
        UpdateRoutineUseCase, ChangeRoutineStatusUseCase, DeleteRoutineUseCase, DuplicateRoutineUseCase,
        CloneRoutineUseCase, ListCommunityRoutinesUseCase, AddRoutineWeekUseCase, UpdateRoutineWeekUseCase,
        DeleteRoutineWeekUseCase, AddRoutineDayUseCase, RenameRoutineDayUseCase, DeleteRoutineDayUseCase,
        AddRoutineExerciseUseCase, UpdateRoutineExerciseUseCase, RemoveRoutineExerciseUseCase,
        ReorderRoutineExercisesUseCase, GetPendingTrainingDayUseCase, PrivatizeUserRoutinesUseCase {

    private final RoutineRepositoryPort routines;
    private final ExerciseRepositoryPort exercises;
    private final UserRepositoryPort users;
    private final Clock clock;

    public RoutineService(RoutineRepositoryPort routines, ExerciseRepositoryPort exercises, UserRepositoryPort users,
                          Clock clock) {
        this.routines = routines;
        this.exercises = exercises;
        this.users = users;
        this.clock = clock;
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
        Routine routine = Routine.create(c.userId(), c.name(), c.description(), c.visibility(),
                c.goal() == null ? TrainingGoal.HYPERTROPHY : c.goal(), c.startDate(), null, weeks, clock.instant());
        return routines.save(routine);
    }

    @Override
    public VisibleRoutine get(UUID userId, UUID routineId) {
        return routines.findVisible(routineId, userId).orElseThrow(() -> new RoutineNotFoundException(routineId));
    }

    @Override
    public PageResult<Routine> listMine(UUID userId, RoutineStatus status, PageRequest page) {
        return routines.findByOwner(userId, status, page);
    }

    @Override
    public PageResult<VisibleRoutine> listCommunity(UUID userId, String text, TrainingGoal goal, PageRequest page) {
        return routines.findCommunity(userId, text == null || text.isBlank() ? null : text.strip(), goal, page);
    }

    @Override
    public Optional<PendingDay> pendingDay(UUID userId) {
        return routines.findLatestActive(userId).flatMap(Routine::nextPendingDay);
    }

    // ------------------------------------------------------------------ datos generales y estado

    @Override
    public Routine update(UpdateRoutineUseCase.Command c) {
        Routine routine = owned(c.userId(), c.routineId());
        routine.updateDetails(c.name(), c.description(), c.visibility(), c.goal(), c.startDate(), c.clearStartDate());
        return routines.save(routine);
    }

    @Override
    public Routine changeStatus(UUID userId, UUID routineId, RoutineStatus status) {
        Routine routine = owned(userId, routineId);
        routine.changeStatus(status);
        return routines.save(routine);
    }

    @Override
    public void delete(UUID userId, UUID routineId) {
        Routine routine = owned(userId, routineId);
        routine.softDelete(clock.instant());
        routines.save(routine);
    }

    @Override
    public Routine duplicate(UUID userId, UUID routineId, String newName) {
        Routine source = owned(userId, routineId);
        return routines.save(source.copyFor(userId, newName, source.origin(), clock.instant()));
    }

    @Override
    public Routine cloneRoutine(UUID userId, UUID routineId) {
        VisibleRoutine visible = get(userId, routineId);
        Routine source = visible.routine();
        if (source.isOwnedBy(userId)) {
            return routines.save(source.copyFor(userId, null, source.origin(), clock.instant()));
        }
        String authorName = visible.authorName() != null ? visible.authorName()
                : users.findById(source.ownerId()).map(User::fullName).orElse(null);
        RoutineOrigin origin = new RoutineOrigin(source.id(), source.ownerId(), authorName);
        String name = source.name().length() > 108 ? source.name().substring(0, 108) : source.name();
        return routines.save(source.copyFor(userId, name + " (copiada)", origin, clock.instant()));
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
        Routine routine = owned(userId, routineId);
        routine.addWeek(name, type);
        return routines.save(routine);
    }

    @Override
    public Routine updateWeek(UUID userId, UUID routineId, UUID weekId, String name, WeekType type) {
        Routine routine = owned(userId, routineId);
        RoutineWeek week = routine.week(weekId);
        if (name != null) {
            week.rename(name);
        }
        if (type != null) {
            week.changeType(type);
        }
        return routines.save(routine);
    }

    @Override
    public Routine deleteWeek(UUID userId, UUID routineId, UUID weekId) {
        Routine routine = owned(userId, routineId);
        routine.removeWeek(weekId);
        return routines.save(routine);
    }

    @Override
    public Routine addDay(UUID userId, UUID routineId, UUID weekId, int dayNumber, String name) {
        Routine routine = owned(userId, routineId);
        routine.addDay(weekId, dayNumber, name);
        return routines.save(routine);
    }

    @Override
    public Routine renameDay(UUID userId, UUID routineId, UUID dayId, String name) {
        Routine routine = owned(userId, routineId);
        routine.day(dayId).rename(name);
        return routines.save(routine);
    }

    @Override
    public Routine deleteDay(UUID userId, UUID routineId, UUID dayId) {
        Routine routine = owned(userId, routineId);
        routine.removeDay(dayId);
        return routines.save(routine);
    }

    @Override
    public Routine addExercise(UUID userId, UUID routineId, UUID dayId, UUID exerciseId, ExerciseParameters parameters) {
        Routine routine = owned(userId, routineId);
        Exercise exercise = usable(exercises.findByIds(List.of(exerciseId)), exerciseId);
        routine.addExercise(dayId, exercise.toRef(), parameters);
        return routines.save(routine);
    }

    @Override
    public Routine updateExercise(UUID userId, UUID routineId, UUID plannedExerciseId, ExerciseParameters parameters) {
        Routine routine = owned(userId, routineId);
        routine.updateExercise(plannedExerciseId, parameters);
        return routines.save(routine);
    }

    @Override
    public Routine removeExercise(UUID userId, UUID routineId, UUID plannedExerciseId) {
        Routine routine = owned(userId, routineId);
        routine.removeExercise(plannedExerciseId);
        return routines.save(routine);
    }

    @Override
    public Routine reorder(UUID userId, UUID routineId, UUID dayId, List<UUID> orderedPlannedExerciseIds) {
        Routine routine = owned(userId, routineId);
        routine.reorderExercises(dayId, orderedPlannedExerciseIds);
        return routines.save(routine);
    }

    // ------------------------------------------------------------------ helpers

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
