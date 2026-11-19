package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Varias correctas» (todo o nada), tandas y enunciados repetidos (ADR 0058). */
class QuestionRulesTest {

    private static Question multiple() {
        QuestionDraft draft = QuestionDraft.multipleAnswer("¿Cuáles suman, cuentan o promedian?",
                List.of("COUNT", "SUM", "JOIN", "AVG"), List.of("avg", "COUNT", "Sum"), null);
        return Question.from(draft, UUID.randomUUID(), 0);
    }

    @Test
    void multipleAnswerCountsOnlyWithAllTheRightOnesAndNoWrongOne() {
        Question q = multiple();

        assertThat(q.correctAnswers()).containsExactly("COUNT", "SUM", "AVG");
        assertThat(q.isCorrect(Question.joinAnswers(List.of("AVG", "count", "SUM")))).isTrue();
        assertThat(q.isCorrect(Question.joinAnswers(List.of("COUNT", "SUM")))).isFalse();
        assertThat(q.isCorrect(Question.joinAnswers(List.of("COUNT", "SUM", "AVG", "JOIN")))).isFalse();
        assertThat(q.isCorrect("")).isFalse();
        assertThat(q.isCorrect(null)).isFalse();
    }

    @Test
    void multipleAnswerNeedsItsAnswersAmongTheOptions() {
        assertThatThrownBy(() -> QuestionDraft.multipleAnswer("¿Cuáles?", List.of("A", "B"), List.of("C"), null))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> QuestionDraft.multipleAnswer("¿Cuáles?", List.of("A", "B"), List.of(), null))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> QuestionDraft.multipleAnswer("¿Cuáles?", List.of("A"), List.of("A"), null))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void optionsNeverKeepLineBreaks() {
        QuestionDraft d = QuestionDraft.multipleAnswer("¿Cuáles?", List.of("una\nlínea", "B"), List.of("una línea"),
                null);
        assertThat(d.options()).containsExactly("una línea", "B");
        assertThat(d.correctAnswers()).containsExactly("una línea");
    }

    @Test
    void newQuestionsAreSplitInBatchesOfTenAndMixed() {
        List<QuestionBatch> plan = QuestionBatch.plan(QuestionFormat.MIXED, 25, true);

        assertThat(plan).extracting(QuestionBatch::total).containsExactly(10, 10, 5);
        assertThat(plan.getFirst().singleChoice()).isEqualTo(4);
        assertThat(plan.getFirst().fillInBlank()).isEqualTo(3);
        assertThat(plan.getFirst().multipleAnswer()).isEqualTo(3);
        assertThat(QuestionBatch.plan(QuestionFormat.MIXED, 10, false))
                .allSatisfy(b -> assertThat(b.multipleAnswer()).isZero());
        assertThat(QuestionBatch.plan(QuestionFormat.FLASHCARD, 5, true)).singleElement()
                .satisfies(b -> assertThat(b.flashcards()).isEqualTo(5));
        assertThat(QuestionBatch.plan(QuestionFormat.MIXED, 0, true)).isEmpty();
        assertThatThrownBy(() -> QuestionBatch.plan(QuestionFormat.MIXED, 31, true))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void repeatedStatementsAreDroppedIgnoringCaseAndAccents() {
        QuestionDraft a = new QuestionDraft(QuestionType.FILL_IN_BLANK, "¿Qué es una CLAVE?", null, "x", null);
        QuestionDraft b = new QuestionDraft(QuestionType.FILL_IN_BLANK, "¿Que es una clave?", null, "y", null);
        QuestionDraft c = new QuestionDraft(QuestionType.FILL_IN_BLANK, "Otra", null, "z", null);

        assertThat(QuestionDraft.withoutRepeats(List.of("otra"), List.of(a, b, c))).containsExactly(a);
    }

    @Test
    void documentQuestionsKeepWhyTheyCannotBeUsed() {
        assertThat(DocumentQuestion.of(null, "Explica…", null, List.of("algo"), true, null).status())
                .isEqualTo(DocumentQuestion.Status.LONG_ANSWER);
        assertThat(DocumentQuestion.of(QuestionType.MULTIPLE_CHOICE, "¿?", List.of("A", "B"), List.of("C"), true,
                null).status()).isEqualTo(DocumentQuestion.Status.NO_ANSWER);
        DocumentQuestion proposed = DocumentQuestion.of(QuestionType.MULTIPLE_ANSWER, "¿Cuáles?",
                List.of("A", "B", "C"), List.of("A", "C"), false, null);
        assertThat(proposed.status()).isEqualTo(DocumentQuestion.Status.ANSWER_PROPOSED);
        assertThat(proposed.toDraft().correctAnswers()).containsExactly("A", "C");
    }
}
