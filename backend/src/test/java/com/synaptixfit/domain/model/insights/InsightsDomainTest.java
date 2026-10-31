package com.synaptixfit.domain.model.insights;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.exception.insights.InvalidTimeZoneException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas de dominio de los indicadores (ACWR corregido, carga cognitiva, energía, FCT). */
class InsightsDomainTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-18T10:00:00Z");

    @Test
    void acwrUsesDailyAveragesOfBothWindows() {
        // 300 AU/día durante 28 días: carga estable → ACWR 1.0, zona óptima, sin penalizar el estudio.
        CrossRegulationState steady = CrossRegulationState.compute(USER, 300 * 7, 300 * 28, null, NOW);
        assertThat(steady.acuteDailyLoad()).isEqualTo(300);
        assertThat(steady.chronicDailyLoad()).isEqualTo(300);
        assertThat(steady.acwr()).isEqualTo(1.0);
        assertThat(steady.zone()).isEqualTo(AcwrZone.OPTIMAL);
        assertThat(steady.maxStudyMinutes()).isEqualTo(90);
    }

    @Test
    void firstTrainingWeekHasNoBaselineSoNoAcwr() {
        // Toda la carga en los últimos 7 días: no hay línea base (días 8-28 a 0). Antes salía ACWR 4
        // (y 28 con el criterio heredado) y se avisaba de sobreentrenamiento a un usuario nuevo.
        CrossRegulationState state = CrossRegulationState.compute(USER, 2100, 2100, null, NOW);
        assertThat(state.acwr()).isNull();
        assertThat(state.zone()).isEqualTo(AcwrZone.NO_DATA);
        assertThat(state.maxStudyMinutes()).isEqualTo(90);
    }

    @Test
    void spikeOverAnExistingBaselineIsOvertraining() {
        // 2100 en 7 días y 2100 más antes: media 7d = 300, media 28d = 4200/28 = 150 → ACWR 2.
        CrossRegulationState state = CrossRegulationState.compute(USER, 2100, 4200, null, NOW);
        assertThat(state.acwr()).isEqualTo(2.0);
        assertThat(state.zone()).isEqualTo(AcwrZone.OVERTRAINING);
    }

    @Test
    void aSingleOldSessionIsNotABaseline() {
        LocalDate today = LocalDate.of(2026, 10, 18);
        // Una sesión hace 9 días y tres esta semana: antes daba ACWR ~3 y avisaba de sobreentrenamiento.
        List<PhysicalLoadHistory.Entry> sparse = List.of(
                new PhysicalLoadHistory.Entry(today.minusDays(9), 7, 60),
                new PhysicalLoadHistory.Entry(today.minusDays(4), 8, 60),
                new PhysicalLoadHistory.Entry(today.minusDays(2), 8, 60),
                new PhysicalLoadHistory.Entry(today, 8, 60));
        CrossRegulationState state = CrossRegulationState.compute(USER, sparse, today, null, NOW);
        assertThat(state.acwr()).isNull();
        assertThat(state.zone()).isEqualTo(AcwrZone.NO_DATA);

        // Con carga en dos de las tres semanas anteriores ya hay línea base y el pico sí cuenta.
        List<PhysicalLoadHistory.Entry> withBaseline = new java.util.ArrayList<>(sparse);
        withBaseline.add(new PhysicalLoadHistory.Entry(today.minusDays(16), 7, 60));
        CrossRegulationState spike = CrossRegulationState.compute(USER, withBaseline, today, null, NOW);
        assertThat(spike.acwr()).isNotNull();
        assertThat(spike.zone()).isEqualTo(AcwrZone.OVERTRAINING);
    }

    @Test
    void acwrIsNullWithoutChronicLoad() {
        CrossRegulationState empty = CrossRegulationState.compute(USER, 0, 0, null, NOW);
        assertThat(empty.acwr()).isNull();
        assertThat(empty.zone()).isEqualTo(AcwrZone.NO_DATA);
        assertThat(empty.maxStudyMinutes()).isEqualTo(90);
        assertThat(empty.recommendedVolumeFactor(1.0)).isEqualTo(1.0);
    }

    @Test
    void zonesFollowGabbettThresholds() {
        assertThat(AcwrZone.of(0.5)).isEqualTo(AcwrZone.UNDERTRAINING);
        assertThat(AcwrZone.of(1.3)).isEqualTo(AcwrZone.OPTIMAL);
        assertThat(AcwrZone.of(1.4)).isEqualTo(AcwrZone.DANGER);
        assertThat(AcwrZone.of(1.6)).isEqualTo(AcwrZone.OVERTRAINING);
    }

    @Test
    void volumeFactorPenalisesOnlyWithAnUpcomingExam() {
        CrossRegulationState examTomorrow = CrossRegulationState.compute(USER, 0, 0, 1, NOW);
        assertThat(examTomorrow.recommendedVolumeFactor(1.0)).isCloseTo(1 - 0.4 * Math.exp(-0.15), within(1e-9));
        CrossRegulationState farExam = CrossRegulationState.compute(USER, 0, 0, 90, NOW);
        assertThat(farExam.recommendedVolumeFactor(1.0)).isEqualTo(1.0);
    }

    @Test
    void physicalLoadNormalisesMissingRpeAndDuration() {
        PhysicalLoadRecord r = PhysicalLoadRecord.forSession(USER, UUID.randomUUID(), LocalDate.of(2026, 10, 18), 0, 0, NOW);
        assertThat(r.rpe()).isEqualTo(5);
        assertThat(r.durationMinutes()).isEqualTo(1);
        assertThat(r.load()).isEqualTo(5);
        assertThat(r.update(r.date(), 5, 1)).isFalse();
        assertThat(r.update(r.date(), 8, 60)).isTrue();
        assertThat(r.load()).isEqualTo(480);
    }

    @Test
    void cognitiveStateIsRecomputedFromTodaysBlocks() {
        CognitiveState state = CognitiveState.initial(USER, NOW);
        Instant t0 = Instant.parse("2026-10-18T08:00:00Z");
        CompletedStudyBlock first = block("estudio", t0, 60, 5);
        CompletedStudyBlock second = block("clase", t0.plusSeconds(60 * 60), 30, null);   // sin pausa
        CompletedStudyBlock sport = block("deporte", t0.plusSeconds(3 * 3600), 60, null); // se ignora

        state.recompute(List.of(second, sport, first), 1600.0, NOW);

        // Fórmula 2 v2: 60 × 1,8 + 30 × 1,0 = 138 min equivalentes sin descanso; τ = 240/ln 5.
        double expected = 1 - Math.exp(-138 / (240 / Math.log(5)));
        assertThat(state.cognitiveLoad()).isCloseTo(expected, within(1e-9));
        // 90 min seguidos: la atención baja a la mitad cada 52 min.
        assertThat(state.attentionCapacity()).isCloseTo(Math.exp(-Math.log(2) / 52 * 90), within(1e-9));
        assertThat(state.lastBlockMinutes()).isEqualTo(30);
        assertThat(state.lastRestAt()).isEqualTo(t0);
        assertThat(state.rmrBase()).isEqualTo(1600.0);

        // Desmarcar todo: el estado vuelve a cero sin deriva.
        state.recompute(List.of(), null, NOW);
        assertThat(state.cognitiveLoad()).isZero();
        assertThat(state.attentionCapacity()).isEqualTo(1.0);
        assertThat(state.rmrBase()).isEqualTo(1600.0);
    }

    @Test
    void aBreakOfSeventeenMinutesOrMoreStartsANewStreak() {
        CognitiveState state = CognitiveState.initial(USER, NOW);
        Instant t0 = Instant.parse("2026-10-18T08:00:00Z");
        Instant afterBreak = t0.plusSeconds(5 * 60 + 20 * 60);
        state.recompute(List.of(block("estudio", t0, 5, 3), block("repaso", afterBreak, 5, 1)), null, NOW);
        // El primer bloque (5 × 1,3) se recupera durante 20 min (semivida 90 min) y se suma el segundo.
        double effort = 5 * 1.3 * Math.exp(-Math.log(2) / 90 * 20) + 5 * 1.0;
        assertThat(state.cognitiveLoad()).isCloseTo(1 - Math.exp(-effort / (240 / Math.log(5))), within(1e-9));
        assertThat(state.attentionCapacity()).isCloseTo(Math.exp(-Math.log(2) / 52 * 5), within(1e-9));
        assertThat(state.lastRestAt()).isEqualTo(afterBreak);
    }

    @Test
    void studyCaloriesPreferStoredValueAndOtherwiseUseRmr() {
        Instant t0 = Instant.parse("2026-10-18T08:00:00Z");
        CompletedStudyBlock stored = new CompletedStudyBlock(UUID.randomUUID(), "estudio", t0, t0.plusSeconds(3600), 3, 12.5);
        CompletedStudyBlock computed = block("clase", t0.plusSeconds(7200), 60, null);
        StudyCaloriesSummary summary = StudyCaloriesSummary.of(LocalDate.of(2026, 10, 18), List.of(stored, computed), 1728.0);
        // 1728 kcal/día = 0.02 kcal/s → 3600 s · 1.8 MET · 0.02 = 129.6
        assertThat(summary.totalCalories()).isCloseTo(12.5 + 129.6, within(1e-9));
        assertThat(summary.completedBlocks()).isEqualTo(2);
        assertThat(summary.studyMinutes()).isEqualTo(120);
    }

    @Test
    void energyScoreAppliesGatesAndFixedRecovery() {
        DailyCheckIn great = new DailyCheckIn(LocalDate.of(2026, 10, 18), 5, 1, 5, 1, true);
        EnergyScore best = EnergyScore.compute(great, null);
        assertThat(best.recovery()).isEqualTo(100);
        // 0.30·100 + 0.25·100 + 0.20·100 + 0.15·50 + 0.10·50
        assertThat(best.score()).isCloseTo(87.5, within(1e-9));

        DailyCheckIn bad = new DailyCheckIn(LocalDate.of(2026, 10, 18), 1, 5, 1, 5, false);
        EnergyScore worst = EnergyScore.compute(bad, null);
        assertThat(worst.sleepGate()).isEqualTo(0.40);
        assertThat(worst.sorenessGate()).isEqualTo(0.60);
        assertThat(worst.energyGate()).isEqualTo(0.50);
        assertThat(worst.score()).isLessThan(5);
        assertThat(bad.fatigueScore()).isEqualTo(25 + 20 + 20 + 28);
    }

    @Test
    void totalLoadFactorAndAdherence() {
        WeeklyAcademicLoad week = new WeeklyAcademicLoad(LocalDate.of(2026, 10, 12), 20, 30, 5, 2, 10, 4);
        TotalLoadFactor fct = TotalLoadFactor.compute(week, null);
        assertThat(fct.value()).isCloseTo(0.25 + 0.25 + 0.15 + 0.15 * 0.5, within(1e-9));
        assertThat(fct.level()).isEqualTo(TotalLoadFactor.LoadLevel.HIGH);

        AcademicAdherence adherence = AcademicAdherence.compute(week, 4, 1, 7);
        assertThat(adherence.score()).isCloseTo(60 + 7.5 + 10, within(1e-9));
        AcademicAdherence neutral = AcademicAdherence.compute(
                new WeeklyAcademicLoad(LocalDate.of(2026, 10, 12), 0, 0, 0, 0, 5, 7), 0, 0, 0);
        assertThat(neutral.score()).isEqualTo(45);
    }

    @Test
    void invalidTimeZoneIsRejected() {
        assertThat(TimeZones.resolve(null, ZoneId.of("UTC"))).isEqualTo(ZoneId.of("UTC"));
        assertThat(TimeZones.resolve("Europe/Madrid", ZoneId.of("UTC"))).isEqualTo(ZoneId.of("Europe/Madrid"));
        assertThatThrownBy(() -> TimeZones.resolve("Mars/Olympus", ZoneId.of("UTC")))
                .isInstanceOf(InvalidTimeZoneException.class)
                .extracting("code").isEqualTo("INSIGHTS_INVALID_TIME_ZONE");
    }

    private static CompletedStudyBlock block(String type, Instant start, int minutes, Integer difficulty) {
        return new CompletedStudyBlock(UUID.randomUUID(), type, start, start.plusSeconds(minutes * 60L), difficulty, null);
    }
}
