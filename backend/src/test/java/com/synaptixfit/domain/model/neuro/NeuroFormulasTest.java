package com.synaptixfit.domain.model.neuro;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import java.util.List;
import org.junit.jupiter.api.Test;

class NeuroFormulasTest {

    @Test
    void rmrUsesSexConstant() {
        assertThat(StudyEnergy.restingMetabolicRate(70, 175, 22, BiologicalSex.MALE)).isCloseTo(1688.75, within(0.01));
        assertThat(StudyEnergy.restingMetabolicRate(70, 175, 22, BiologicalSex.FEMALE)).isCloseTo(1522.75, within(0.01));
    }

    @Test
    void studyBlockCalories() {
        // 1 hora de clase con RMR 1728: 1728/86400 * 3600 * 1.8 = 129.6
        assertThat(StudyEnergy.blockCalories(1728, 3600, StudyEnergy.cognitiveMet("clase"))).isCloseTo(129.6, within(0.001));
        assertThat(StudyEnergy.cognitiveMet("estudio")).isEqualTo(1.3);
    }

    @Test
    void oneFocusBlockIsALowLoadNotACriticalOne() {
        // Un Pomodoro de 25 min (dificultad normal): ~0,15, lejos del 0,92 de la versión anterior.
        assertThat(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(25, 1.0, 0)))).isCloseTo(0.154, within(0.005));
    }

    @Test
    void fourHoursOfDemandingStudyReachTheCriticalThreshold() {
        // 4 h seguidas: el máximo sostenible de práctica deliberada (Ericsson et al., 1993) = 0,8.
        assertThat(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(240, 1.0, 0)))).isCloseTo(0.8, within(1e-9));
        // Satura sin llegar a 1: 8 h siguen por debajo.
        assertThat(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(480, 1.0, 0)))).isLessThan(1.0).isGreaterThan(0.95);
    }

    @Test
    void restRecoversPreviousLoadAndDifficultyAddsLoad() {
        double together = CognitiveLoad.accumulated(List.of(new StudyBlockLoad(60, 1.0, 0), new StudyBlockLoad(60, 1.0, 0)));
        double withBreak = CognitiveLoad.accumulated(List.of(new StudyBlockLoad(60, 1.0, 0), new StudyBlockLoad(60, 1.0, 90)));
        // 90 min de descanso reducen a la mitad el esfuerzo del primer bloque: 30 + 60 = 90 min equivalentes.
        assertThat(withBreak).isLessThan(together)
                .isCloseTo(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(90, 1.0, 0))), within(1e-9));
        assertThat(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(60, 1.8, 0))))
                .isGreaterThan(CognitiveLoad.accumulated(List.of(new StudyBlockLoad(60, 1.0, 0))));
    }

    @Test
    void attentionHalvesAfter52MinutesOfContinuousWork() {
        assertThat(CognitiveLoad.attentionCapacity(1.0, 52)).isCloseTo(0.5, within(1e-9));
        assertThat(CognitiveLoad.attentionCapacity(1.0, 0)).isEqualTo(1.0);
    }

    @Test
    void maxStudyMinutesFollowsAcwrBands() {
        assertThat(CrossRegulation.maxStudyMinutes(90, 1.0)).isEqualTo(90);
        assertThat(CrossRegulation.maxStudyMinutes(90, 1.6)).isLessThan(90).isGreaterThan(45);
        assertThat(CrossRegulation.maxStudyMinutes(90, 3.0)).isEqualTo(45);
        assertThat(CrossRegulation.maxStudyMinutes(40, 3.0)).isEqualTo(25);
    }

    @Test
    void acwrComparesDailyAverages() {
        // Carga constante de 300 UA/día: ACWR = 1.0
        assertThat(CrossRegulation.acwr(300 * 7, 300 * 28)).isCloseTo(1.0, within(1e-9));
        assertThat(CrossRegulation.acwr(100, 0)).isNull();
    }

    @Test
    void modifiedVolumeNoPenaltyFarFromExam() {
        assertThat(CrossRegulation.modifiedVolume(1.0, 1.0, 1.0, 90)).isEqualTo(1.0);
        assertThat(CrossRegulation.modifiedVolume(1.0, 1.0, 1.0, 0)).isCloseTo(0.6, within(1e-9));
    }

    @Test
    void fatigueAdjustmentIsBoundedAndNotRounded() {
        assertThat(FatigueAdjustedRecall.adjustedQuality(2, 500, 1000)).isCloseTo(2.25, within(1e-9));
        assertThat(FatigueAdjustedRecall.adjustedQuality(5, 1000, 1000)).isEqualTo(5.0);
        assertThat(FatigueAdjustedRecall.adjustedQuality(3, 100, 0)).isEqualTo(3.0);
    }

    @Test
    void exerciseCaloriesFallbackWeight() {
        assertThat(ExerciseEnergy.calories(6.0, null, 3600)).isCloseTo(420.0, within(1e-9));
        assertThat(ExerciseEnergy.deriveMet(null, "aerobica", false)).isEqualTo(8.3);
    }
}
