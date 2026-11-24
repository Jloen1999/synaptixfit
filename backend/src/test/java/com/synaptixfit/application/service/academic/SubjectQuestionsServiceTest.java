package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionStanding;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectQuestions;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Lista de todas las preguntas de una asignatura del apartado «Practicar» (ADR 0063). */
class SubjectQuestionsServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final SubjectQuestionsService service = new SubjectQuestionsService(f.subjects, f.materials, f.banks,
            f.attempts);
    private final UUID user = UUID.randomUUID();

    @Test
    void joinsEveryMaterialWithItsStandingAndTheOnesToReviewFirst() {
        Subject subject = f.subject(user, "Bases de datos");
        StudyMaterial sql = f.material(user, subject.id(), f.note(user, subject.id(), "SQL").id());
        StudyMaterial er = f.material(user, subject.id(), f.note(user, subject.id(), "Modelo E/R").id());
        f.material(user, subject.id(), f.note(user, subject.id(), "Sin preguntas").id());
        Question having = question(sql, QuestionType.MULTIPLE_CHOICE, "¿Qué filtra grupos?", 0);
        Question aggregates = question(sql, QuestionType.MULTIPLE_ANSWER, "¿Cuáles agregan?", 1);
        Question key = question(er, QuestionType.FILL_IN_BLANK, "Una clave ___", 0);
        f.attempts.save(QuestionAttempt.of(user, having.id(), true, AcademicFakes.NOW.minusSeconds(60)));
        f.attempts.save(QuestionAttempt.dontKnow(user, key.id(), AcademicFakes.NOW));
        // Los intentos de otra persona no cuentan.
        f.attempts.save(QuestionAttempt.dontKnow(UUID.randomUUID(), having.id(), AcademicFakes.NOW));

        SubjectQuestions list = service.listSubjectQuestions(user, subject.id(), QuestionType.ALL);

        assertThat(list.questions()).extracting(i -> i.question().id())
                .containsExactly(key.id(), aggregates.id(), having.id());
        assertThat(list.questions()).extracting(SubjectQuestions.Item::standing)
                .containsExactly(QuestionStanding.DONT_KNOW, QuestionStanding.NEW, QuestionStanding.CORRECT);
        assertThat(list.questions().getFirst().materialTitle()).isEqualTo(er.title());
        assertThat(list.questions().getFirst().lastAnsweredAt()).isEqualTo(AcademicFakes.NOW);
        assertThat(list.questions().get(1).lastAnsweredAt()).isNull();
        assertThat(list.toReview()).isEqualTo(1);
        assertThat(list.subjectName()).isEqualTo("Bases de datos");

        // Una app que no pinta «Varias correctas» no la recibe.
        assertThat(service.listSubjectQuestions(user, subject.id(), QuestionType.LEGACY).questions())
                .extracting(i -> i.question().id()).doesNotContain(aggregates.id());
    }

    @Test
    void someoneElsesSubjectDoesNotExist() {
        Subject subject = f.subject(user, "Historia");
        assertThatThrownBy(() -> service.listSubjectQuestions(UUID.randomUUID(), subject.id(), QuestionType.ALL))
                .isInstanceOf(SubjectNotFoundException.class);
    }

    private Question question(StudyMaterial material, QuestionType type, String statement, int order) {
        QuestionBank bank = f.banks.findByMaterial(material.id())
                .orElseGet(() -> f.banks.save(QuestionBank.create(material.id(), user, AcademicFakes.NOW)));
        QuestionDraft draft = switch (type) {
            case MULTIPLE_CHOICE -> new QuestionDraft(type, statement, List.of("WHERE", "HAVING"), "HAVING", null);
            case MULTIPLE_ANSWER -> QuestionDraft.multipleAnswer(statement, List.of("COUNT", "JOIN", "AVG"),
                    List.of("COUNT", "AVG"), null);
            case FILL_IN_BLANK -> new QuestionDraft(type, statement, null, "primaria", null);
        };
        Question q = Question.from(draft, bank.id(), order);
        f.banks.addQuestions(bank.id(), List.of(q));
        return q;
    }
}
