package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.training.CorrectTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.DeleteTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.DeleteSessionSetUseCase;
import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.GetTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ListTrainingSessionsUseCase;
import com.synaptixfit.application.port.input.training.LogPastRoutineSessionUseCase;
import com.synaptixfit.application.port.input.training.PauseTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.application.port.input.training.ResumeTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.UnmarkTrainingSessionUseCase;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionCorrected;
import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.exception.training.SessionDayMismatchException;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.exception.training.SessionPastDateInvalidException;
import com.synaptixfit.domain.exception.training.SessionStaleOpenException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.SessionCalories;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingRewards;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.GoalParameters;
import com.synaptixfit.domain.model.training.generation.SessionFeedback;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.RecommendationRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Ciclo de vida de las sesiones de entrenamiento.
 *
 * <p>Regla única de progreso: empezar una sesión pone el día en progreso; finalizarla lo completa
 * (y salta los días anteriores que quedaban: la rutina avanza por orden); desmarcarla (solo el mismo
 * día) lo devuelve a en progreso salvo que haya otra sesión completada de ese día; eliminarla lo
 * devuelve a pendiente. El estado de la semana se deriva de sus días y, si ya no queda nada, el ciclo
 * termina ({@link RoutineLifecycle}).
 *
 * <p>Sesiones abandonadas (abiertas más de 6 h): nunca se borran solas. Empezar ese día con una
 * pendiente da {@code SESSION_STALE_OPEN}; se terminan con lo registrado (cuentan en el día en que se
 * hicieron) o se descartan.
 *
 * <p>Experiencia: al finalizar se otorga {@link TrainingRewards#sessionXp} y se guarda la cantidad
 * en la sesión; al desmarcar o eliminar se resta exactamente esa cantidad.
 */
public class TrainingSessionService implements StartTrainingSessionUseCase, RecordSessionSetUseCase,
        DeleteSessionSetUseCase, FinishTrainingSessionUseCase, UnmarkTrainingSessionUseCase,
        DeleteTrainingSessionUseCase, CorrectTrainingSessionUseCase, LogPastRoutineSessionUseCase,
        ListTrainingSessionsUseCase, GetTrainingSessionUseCase, PauseTrainingSessionUseCase,
        ResumeTrainingSessionUseCase {

    /** Hasta cuántos días atrás se puede registrar una sesión pasada (igual que «Actividad pasada»). */
    static final int PAST_SESSION_MAX_DAYS = 7;
    /** Hora a la que se fecha una sesión pasada de otro día (la del día no se conoce). */
    static final LocalTime PAST_SESSION_TIME = LocalTime.NOON;

    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final ExerciseRepositoryPort exercises;
    private final RecommendationRepositoryPort recommendations;
    private final TrainingContextPort context;
    private final AwardExperienceUseCase awardExperience;
    private final RevokeExperienceUseCase revokeExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId zone;
    private final RoutineLifecycle lifecycle;

    /**
     * @param zone zona que define el «día» de una sesión; la misma que usan indicadores, insignias y
     *             retos, para que la carga física, la racha y el calendario caigan en el mismo día
     */
    public TrainingSessionService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                  ExerciseRepositoryPort exercises, RecommendationRepositoryPort recommendations, TrainingContextPort context,
                                  AwardExperienceUseCase awardExperience, RevokeExperienceUseCase revokeExperience,
                                  DomainEventPublisherPort events, Clock clock, ZoneId zone) {
        this.sessions = sessions;
        this.routines = routines;
        this.exercises = exercises;
        this.recommendations = recommendations;
        this.context = context;
        this.awardExperience = awardExperience;
        this.revokeExperience = revokeExperience;
        this.events = events;
        this.clock = clock;
        this.zone = zone;
        this.lifecycle = new RoutineLifecycle(routines, events, clock);
    }

    @Override
    public TrainingSession start(UUID userId, UUID routineId, UUID dayId) {
        Instant now = clock.instant();
        if (routineId == null) {
            if (dayId != null) {
                throw new SessionDayMismatchException();
            }
            return sessions.save(TrainingSession.start(userId, null, null, now));
        }
        Routine routine = ownedRoutine(userId, routineId);
        if (dayId == null) {
            return sessions.save(TrainingSession.start(userId, routineId, null, now));
        }
        RoutineDay day = routine.findDay(dayId).orElseThrow(SessionDayMismatchException::new);
        Optional<TrainingSession> existing = sessions.findInProgressForDay(userId, dayId);
        if (existing.isPresent()) {
            // Una sesión abandonada no se reanuda (series de otra jornada) ni se borra sin que la
            // persona lo decida: primero la termina con lo registrado o la descarta.
            if (existing.get().isStale(now)) {
                throw new SessionStaleOpenException(existing.get().id());
            }
            return existing.get();
        }
        sessions.lastCompletedAt(userId).ifPresent(last -> {
            int days = (int) ChronoUnit.DAYS.between(LocalDate.ofInstant(last, zone), today());
            SessionFeedback.afterInactivity(userId, routineId, days, day.exercises(), GoalParameters.of(routine.goal()), now)
                    .ifPresent(recommendations::save);
        });
        RoutineStatus before = routine.status();
        routine.startDay(dayId, today());
        lifecycle.save(routine, before);
        return sessions.save(TrainingSession.start(userId, routineId, dayId, now));
    }

    @Override
    public TrainingSession recordSet(RecordSessionSetUseCase.Command c) {
        TrainingSession session = owned(c.userId(), c.sessionId());
        applySet(session, c);
        return sessions.save(session);
    }

    @Override
    public TrainingSession pause(UUID userId, UUID sessionId) {
        TrainingSession session = owned(userId, sessionId);
        session.pause(clock.instant());
        return sessions.save(session);
    }

    @Override
    public TrainingSession resume(UUID userId, UUID sessionId, Instant resumedAt) {
        TrainingSession session = owned(userId, sessionId);
        session.resume(resumedAt, clock.instant());
        return sessions.save(session);
    }

    @Override
    public TrainingSession deleteSet(UUID userId, UUID sessionId, UUID setId) {
        TrainingSession session = owned(userId, sessionId);
        session.removeSet(setId);
        return sessions.save(session);
    }

    @Override
    public FinishTrainingSessionUseCase.Result finish(FinishTrainingSessionUseCase.Command c) {
        TrainingSession session = owned(c.userId(), c.sessionId());
        if (session.isCompleted()) {
            throw new SessionAlreadyCompletedException();
        }
        Optional<Routine> routine = session.routineId() == null ? Optional.empty() : routines.findById(session.routineId());
        if (c.sets() != null) {
            c.sets().forEach(s -> applySet(session, s, routine, true));
        }
        List<PlannedExercise> planned = routine.flatMap(r -> session.dayId() == null ? Optional.empty() : r.findDay(session.dayId()))
                .map(RoutineDay::exercises).orElse(List.of());
        Map<UUID, Integer> realDurations = new HashMap<>();
        if (c.realDurations() != null) {
            planned.forEach(p -> {
                Integer seconds = c.realDurations().get(p.id());
                if (seconds != null && seconds > 0) {
                    realDurations.put(p.id(), seconds);
                }
            });
        }
        Double weight = context.bodyWeightKg(c.userId()).orElse(null);
        Instant now = clock.instant();
        long duration = session.boundedDurationSeconds(c.durationSeconds(), now);
        double calories = SessionCalories.estimate(planned, realDurations, weight, duration);
        // Una sesión abandonada cuenta en el día en que se hizo, no en el de hoy.
        Instant completedAt = session.completionInstant(duration, now);
        LocalDate day = LocalDate.ofInstant(completedAt, zone);
        int minutes = TrainingSession.minutesOf(duration);
        int rewardedToday = rewardedOn(c.userId(), day, completedAt);
        int xp = TrainingRewards.sessionXp(minutes, c.rpe(), rewardedToday);
        session.complete(duration, c.rpe(), calories, xp, completedAt);
        TrainingSession saved = sessions.save(session);

        Optional<Routine> trained = routine.filter(r -> session.dayId() != null && r.findDay(session.dayId()).isPresent());
        trained.ifPresent(r -> realDurations.forEach((plannedId, seconds) ->
                r.plannedExercise(plannedId).recordRealDuration(seconds)));

        ExperienceChange experience = awardExperience.award(c.userId(), xp);
        Map<UUID, PlannedExercise> plannedById = planned.stream()
                .collect(Collectors.toMap(PlannedExercise::id, Function.identity()));
        TrainingGoal goal = routine.map(Routine::goal).orElse(TrainingGoal.HYPERTROPHY);
        List<Recommendation> suggestions = SessionFeedback.afterSession(saved, plannedById, GoalParameters.of(goal), now);
        recommendations.saveAll(suggestions);

        events.publish(new TrainingSessionCompletionChanged(c.userId(), saved.id(), day, c.rpe(),
                saved.durationMinutes(), saved.dayId(), true, now));
        trained.ifPresent(r -> closeDay(r, session.dayId(), day));
        return new FinishTrainingSessionUseCase.Result(saved, experience, suggestions,
                TrainingRewards.withheldReason(minutes, rewardedToday).orElse(null));
    }

    @Override
    public UnmarkTrainingSessionUseCase.Result unmark(UUID userId, UUID sessionId) {
        TrainingSession session = owned(userId, sessionId);
        TrainingSession.CompletionSnapshot snapshot = session.unmark(today(), zone);
        TrainingSession saved = sessions.save(session);

        if (session.routineId() != null && session.dayId() != null) {
            routines.findById(session.routineId()).ifPresent(r -> {
                if (r.findDay(session.dayId()).isPresent()
                        && !sessions.existsCompletedForDay(session.dayId(), session.id())) {
                    RoutineStatus before = r.status();
                    r.resetDay(session.dayId());
                    r.startDay(session.dayId(), today());
                    lifecycle.save(r, before);
                }
            });
        }
        ExperienceChange experience = revokeExperience.revoke(userId, snapshot.xpAwarded());
        events.publish(new TrainingSessionCompletionChanged(userId, saved.id(),
                LocalDate.ofInstant(snapshot.completedAt(), zone), snapshot.rpe(),
                snapshot.durationMinutes(), saved.dayId(), false, clock.instant()));
        return new UnmarkTrainingSessionUseCase.Result(saved, experience);
    }

    @Override
    public void delete(UUID userId, UUID sessionId) {
        TrainingSession session = owned(userId, sessionId);
        TrainingSession.CompletionSnapshot snapshot = session.isCompleted() ? session.snapshot() : null;
        sessions.delete(session.id());
        if (session.routineId() != null && session.dayId() != null) {
            routines.findById(session.routineId()).ifPresent(r -> {
                if (r.findDay(session.dayId()).isPresent()
                        && !sessions.existsCompletedForDay(session.dayId(), session.id())) {
                    RoutineStatus before = r.status();
                    r.resetDay(session.dayId());
                    lifecycle.save(r, before);
                }
            });
        }
        if (snapshot != null) {
            revokeExperience.revoke(userId, snapshot.xpAwarded());
            events.publish(new TrainingSessionCompletionChanged(userId, session.id(),
                    LocalDate.ofInstant(snapshot.completedAt(), zone), snapshot.rpe(), snapshot.durationMinutes(),
                    session.dayId(), false, clock.instant()));
        }
    }

    @Override
    public TrainingSession correct(CorrectTrainingSessionUseCase.Command c) {
        TrainingSession session = owned(c.userId(), c.sessionId());
        List<PlannedExercise> planned = plannedOf(session);
        Double weight = context.bodyWeightKg(c.userId()).orElse(null);
        double calories = SessionCalories.estimate(planned, Map.of(), weight, c.durationMinutes() * 60L);
        session.correct(c.rpe(), c.durationMinutes(), calories);
        TrainingSession saved = sessions.save(session);
        // Solo cambian las cifras: Indicadores actualiza su carga; calendario y retos no se tocan.
        events.publish(new TrainingSessionCorrected(c.userId(), saved.id(), saved.completedOn(zone),
                saved.rpe(), saved.durationMinutes(), clock.instant()));
        return saved;
    }

    @Override
    public LogPastRoutineSessionUseCase.Result logPast(LogPastRoutineSessionUseCase.Command c) {
        Instant now = clock.instant();
        LocalDate today = today();
        if (c.date() == null || c.date().isAfter(today) || c.date().isBefore(today.minusDays(PAST_SESSION_MAX_DAYS))) {
            throw new SessionPastDateInvalidException();
        }
        Routine routine = ownedRoutine(c.userId(), c.routineId());
        RoutineDay day = routine.findDay(c.dayId()).orElseThrow(SessionDayMismatchException::new);
        Instant completedAt = c.date().equals(today) ? now : c.date().atTime(PAST_SESSION_TIME).atZone(zone).toInstant();
        Double weight = context.bodyWeightKg(c.userId()).orElse(null);
        double calories = SessionCalories.estimate(day.exercises(), Map.of(), weight, c.durationMinutes() * 60L);
        int xp = TrainingRewards.sessionXp(c.durationMinutes(), c.rpe(), rewardedOn(c.userId(), c.date(), completedAt));
        TrainingSession saved = sessions.save(TrainingSession.logged(c.userId(), routine.id(), day.id(), completedAt,
                c.durationMinutes(), c.rpe(), calories, xp));
        ExperienceChange experience = awardExperience.award(c.userId(), xp);
        events.publish(new TrainingSessionCompletionChanged(c.userId(), saved.id(), c.date(), c.rpe(),
                saved.durationMinutes(), saved.dayId(), true, now));
        closeDay(routine, day.id(), c.date());
        return new LogPastRoutineSessionUseCase.Result(saved, experience);
    }

    @Override
    public PageResult<TrainingSession> list(UUID userId, Boolean completed, PageRequest page) {
        return sessions.findByUser(userId, completed, page);
    }

    @Override
    public TrainingSession get(UUID userId, UUID sessionId) {
        return owned(userId, sessionId);
    }

    // ------------------------------------------------------------------ helpers

    /**
     * Completa el día en la fecha de la sesión: salta los anteriores pendientes, cierra el ciclo si ya
     * no queda nada y avisa (días saltados, rutina completada). Se llama después de publicar
     * {@code TrainingSessionCompletionChanged}: el calendario marca primero el bloque del día entrenado
     * y solo después retira los bloques que ya no tocan (si no, al terminar el ciclo se borraría también
     * el bloque del día que se acaba de hacer).
     */
    private void closeDay(Routine routine, UUID dayId, LocalDate on) {
        RoutineStatus before = routine.status();
        List<UUID> skipped = routine.completeDay(dayId, on);
        routine.finishCycleIfDone();
        Routine saved = lifecycle.save(routine, before);
        lifecycle.daysSkipped(saved, skipped);
    }

    /** Sesiones que ya dieron XP ese día antes de {@code until} (para el tope diario). */
    private int rewardedOn(UUID userId, LocalDate day, Instant until) {
        Instant dayStart = day.atStartOfDay(zone).toInstant();
        Instant dayEnd = day.plusDays(1).atStartOfDay(zone).toInstant();
        return sessions.countRewardedBetween(userId, dayStart, until.isBefore(dayEnd) ? until : dayEnd);
    }

    private List<PlannedExercise> plannedOf(TrainingSession session) {
        if (session.routineId() == null || session.dayId() == null) {
            return List.of();
        }
        return routines.findById(session.routineId()).flatMap(r -> r.findDay(session.dayId()))
                .map(RoutineDay::exercises).orElse(List.of());
    }

    private void applySet(TrainingSession session, RecordSessionSetUseCase.Command c) {
        Optional<Routine> routine = c.plannedExerciseId() == null || session.routineId() == null
                ? Optional.empty() : routines.findById(session.routineId());
        applySet(session, c, routine, false);
    }

    /**
     * Registra la serie con el ejercicio que se hizo. Al apuntarla, el hueco debe existir en la rutina de la
     * sesión. Al terminar ({@code lenient}), una serie de un hueco que se quitó o sustituyó mientras tanto
     * (p. ej. apuntada sin conexión) se guarda como serie suelta en vez de hacer fallar toda la sesión.
     */
    private void applySet(TrainingSession session, RecordSessionSetUseCase.Command c, Optional<Routine> routine,
                          boolean lenient) {
        Optional<PlannedExercise> planned = c.plannedExerciseId() == null ? Optional.empty()
                : routine.flatMap(r -> r.findPlannedExercise(c.plannedExerciseId()));
        if (c.plannedExerciseId() != null && planned.isEmpty() && !lenient) {
            throw new RoutineExerciseNotFoundException(c.plannedExerciseId());
        }
        UUID plannedId = planned.map(PlannedExercise::id).orElse(null);
        UUID exerciseId = planned.map(p -> performedExercise(p, c.exerciseId(), lenient)).orElse(null);
        if (c.warmup()) {
            session.recordWarmupSet(plannedId, exerciseId, c.setNumber(), c.repsDone(), c.weightKg(),
                    c.durationSeconds(), c.distanceMeters(), c.activeSeconds());
            return;
        }
        session.recordSet(plannedId, exerciseId, c.setNumber(), c.repsDone(), c.weightKg(), c.completed(),
                c.failedReps(), c.durationSeconds(), c.distanceMeters(), c.activeSeconds(), c.toFailure());
    }

    /**
     * Ejercicio que se hizo en el hueco {@code planned}: el de la rutina o, con «Usar hoy», el que se eligió solo
     * para esta sesión (la rutina no cambia). Debe existir y estar activo; al terminar ({@code lenient}) uno que
     * ya no esté se apunta con el del hueco en vez de hacer fallar toda la sesión.
     */
    private UUID performedExercise(PlannedExercise planned, UUID chosen, boolean lenient) {
        if (chosen == null || chosen.equals(planned.exerciseId())) {
            return planned.exerciseId();
        }
        boolean usable = exercises.findById(chosen).filter(Exercise::active).isPresent();
        if (usable) {
            return chosen;
        }
        if (lenient) {
            return planned.exerciseId();
        }
        throw new ExerciseNotFoundException(chosen);
    }

    private TrainingSession owned(UUID userId, UUID sessionId) {
        return sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
    }

    private Routine ownedRoutine(UUID userId, UUID routineId) {
        return routines.findById(routineId).filter(r -> r.isOwnedBy(userId))
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
