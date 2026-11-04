package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.GetMockExamOptionsUseCase;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.MockExamOptions;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Implementa {@link GetMockExamOptionsUseCase}: lista los materiales de la asignatura con preguntas
 * y los límites de {@link QuizService} al empezar un simulacro. Una asignatura tiene pocos
 * materiales, así que leer el banco de cada uno es barato.
 */
public class MockExamOptionsService implements GetMockExamOptionsUseCase {

    private final SubjectRepositoryPort subjects;
    private final StudyMaterialRepositoryPort materials;
    private final QuestionBankRepositoryPort banks;

    public MockExamOptionsService(SubjectRepositoryPort subjects, StudyMaterialRepositoryPort materials,
                                  QuestionBankRepositoryPort banks) {
        this.subjects = subjects;
        this.materials = materials;
        this.banks = banks;
    }

    @Override
    public MockExamOptions getMockExamOptions(UUID userId, UUID subjectId) {
        subjects.findByIdAndUser(subjectId, userId).orElseThrow(() -> new SubjectNotFoundException(subjectId));
        List<MockExamOptions.Source> sources = new ArrayList<>();
        for (StudyMaterial m : materials.findByUser(userId, subjectId)) {
            banks.findByMaterial(m.id())
                    .map(bank -> banks.findQuestions(bank.id()).size())
                    .filter(count -> count > 0)
                    .ifPresent(count -> sources.add(
                            new MockExamOptions.Source(m.id(), m.title(), m.originType(), count)));
        }
        // Los que más preguntas tienen primero: suelen ser los temas más completos.
        sources.sort(Comparator.comparingInt(MockExamOptions.Source::questionCount).reversed()
                .thenComparing(MockExamOptions.Source::title, String.CASE_INSENSITIVE_ORDER));
        return new MockExamOptions(sources, QuizService.MAX_MATERIALS, QuizService.COMBINED_TARGET,
                QuizService.MAX_QUESTION_COUNT);
    }
}
