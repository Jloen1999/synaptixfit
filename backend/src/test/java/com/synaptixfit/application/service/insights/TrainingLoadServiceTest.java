package com.synaptixfit.application.service.insights;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.application.port.input.insights.RecordTrainingLoadUseCase.Command;
import com.synaptixfit.domain.exception.insights.InvalidTimeZoneException;
import com.synaptixfit.domain.event.insights.OvertrainingDetected;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Carga física, idempotencia del oyente y recálculo del ACWR con el criterio corregido. */
class TrainingLoadServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-18T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 18);

    private InMemoryInsightsPorts ports;
    private TrainingLoadService service;

    @BeforeEach
    void setUp() {
        ports = new InMemoryInsightsPorts();
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        CognitiveStateService cognitive = new CognitiveStateService(ports.cognitivePort, ports.sourcePort, clock,
                ZoneId.of("UTC"));
        service = new TrainingLoadService(ports.loadPort, ports.regulationPort, cognitive, ports.sourcePort,
                ports.events::add, clock, ZoneId.of("UTC"));
    }

    @Test
    void completedSessionIsRecordedOnceAndAcwrRecalculated() {
        UUID session = UUID.randomUUID();
        Command completed = new Command(USER, session, TODAY, 0, 0, true);

        service.recordTrainingLoad(completed);
        service.recordTrainingLoad(completed); // evento repetido: idempotente

        assertThat(ports.loads).hasSize(1);
        PhysicalLoadRecord r = ports.loads.get(0);
        assertThat(r.rpe()).isEqualTo(PhysicalLoadRecord.DEFAULT_RPE);
        assertThat(r.durationMinutes()).isEqualTo(1);
        // Única sesión y sin historial previo: sin línea base no hay ACWR (zona NO_DATA).
        assertThat(ports.regulation.get(USER).acwr()).isNull();
    }

    @Test
    void repeatedSessionWithNewValuesUpdatesTheRecord() {
        UUID session = UUID.randomUUID();
        service.recordTrainingLoad(new Command(USER, session, TODAY, 6, 40, true));
        service.recordTrainingLoad(new Command(USER, session, TODAY, 8, 60, true));
        assertThat(ports.loads).singleElement().satisfies(r -> assertThat(r.load()).isEqualTo(480));
    }

    @Test
    void uncompletedSessionDeletesItsLoad() {
        UUID session = UUID.randomUUID();
        service.recordTrainingLoad(new Command(USER, session, TODAY, 7, 45, true));
        service.recordTrainingLoad(new Command(USER, session, TODAY, 7, 45, false));
        service.recordTrainingLoad(new Command(USER, session, TODAY, 7, 45, false)); // idempotente

        assertThat(ports.loads).isEmpty();
        assertThat(ports.regulation.get(USER).acwr()).isNull();
        assertThat(ports.regulation.get(USER).maxStudyMinutes()).isEqualTo(90);
    }

    @Test
    void acwrWindowsAreSevenAndTwentyEightDaysIncludingToday() {
        // 21 días antiguos (días 7..27 atrás) con 300 AU y 7 días recientes con 600 AU.
        for (int i = 0; i < 28; i++) {
            int minutes = i < 7 ? 60 : 30;
            ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY.minusDays(i), 10, minutes, NOW));
        }
        // Fuera de ambas ventanas: no cuenta.
        ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY.minusDays(28), 10, 600, NOW));

        CrossRegulationView view = service.getCrossRegulation(USER, null);

        double acute = 600.0;
        double chronic = (7 * 600.0 + 21 * 300.0) / 28;
        assertThat(view.state().acuteDailyLoad()).isCloseTo(acute, within(1e-9));
        assertThat(view.state().chronicDailyLoad()).isCloseTo(chronic, within(1e-9));
        assertThat(view.acwr()).isCloseTo(acute / chronic, within(1e-9)); // 1.6
        assertThat(view.zone()).isEqualTo(AcwrZone.OVERTRAINING);
        // T_max = 90 · (1 - 0.5 · ln(1.6 / 1.3)) ≈ 80.66 → 81
        assertThat(view.state().maxStudyMinutes()).isEqualTo(81);
    }

    @Test
    void upcomingExamAndWeeklyLoadReduceTheRecommendedVolume() {
        ports.nextExam = Instant.parse("2026-10-20T09:00:00Z");
        ports.weekly = new WeeklyAcademicLoad(LocalDate.of(2026, 10, 12), 20, 30, 5, 0, 10, 8);

        CrossRegulationView view = service.getCrossRegulation(USER, "UTC");

        assertThat(view.state().daysUntilExam()).isEqualTo(2);
        assertThat(view.academicLoad()).isCloseTo(0.65, within(1e-9));
        assertThat(view.recommendedVolumeFactor()).isCloseTo(1 - 0.4 * 0.65 * Math.exp(-0.3), within(1e-9));
    }

    @Test
    void physicalLoadSummaryFillsTheLast28Days() {
        ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY, 5, 40, NOW));
        ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY, 5, 20, NOW));
        ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY.minusDays(60), 10, 60, NOW));

        PhysicalLoadSummary summary = service.getPhysicalLoad(USER, null);

        assertThat(summary.todayLoad()).isEqualTo(300);
        assertThat(summary.maxDailyLoad()).isEqualTo(600);
        assertThat(summary.todayRatio()).isEqualTo(0.5);
        assertThat(summary.last28Days()).hasSize(28);
        assertThat(summary.last28Days().get(27).date()).isEqualTo(TODAY);
        assertThat(summary.last28Days().get(0).load()).isZero();
    }

    @Test
    void invalidTimeZoneIsRejected() {
        assertThatThrownBy(() -> service.getPhysicalLoad(USER, "Nowhere/City"))
                .isInstanceOf(InvalidTimeZoneException.class);
    }

    @Test
    void enteringOvertrainingIsAnnouncedOnce() {
        // Línea base baja (días 8-28) y una semana muy cargada: ACWR > 1.5.
        ports.loads.add(PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), TODAY.minusDays(20), 5, 30, NOW));
        UUID heavy = UUID.randomUUID();
        service.recordTrainingLoad(new Command(USER, heavy, TODAY, 9, 120, true));
        service.recordTrainingLoad(new Command(USER, heavy, TODAY, 9, 120, true));
        service.getCrossRegulation(USER, null);

        assertThat(ports.events).singleElement().isInstanceOfSatisfying(OvertrainingDetected.class,
                e -> assertThat(e.acwr()).isGreaterThan(1.5));
    }
}
