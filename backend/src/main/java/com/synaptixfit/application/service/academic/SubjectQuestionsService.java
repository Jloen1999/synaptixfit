package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ListSubjectQuestionsUseCase;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.model.academic.QuestionStanding;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectQuestions;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Implementa {@link ListSubjectQuestionsUseCase}: junta las preguntas de los bancos de todos los materiales de la
 * asignatura y les pone su estado con {@link QuestionStanding} según el último intento de la persona.
 */
public class SubjectQuestionsService implements ListSubjectQuestionsUseCase {

    private final SubjectRepositoryPort subjects;
    private final StudyMaterialRepositoryPort materials;
    private final QuestionBankRepositoryPort banks;
    private final QuestionAttemptRepositoryPort attempts;

    public SubjectQuestionsService(SubjectRepositoryPort subjects, StudyMaterialRepositoryPort materials,
                                   QuestionBankRepositoryPort banks, QuestionAttemptRepositoryPort attempts) {
        this.subjects = subjects;
        this.materials = materials;
        this.banks = banks;
        this.attempts = attempts;
    }

    @Override
    public SubjectQuestions listSubjectQuestions(UUID userId, UUID subjectId, Set<QuestionType> visibleTypes) {
        Subject subject = subjects.findByIdAndUser(subjectId, userId)
                .orElseThrow(() -> new SubjectNotFoundException(subjectId));
        record Sourced(Question question, StudyMaterial material) {
        }
        List<StudyMaterial> subjectMaterials = materials.findByUser(userId, subjectId);
        Map<UUID, List<Question>> byMaterial = banks.findQuestionsByMaterials(
                subjectMaterials.stream().map(StudyMaterial::id).toList());
        List<Sourced> found = new ArrayList<>();
        for (StudyMaterial m : subjectMaterials) {
            byMaterial.getOrDefault(m.id(), List.of()).stream().filter(q -> visibleTypes.contains(q.type()))
                    .forEach(q -> found.add(new Sourced(q, m)));
        }
        Map<UUID, QuestionAttempt> latest = QuestionStanding.latest(attempts.findByUserAndQuestions(userId,
                found.stream().map(s -> s.question().id()).toList()));
        return new SubjectQuestions(subject.name(), found.stream().map(s -> {
            QuestionAttempt last = latest.get(s.question().id());
            return new SubjectQuestions.Item(s.question(), s.material().id(), s.material().title(),
                    QuestionStanding.of(last), last == null ? null : last.answeredAt());
        }).toList());
    }
}
