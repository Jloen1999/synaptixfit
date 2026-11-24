package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.QuestionAlreadyAnsweredException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «No lo sé», orden en que vuelven las preguntas y entrega del simulacro (ADR 0063). */
class DontKnowTest {

    private static final Instant NOW = Instant.parse("2026-11-23T10:00:00Z");
    private static final UUID USER = UUID.randomUUID();

    @Test
    void noLoSeEsUnFalloDeLaNotaMasBaja() {
        QuestionAttempt a = QuestionAttempt.dontKnow(USER, UUID.randomUUID(), NOW);
        assertThat(a.correct()).isFalse();
        assertThat(a.dontKnow()).isTrue();
        // Aunque llegue marcado como acierto, un «No lo sé» nunca lo es.
        assertThat(new QuestionAttempt(UUID.randomUUID(), USER, UUID.randomUUID(), true, true, NOW).correct())
                .isFalse();
        assertThat(QuestionStanding.of(a)).isEqualTo(QuestionStanding.DONT_KNOW);
        assertThat(QuestionStanding.DONT_KNOW.recallQuality()).isZero();
        assertThat(QuestionStanding.WRONG.recallQuality()).isEqualTo(2);
        assertThat(QuestionStanding.CORRECT.recallQuality()).isEqualTo(4);
        assertThat(QuestionStanding.of(null)).isEqualTo(QuestionStanding.NEW);
    }

    @Test
    void vuelvenAntesNoLoSeLuegoFalladasNuevasYAcertadas() {
        List<QuestionStanding> sorted = List.of(QuestionStanding.CORRECT, QuestionStanding.NEW,
                QuestionStanding.WRONG, QuestionStanding.DONT_KNOW).stream()
                .sorted(QuestionStanding.COMES_BACK_FIRST).toList();
        assertThat(sorted).containsExactly(QuestionStanding.DONT_KNOW, QuestionStanding.WRONG, QuestionStanding.NEW,
                QuestionStanding.CORRECT);
        assertThat(QuestionStanding.DONT_KNOW.toReview()).isTrue();
        assertThat(QuestionStanding.WRONG.toReview()).isTrue();
        assertThat(QuestionStanding.NEW.toReview()).isFalse();
    }

    @Test
    void cuentaElUltimoIntentoDeCadaPregunta() {
        UUID q = UUID.randomUUID();
        Map<UUID, QuestionAttempt> latest = QuestionStanding.latest(List.of(
                QuestionAttempt.of(USER, q, true, NOW.minusSeconds(60)),
                QuestionAttempt.dontKnow(USER, q, NOW)));
        assertThat(QuestionStanding.of(latest.get(q))).isEqualTo(QuestionStanding.DONT_KNOW);
        // Acertarla después la saca del repaso.
        latest = QuestionStanding.latest(List.of(QuestionAttempt.dontKnow(USER, q, NOW.minusSeconds(60)),
                QuestionAttempt.of(USER, q, true, NOW)));
        assertThat(QuestionStanding.of(latest.get(q))).isEqualTo(QuestionStanding.CORRECT);
    }

    @Test
    void noLoSeBajaLaNotaPropuestaDelRepaso() {
        List<QuestionAttempt> attempts = List.of(
                QuestionAttempt.of(USER, UUID.randomUUID(), true, NOW.minusSeconds(60)),
                QuestionAttempt.dontKnow(USER, UUID.randomUUID(), NOW.minusSeconds(50)),
                QuestionAttempt.dontKnow(USER, UUID.randomUUID(), NOW.minusSeconds(40)));
        PracticeScore score = PracticeScore.from(attempts, null, NOW).orElseThrow();
        assertThat(score.correct()).isEqualTo(1);
        assertThat(score.answered()).isEqualTo(3);
        assertThat(score.suggestedQuality()).isEqualTo(1);
    }

