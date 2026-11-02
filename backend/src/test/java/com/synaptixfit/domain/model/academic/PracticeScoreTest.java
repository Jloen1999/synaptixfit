package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Nota propuesta en el repaso espaciado a partir de la práctica reciente. */
class PracticeScoreTest {

    private static final Instant NOW = Instant.parse("2026-11-02T18:00:00Z");
    private static final UUID USER = UUID.randomUUID();

    private static List<QuestionAttempt> answers(int correct, int wrong, Instant at) {
        List<QuestionAttempt> list = new ArrayList<>();
        for (int i = 0; i < correct + wrong; i++) {
            list.add(new QuestionAttempt(UUID.randomUUID(), USER, UUID.randomUUID(), i < correct, at));
        }
        return list;
    }

    @Test
    void sieteDeDiezProponeBienConEsfuerzo() {
        PracticeScore s = PracticeScore.from(answers(7, 3, NOW.minusSeconds(600)), null, NOW).orElseThrow();
        assertThat(s.correct()).isEqualTo(7);
        assertThat(s.answered()).isEqualTo(10);
        assertThat(s.suggestedQuality()).isEqualTo(3);
    }

    @Test
    void escalaDeAciertosANotaSm2() {
        assertThat(PracticeScore.qualityFor(1.0)).isEqualTo(5);
        assertThat(PracticeScore.qualityFor(0.8)).isEqualTo(4);
        assertThat(PracticeScore.qualityFor(0.6)).isEqualTo(3);
        assertThat(PracticeScore.qualityFor(0.5)).isEqualTo(2);
        assertThat(PracticeScore.qualityFor(0.2)).isEqualTo(1);
        assertThat(PracticeScore.qualityFor(0.0)).isZero();
    }

    @Test
    void cuentaSoloLaUltimaRespuestaDeCadaPregunta() {
        UUID q = UUID.randomUUID();
        List<QuestionAttempt> list = new ArrayList<>(answers(2, 0, NOW.minusSeconds(900)));
        list.add(new QuestionAttempt(UUID.randomUUID(), USER, q, false, NOW.minusSeconds(800)));
        list.add(new QuestionAttempt(UUID.randomUUID(), USER, q, true, NOW.minusSeconds(700)));
        PracticeScore s = PracticeScore.from(list, null, NOW).orElseThrow();
        assertThat(s.answered()).isEqualTo(3);
        assertThat(s.correct()).isEqualTo(3);
    }

    @Test
    void sinPracticaRecienteOConPocasPreguntasNoSeProponeNada() {
        assertThat(PracticeScore.from(answers(5, 0, NOW.minus(Duration.ofHours(7))), null, NOW)).isEmpty();
        assertThat(PracticeScore.from(answers(2, 0, NOW.minusSeconds(60)), null, NOW)).isEmpty();
    }

    @Test
    void loPracticadoAntesDelUltimoRepasoYaSeValoro() {
        Instant reviewed = NOW.minusSeconds(1800);
        assertThat(PracticeScore.from(answers(5, 0, NOW.minusSeconds(3600)), reviewed, NOW)).isEmpty();
        assertThat(PracticeScore.from(answers(5, 0, NOW.minusSeconds(600)), reviewed, NOW)).isPresent();
    }
}
