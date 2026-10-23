package com.synaptixfit.application.service.insights;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyActivityUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.InitializeCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.RefreshCognitiveStateUseCase;
import com.synaptixfit.domain.model.insights.BodyProfile;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.StudyActivity;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.port.output.insights.CognitiveStateRepositoryPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

/**
 * Estado cognitivo (fórmula 2), gasto calórico del estudio (fórmula 1) y actividad de estudio de un
 * periodo. Sustituye al trigger {@code trg_inicializar_estado_cognitivo} y a la lógica de
 * {@code completarBloqueEstudio} del cliente. La carga, los minutos y las kcal de hoy salen de la misma
 * lista ({@link StudyActivity}): bloques cognitivos completados y práctica sin bloque (Pomodoro, tests,
 * repasos SM-2); las kcal de la práctica se estiman con el RMR porque el planificador solo guarda las
 * de los bloques.
 *
 * <p>Solo {@link #refreshCognitiveState} (oyentes de eventos) guarda el estado; las lecturas lo
 * recalculan en memoria, así un {@code GET} no escribe en la base de datos.
 */
public class CognitiveStateService implements InitializeCognitiveStateUseCase, RefreshCognitiveStateUseCase,
        GetCognitiveStateUseCase, GetStudyCaloriesTodayUseCase, GetStudyActivityUseCase {

    private final CognitiveStateRepositoryPort states;
    private final InsightsSourcePort sources;
    private final Clock clock;
    private final ZoneId defaultZone;

    public CognitiveStateService(CognitiveStateRepositoryPort states, InsightsSourcePort sources, Clock clock,
                                 ZoneId defaultZone) {
        this.states = states;
        this.sources = sources;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public void initializeCognitiveState(UUID userId) {
        if (states.findByUser(userId).isEmpty()) {
            states.save(CognitiveState.initial(userId, clock.instant()));
        }
    }

    @Override
    public void refreshCognitiveState(Command command) {
        if (command.activityType() != null && !CompletedStudyBlock.isCognitive(command.activityType())) {
            return;
        }
        states.save(recompute(command.userId(), defaultZone));
    }

    @Override
    public CognitiveState getCognitiveState(UUID userId, String timeZone) {
        return recompute(userId, TimeZones.resolve(timeZone, defaultZone));
    }

    @Override
    public StudyCaloriesSummary getStudyCaloriesToday(UUID userId, String timeZone) {
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        Double rmr = sources.bodyProfile(userId).map(BodyProfile::restingMetabolicRate)
                .orElseGet(() -> states.findByUser(userId).map(CognitiveState::rmrBase).orElse(null));
        return StudyCaloriesSummary.of(today, todayActivities(userId, today, zone), rmr);
    }

    @Override
    public List<CompletedStudyBlock> getStudyActivity(UUID userId, Instant from, Instant to) {
        return StudyActivity.of(sources.completedStudyBlocks(userId, from, to), sources.practiceLog(userId, from, to));
    }

    /** Estado recalculado en memoria (sin guardar) con la actividad de hoy en {@code zone}. */
    private CognitiveState recompute(UUID userId, ZoneId zone) {
        Instant now = clock.instant();
        LocalDate today = LocalDate.ofInstant(now, zone);
        Double rmr = sources.bodyProfile(userId).map(BodyProfile::restingMetabolicRate).orElse(null);
        CognitiveState state = states.findByUser(userId).orElseGet(() -> CognitiveState.initial(userId, now));
        state.recompute(todayActivities(userId, today, zone), rmr, now);
        return state;
    }

    private List<CompletedStudyBlock> todayActivities(UUID userId, LocalDate today, ZoneId zone) {
        return getStudyActivity(userId, TimeZones.startOfDay(today, zone), TimeZones.startOfDay(today.plusDays(1), zone));
    }
}