    @Test
    void enLaSesionNoLoSeEsUnaRespuestaQueCuentaParaLaXp() {
        UUID q1 = UUID.randomUUID();
        UUID q2 = UUID.randomUUID();
        TestSession s = TestSession.start(USER, UUID.randomUUID(), List.of(q1, q2), NOW);
        assertThat(s.countsIfSubmitted()).isFalse();
        s.dontKnow(q1, null);
        assertThat(s.countsIfSubmitted()).isTrue();
        assertThat(s.currentIndex()).isEqualTo(1);
        s.answer(q2, "b", true, null);
        assertThat(s.complete(NOW)).isEmpty();
        assertThat(s.dontKnowIds()).containsExactly(q1);
        assertThat(s.score()).isEqualTo(1);
        assertThat(s.answeredCount()).isEqualTo(2);
        assertThat(s.claimXp()).isTrue();
    }

    @Test
    void loCorregidoNoSeCambia() {
        UUID q1 = UUID.randomUUID();
        UUID q2 = UUID.randomUUID();
        TestSession s = TestSession.start(USER, UUID.randomUUID(), List.of(q1, q2), NOW);
        s.dontKnow(q1, null);
        s.answer(q2, "b", false, null);
        assertThatThrownBy(() -> s.answer(q1, "a", true, null))
                .isInstanceOf(QuestionAlreadyAnsweredException.class);
        assertThatThrownBy(() -> s.answer(q2, "a", true, null))
                .isInstanceOf(QuestionAlreadyAnsweredException.class);
        assertThatThrownBy(() -> s.dontKnow(q2, null)).isInstanceOf(QuestionAlreadyAnsweredException.class);
        assertThat(s.dontKnowIds()).containsExactly(q1);
        assertThat(s.score()).isZero();
    }

    @Test
    void sinRespuestasSeAbandonaYNoSaleEnElHistorial() {
        TestSession empty = TestSession.start(USER, UUID.randomUUID(), List.of(UUID.randomUUID()), NOW);
        assertThat(empty.inHistory()).isTrue();
        empty.abandon(NOW);
        assertThat(empty.counted()).isFalse();
        assertThat(empty.inHistory()).isFalse();
        assertThatThrownBy(() -> empty.abandon(NOW)).isInstanceOf(TestSessionNotInProgressException.class);
    }

    @Test
    void alEntregarLoSinContestarPasaANoLoSePeroNoDaXp() {
        UUID q1 = UUID.randomUUID();
        UUID q2 = UUID.randomUUID();
        UUID q3 = UUID.randomUUID();
        TestSession s = TestSession.start(USER, UUID.randomUUID(), List.of(q1, q2, q3), NOW);
        s.answer(q1, "a", true, null);
        List<UUID> filled = s.complete(NOW);
        assertThat(filled).containsExactly(q2, q3);
        assertThat(s.unansweredAtSubmit()).containsExactlyInAnyOrder(q2, q3);
        assertThat(s.dontKnowIds()).containsExactlyInAnyOrder(q2, q3);
        assertThat(s.allAnswered()).isTrue();
        assertThat(s.answeredCount()).isEqualTo(1);
        assertThat(s.score()).isEqualTo(1);
        assertThat(s.canClaimXp()).isFalse();
    }

    @Test
    void laListaDeLaAsignaturaVaEnElOrdenEnQueVuelven() {
        UUID bank = UUID.randomUUID();
        Question a = Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "A", null, "a", null), bank, 0);
        Question b = Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "B", null, "b", null), bank, 1);
        Question c = Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "C", null, "c", null), bank, 2);
        UUID material = UUID.randomUUID();
        SubjectQuestions list = new SubjectQuestions(List.of(
                new SubjectQuestions.Item(a, material, "Tema 1", QuestionStanding.CORRECT, NOW),
                new SubjectQuestions.Item(b, material, "Tema 1", QuestionStanding.NEW, null),
                new SubjectQuestions.Item(c, material, "Tema 1", QuestionStanding.DONT_KNOW, NOW)));
        assertThat(list.questions()).extracting(i -> i.question().statement()).containsExactly("C", "B", "A");
        assertThat(list.toReview()).isEqualTo(1);
    }
}
