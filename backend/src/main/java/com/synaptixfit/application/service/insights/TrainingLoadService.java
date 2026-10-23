package com.synaptixfit.application.service.insights;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.RecordTrainingLoadUseCase;
import com.synaptixfit.domain.event.insights.OvertrainingDetected;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.DailyLoad;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.insights.TotalLoadFactor;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.insights.CrossRegulationRepositoryPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.insights.PhysicalLoadRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Carga física y regulación cruzada (fórmula 3). Sustituye al trigger {@code trg_insertar_carga_fisica}
 * y a la función {@code recalcular_regulacion_cruzada}. Publica {@link OvertrainingDetected} cuando el
 * ACWR entra en zona de sobreentrenamiento.
 */
public class TrainingLoadService implements RecordTrainingLoadUseCase, GetCrossRegulationUseCase,
        GetPhysicalLoadUseCase {

    private static final int SERIES_DAYS = 28;

    private final PhysicalLoadRepositoryPort loads;
    private final CrossRegulationRepositoryPort regulation;
    private final GetCognitiveStateUseCase cognitiveStates;
    private final InsightsSourcePort sources;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId defaultZone;

    public TrainingLoadService(PhysicalLoadRepositoryPort loads, CrossRegulationRepositoryPort regulation,
                               GetCognitiveStateUseCase cognitiveStates, InsightsSourcePort sources,
                               DomainEventPublisherPort events, Clock clock, ZoneId defaultZone) {
        this.loads = loads;
        this.regulation = regulation;
        this.cognitiveStates = cognitiveStates;
        this.sources = sources;
        this.events = events;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public void recordTrainingLoad(Command command) {
        Guard.notNull(command.userId(), "userId");
        Guard.notNull(command.sessionId(), "sessionId");
        if (command.completed()) {
            LocalDate date = command.date() != null ? command.date() : today(defaultZone);
            Optional<PhysicalLoadRecord> existing = loads.findBySession(command.userId(), command.sessionId());
            if (existing.isPresent()) {
                PhysicalLoadRecord record = existing.get();
                if (record.update(date, command.rpe(), command.durationMinutes())) {
                    loads.save(record);
                }
            } else {
                loads.save(PhysicalLoadRecord.forSession(command.userId(), command.sessionId(), date,
                        command.rpe(), command.durationMinutes(), clock.instant()));
            }
        } else {
            loads.deleteBySession(command.userId(), command.sessionId());
        }
        recalculate(command.userId(), defaultZone);
    }

    @Override
    public CrossRegulationView getCrossRegulation(UUID userId, String timeZone) {
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        CrossRegulationState state = recalculate(userId, zone);
        double academicLoad = academicLoad(userId, today(zone), zone);
        return new CrossRegulationView(state, state.acwr(), state.zone(), academicLoad,
                state.recommendedVolumeFactor(academicLoad));
    }

    @Override
    public PhysicalLoadSummary getPhysicalLoad(UUID userId, String timeZone) {
        ZoneId zone = TimeZones.resolve(timeZone, defaultZone);
        LocalDate today = today(zone);
        LocalDate from = today.minusDays(SERIES_DAYS - 1L);
        Map<LocalDate, Double> byDay = new HashMap<>();
        for (DailyLoad d : PhysicalLoadHistory.dailyLoads(loads.entriesBetween(userId, from, today))) {
            byDay.put(d.date(), d.load());
        }
        List<DailyLoad> series = new ArrayList<>(SERIES_DAYS);
        for (LocalDate d = from; !d.isAfter(today); d = d.plusDays(1)) {
            series.add(new DailyLoad(d, byDay.getOrDefault(d, 0.0)));
        }
        double todayLoad = byDay.getOrDefault(today, 0.0);
        double max = Math.max(PhysicalLoadHistory.maxDailyLoad(loads.allEntries(userId)), todayLoad);
        double ratio = max > 0 ? todayLoad / max : 0;
        return new PhysicalLoadSummary(today, todayLoad, max, ratio, series);
    }

    /** Recalcula y guarda el estado con ventanas de 7 y 28 días que terminan hoy (incluido). */
    private CrossRegulationState recalculate(UUID userId, ZoneId zone) {
        LocalDate today = today(zone);
        List<PhysicalLoadHistory.Entry> window = loads.entriesBetween(userId,
                today.minusDays(CrossRegulationState.CHRONIC_DAYS - 1L), today);
        double acute = PhysicalLoadHistory.total(window, today.minusDays(CrossRegulationState.ACUTE_DAYS - 1L), today);
        double chronic = PhysicalLoadHistory.total(window);
        Instant now = clock.instant();
        Integer daysUntilExam = sources.nextPendingExam(userId, now)
                .map(deadline -> (int) ChronoUnit.DAYS.between(today, LocalDate.ofInstant(deadline, zone)))
                .orElse(null);
        boolean wasOvertraining = regulation.findByUser(userId)
                .map(previous -> previous.zone() == AcwrZone.OVERTRAINING).orElse(false);
        CrossRegulationState saved =
                regulation.save(CrossRegulationState.compute(userId, acute, chronic, daysUntilExam, now));
        // Solo la entrada en la zona se anuncia: recalcular cada lectura no debe repetir el aviso.
        if (saved.zone() == AcwrZone.OVERTRAINING && !wasOvertraining) {
            events.publish(new OvertrainingDetected(userId, saved.acwr(), now));
        }
        return saved;
    }

    /**
     * Carga académica 0-1 para la fórmula 3A: el FCT de la semana si hay carga académica registrada
     * (como en la app antigua) y, si no, la carga cognitiva acumulada de hoy (recalculada, no la
     * guardada, que puede ser de un día anterior).
     */
    private double academicLoad(UUID userId, LocalDate today, ZoneId zone) {
        return sources.weeklyAcademicLoad(userId, TimeZones.weekStart(today))
                .map(w -> TotalLoadFactor.compute(w, sources.checkIn(userId, today).orElse(null)).value())
                .orElseGet(() -> cognitiveStates.getCognitiveState(userId, zone.getId()).cognitiveLoad());
    }

    private LocalDate today(ZoneId zone) {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
