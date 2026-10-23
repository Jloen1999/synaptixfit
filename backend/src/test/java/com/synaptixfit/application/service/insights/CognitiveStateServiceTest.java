package com.synaptixfit.application.service.insights;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.application.port.input.insights.RefreshCognitiveStateUseCase;
import com.synaptixfit.domain.model.insights.AcademicAdherence;
import com.synaptixfit.domain.model.insights.BodyProfile;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.PracticeSessions;
import com.synaptixfit.domain.model.insights.StudyActivity;
import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import com.synaptixfit.domain.model.neuro.BiologicalSex;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Estado cognitivo (oyentes idempotentes), calorías de estudio y bienestar. */
class CognitiveStateServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-18T18:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 18);

    private InMemoryInsightsPorts ports;
    private CognitiveStateService service;
    private WellbeingService wellbeing;

    @BeforeEach
    void setUp() {
        ports = new InMemoryInsightsPorts();
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        service = new CognitiveStateService(ports.cognitivePort, ports.sourcePort, clock, ZoneId.of("UTC"));
        wellbeing = new WellbeingService(ports.sourcePort, clock, ZoneId.of("UTC"));
    }

    @Test
    void initializationIsIdempotent() {
        service.initializeCognitiveState(USER);
        CognitiveState first = ports.cognitive.get(USER);
        service.initializeCognitiveState(USER);
        assertThat(ports.cognitive.get(USER)).isSameAs(first);
        assertThat(ports.cognitiveSaves).isEqualTo(1);
        assertThat(first.cognitiveLoad()).isZero();
        assertThat(first.attentionCapacity()).isEqualTo(1.0);
    }

    @Test
    void nonCognitiveBlocksAreIgnored() {
        service.refreshCognitiveState(new RefreshCognitiveStateUseCase.Command(USER, "deporte"));
        assertThat(ports.cognitiveSaves).isZero();
    }

    @Test
    void refreshRecomputesOnlyTodaysBlocksAndIsRepeatable() {
        ports.profile = new BodyProfile(70, 175, 22, BiologicalSex.MALE);
        Instant t0 = Instant.parse("2026-10-18T09:00:00Z");
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "estudio", t0, t0.plusSeconds(300), 3, null));
        // Ayer: no cuenta para el estado de hoy.
        Instant yesterday = Instant.parse("2026-10-17T09:00:00Z");
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "estudio", yesterday, yesterday.plusSeconds(3600), 5, null));

        RefreshCognitiveStateUseCase.Command cmd = new RefreshCognitiveStateUseCase.Command(USER, "estudio");
        service.refreshCognitiveState(cmd);
        double load = ports.cognitive.get(USER).cognitiveLoad();
        service.refreshCognitiveState(cmd);

        CognitiveState state = ports.cognitive.get(USER);
        // Fórmula 2 v2: 5 min × 1,3 = 6,5 min equivalentes; C = 1 - e^(-E/τ), τ = 240/ln 5.
        assertThat(state.cognitiveLoad()).isEqualTo(load).isCloseTo(1 - Math.exp(-6.5 / (240 / Math.log(5))), within(1e-9));
        assertThat(state.lastBlockMinutes()).isEqualTo(5);
        // RMR Mifflin-St Jeor: 700 + 1093.75 - 110 + 5
        assertThat(state.rmrBase()).isCloseTo(1688.75, within(1e-9));
    }

    @Test
    void studyCaloriesOfToday() {
        ports.profile = new BodyProfile(70, 175, 22, BiologicalSex.MALE);
        Instant t0 = Instant.parse("2026-10-18T09:00:00Z");
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "clase", t0, t0.plusSeconds(3600), null, null));

        StudyCaloriesSummary summary = service.getStudyCaloriesToday(USER, null);

        assertThat(summary.date()).isEqualTo(TODAY);
        assertThat(summary.totalCalories()).isCloseTo(1688.75 / 86400 * 3600 * 1.8, within(1e-9));
        assertThat(summary.studyMinutes()).isEqualTo(60);
    }

    @Test
    void wellbeingWithoutDataHasNullComponents() {
        WellbeingSnapshot w = wellbeing.getWellbeing(USER, null);
        assertThat(w.checkInDone()).isFalse();
        assertThat(w.energy()).isNull();
        assertThat(w.adherence()).isNull();
        assertThat(w.totalLoad()).isNull();
    }

    @Test
    void wellbeingWithCheckInAndWeeklyLoad() {
        ports.checkIns.add(new DailyCheckIn(TODAY, 4, 2, 4, 2, true));
        ports.weekly = new WeeklyAcademicLoad(LocalDate.of(2026, 10, 12), 10, 5, 1, 1, 4, 7);
        ports.deadlineCounts = new InsightsSourcePort.DeadlineCounts(2, 1);
        Instant monday = Instant.parse("2026-10-12T10:00:00Z");
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "estudio", monday, monday.plusSeconds(3600), 3, null));
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "repaso", monday.plusSeconds(7200),
                monday.plusSeconds(9000), 3, null));
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "clase", NOW.minusSeconds(7200),
                NOW.minusSeconds(3600), 3, null));

        WellbeingSnapshot w = wellbeing.getWellbeing(USER, null);

        assertThat(w.checkInDone()).isTrue();
        assertThat(w.energy()).isNotNull();
        AcademicAdherence a = w.adherence();
        assertThat(a.studyDays()).isEqualTo(1); // la clase no cuenta como día de estudio
        assertThat(a.score()).isCloseTo(0.5 * 60 + 0.5 * 30 + 10.0 / 7, within(1e-9));
        assertThat(w.totalLoad()).isNotNull();
    }

    @Test
    void practiceWithoutBlockAddsCognitiveLoadAndExamBlocksCountToo() {
        service.refreshCognitiveState(new RefreshCognitiveStateUseCase.Command(USER, "examen"));
        assertThat(ports.cognitiveSaves).isEqualTo(1);
        assertThat(ports.cognitive.get(USER).cognitiveLoad()).isZero();

        Instant end = Instant.parse("2026-10-18T10:00:00Z");
        ports.focus.add(new PracticeSessions.Focus(UUID.randomUUID(), end, 25, 3, false));
        ports.reviews.add(new PracticeSessions.Review(UUID.randomUUID(), end.plusSeconds(600), UUID.randomUUID(), null));
        // Práctica sin bloque: tipo nulo, siempre se recalcula.
        service.refreshCognitiveState(new RefreshCognitiveStateUseCase.Command(USER, null));

        CognitiveState state = ports.cognitive.get(USER);
        assertThat(state.cognitiveLoad()).isPositive();
        assertThat(state.lastBlockMinutes()).isEqualTo(CompletedStudyBlock.REVIEW_MINUTES);
    }

    @Test
    void practiceAlreadyCountedByACompletedBlockIsNotCountedTwice() {
        Instant start = Instant.parse("2026-10-18T09:00:00Z");
        UUID material = UUID.randomUUID();
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "repaso", start, start.plusSeconds(1800), 3, null));
        ports.materialsWithCompletedBlock.add(material);
        // Pomodoro dentro del bloque completado y repaso SM-2 del material del bloque: ya están imputados.
        ports.focus.add(new PracticeSessions.Focus(UUID.randomUUID(), start.plusSeconds(1500), 25, 3, true));
        ports.reviews.add(new PracticeSessions.Review(UUID.randomUUID(), start.plusSeconds(1700), material, 3));
        // Pomodoro suelto y test: sí cuentan (25 + 20 min).
        ports.focus.add(new PracticeSessions.Focus(UUID.randomUUID(), start.plusSeconds(7200), 25, 3, false));
        ports.tests.add(new PracticeSessions.TestSession(UUID.randomUUID(), start.plusSeconds(9000),
                start.plusSeconds(10200), 3));

        var activity = service.getStudyActivity(USER, start.minusSeconds(3600), start.plusSeconds(86400));

        assertThat(activity).hasSize(3);
        assertThat(StudyActivity.minutes(activity)).isEqualTo(30 + 25 + 20);
        assertThat(service.getStudyCaloriesToday(USER, null).studyMinutes()).isEqualTo(75);
    }

    @Test
    void readingTheCognitiveStateRecomputesWithoutSaving() {
        service.initializeCognitiveState(USER);
        Instant t0 = Instant.parse("2026-10-18T09:00:00Z");
        ports.blocks.add(new CompletedStudyBlock(UUID.randomUUID(), "estudio", t0, t0.plusSeconds(3600), 3, null));

        CognitiveState read = service.getCognitiveState(USER, null);

        assertThat(read.cognitiveLoad()).isPositive();
        assertThat(ports.cognitiveSaves).isEqualTo(1); // solo el estado inicial
        assertThat(ports.cognitive.get(USER).cognitiveLoad()).isZero();
        service.refreshCognitiveState(new RefreshCognitiveStateUseCase.Command(USER, "estudio"));
        assertThat(ports.cognitive.get(USER).cognitiveLoad()).isEqualTo(read.cognitiveLoad());
    }

    @Test
    void aTestLeftOpenForHoursCountsAtMostOneHour() {
        Instant done = Instant.parse("2026-10-18T12:00:00Z");
        CompletedStudyBlock test = CompletedStudyBlock.test(UUID.randomUUID(), done.minusSeconds(5 * 3600), done, null);
        assertThat(test.durationMinutes()).isEqualTo(CompletedStudyBlock.MAX_TEST_MINUTES);
        assertThat(test.activityType()).isEqualTo("repaso");
    }
}
