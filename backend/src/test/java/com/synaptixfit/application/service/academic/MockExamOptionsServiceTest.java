package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.MockExamOptions;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MockExamOptionsServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final MockExamOptionsService service = new MockExamOptionsService(f.subjects, f.materials, f.banks);
    private final UUID user = UUID.randomUUID();

    @Test
    void listsOnlyMaterialsWithQuestionsMostQuestionsFirstWithServerLimits() {
        Subject subject = f.subject(user, "Historia");
        StudyMaterial few = f.material(user, subject.id(), f.note(user, subject.id(), "Tema 1").id());
        StudyMaterial many = f.material(user, subject.id(), f.note(user, subject.id(), "Tema 2").id());
        StudyMaterial empty = f.material(user, subject.id(), f.note(user, subject.id(), "Tema 3").id());
        f.material(user, subject.id(), f.note(user, subject.id(), "Sin banco").id());
        withQuestions(few, 3);
        withQuestions(many, 8);
        withQuestions(empty, 0);

        MockExamOptions options = service.getMockExamOptions(user, subject.id());

        assertThat(options.sources()).extracting(MockExamOptions.Source::materialId)
                .containsExactly(many.id(), few.id());
        assertThat(options.sources().getFirst().questionCount()).isEqualTo(8);
        assertThat(options.maxMaterials()).isEqualTo(QuizService.MAX_MATERIALS);
        assertThat(options.suggestedQuestions()).isEqualTo(QuizService.COMBINED_TARGET);
        assertThat(options.maxQuestions()).isEqualTo(QuizService.MAX_QUESTION_COUNT);
    }

    @Test
    void someoneElsesSubjectDoesNotExist() {
        Subject subject = f.subject(user, "Historia");
        assertThatThrownBy(() -> service.getMockExamOptions(UUID.randomUUID(), subject.id()))
                .isInstanceOf(SubjectNotFoundException.class);
    }

    private void withQuestions(StudyMaterial material, int count) {
        QuestionBank bank = f.banks.save(QuestionBank.create(material.id(), user, AcademicFakes.NOW));
        List<Question> questions = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            questions.add(Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "P" + i, null, "R" + i, null),
                    bank.id(), i));
        }
        f.banks.replaceQuestions(bank.id(), questions);
    }
}
