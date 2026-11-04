package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.application.port.input.training.GetTodayAdaptationUseCase;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleTracking;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.SessionAdaptation;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.port.output.training.CycleRepositoryPort;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Implementa {@link GetSessionAdaptationUseCase}: combina la regulación cruzada de Indicadores (examen y ACWR)
 * con el registro diario de hoy mediante {@link SessionAdaptation} y lo aplica a los ejercicios del día. Con el
 * seguimiento del ciclo activo ({@link CycleRepositoryPort}), el día apuntado hoy también cuenta (ajuste suave).
 * {@link GetTodayAdaptationUseCase} da lo mismo sin sesión, para explicarlo antes de entrenar.
 */
public class SessionAdaptationService implements GetSessionAdaptationUseCase, GetTodayAdaptationUseCase {

    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final DailyCheckInRepositoryPort checkIns;
    private final GetCrossRegulationUseCase crossRegulation;
    private final Clock clock;
    private final ZoneId zone;
    private final CycleRepositoryPort cycles;

    public SessionAdaptationService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                    DailyCheckInRepositoryPort checkIns, GetCrossRegulationUseCase crossRegulation,
                                    Clock clock, ZoneId zone) {
        this(sessions, routines, checkIns, crossRegulation, clock, zone, null);
    }

    /** @param cycles seguimiento del ciclo; nulo: no se tiene en cuenta */
    public SessionAdaptationService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                    DailyCheckInRepositoryPort checkIns, GetCrossRegulationUseCase crossRegulation,
                                    Clock clock, ZoneId zone, CycleRepositoryPort cycles) {
        this.cycles = cycles;
        this.sessions = sessions;
        this.routines = routines;
        this.checkIns = checkIns;
        this.crossRegulation = crossRegulation;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public GetSessionAdaptationUseCase.Result adaptation(UUID userId, UUID sessionId, String timeZone) {
        TrainingSession session = sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
        // Una sesión terminada o abandonada ya no se adapta: lo de hoy no dice nada de aquel día.
        SessionAdaptation adaptation = session.isCompleted() || session.isStale(clock.instant())
                ? SessionAdaptation.NONE : todays(userId, timeZone);
        Map<UUID, Integer> sets = new LinkedHashMap<>();
        for (PlannedExercise e : plannedExercises(session)) {
            int done = (int) session.sets().stream()
                    .filter(s -> e.id().equals(s.plannedExerciseId()) && s.completed()).count();
            sets.put(e.id(), adaptation.sets(e.parameters().sets(), done));
        }
        return new GetSessionAdaptationUseCase.Result(adaptation, sets);
    }

    /**
     * Regulación de Indicadores (zona del cliente) y registro diario de hoy (zona del servidor, como el resto
     * del registro diario). Leer la regulación la recalcula y puede avisar de sobreentrenamiento, igual que
     * cualquier otra lectura de Indicadores.
     */
    private SessionAdaptation todays(UUID userId, String timeZone) {
        return todays(userId, timeZone, checkIns.findByUserAndDate(userId, today()).orElse(null));
    }

    private SessionAdaptation todays(UUID userId, String timeZone, DailyCheckIn checkIn) {
        CrossRegulationView regulation = crossRegulation.getCrossRegulation(userId, timeZone);
        return SessionAdaptation.of(regulation.recommendedVolumeFactor(),
                regulation.zone() == AcwrZone.OVERTRAINING, checkIn, cycleDay(userId));
    }

    @Override
    public GetTodayAdaptationUseCase.Result today(UUID userId, String timeZone) {
        DailyCheckIn checkIn = checkIns.findByUserAndDate(userId, today()).orElse(null);
        return new GetTodayAdaptationUseCase.Result(todays(userId, timeZone, checkIn), checkIn != null);
    }

    /** Día del ciclo apuntado hoy, solo si el seguimiento está activo. */
    private CycleDay cycleDay(UUID userId) {
        if (cycles == null || !cycles.findTracking(userId).map(CycleTracking::enabled).orElse(false)) {
            return null;
        }
        return cycles.findDay(userId, today()).orElse(null);
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }

    private List<PlannedExercise> plannedExercises(TrainingSession session) {
        if (session.routineId() == null || session.dayId() == null) {
            return List.of();
        }
        return routines.findById(session.routineId())
                .flatMap(r -> r.findDay(session.dayId()))
                .map(RoutineDay::exercises)
                .orElse(List.of());
    }
}
