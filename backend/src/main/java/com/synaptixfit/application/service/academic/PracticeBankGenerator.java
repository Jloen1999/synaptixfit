package com.synaptixfit.application.service.academic;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Genera con IA el banco de preguntas de un material (sustituye las preguntas anteriores) y
 * guarda la marca de práctica en los documentos de IA de su fuente, para los iconos del cliente.
 */
final class PracticeBankGenerator {

    private final QuestionBankRepositoryPort banks;
    private final AiDocumentRepositoryPort aiDocuments;
    private final StudyDocumentCodecPort codec;
    private final StudyAssistantPort assistant;
    private final Clock clock;

    PracticeBankGenerator(QuestionBankRepositoryPort banks, AiDocumentRepositoryPort aiDocuments,
                          StudyDocumentCodecPort codec, StudyAssistantPort assistant, Clock clock) {
        this.banks = banks;
        this.aiDocuments = aiDocuments;
        this.codec = codec;
        this.assistant = assistant;
        this.clock = clock;
    }

    /** Devuelve la marca de práctica guardada. */
    AiDocument generate(UUID userId, StudyMaterial material, AcademicLookups.ResolvedSource source) {
        StudyAssistantPort.PracticeQuestions generated = assistant.practiceQuestions(List.of(source.source()));
        if (generated.questions().isEmpty()) {
            throw new AiUnavailableException("AI returned no questions");
        }
        QuestionBank bank = banks.findByMaterial(material.id())
                .map(b -> b.regenerated(clock.instant()))
                .orElseGet(() -> QuestionBank.create(material.id(), userId, clock.instant()));
        bank = banks.save(bank);
        List<Question> questions = new ArrayList<>();
        for (int i = 0; i < generated.questions().size(); i++) {
            questions.add(Question.from(generated.questions().get(i), bank.id(), i));
        }
        banks.replaceQuestions(bank.id(), questions);

        String content = codec.encodePractice(
                new StudyDocumentCodecPort.PracticeMarker(material.id(), bank.id(), questions.size()));
        AiDocumentSource docSource = AiDocumentSource.of(material.originType());
        String sourceId = material.originId().toString();
        AiDocument doc = aiDocuments.find(userId, docSource, sourceId, AiDocumentType.PRACTICE)
                .map(d -> d.withContent(content, source.title(), material.subjectId(), clock.instant()))
                .orElseGet(() -> AiDocument.create(userId, material.subjectId(), docSource, sourceId,
                        AiDocumentType.PRACTICE, source.title(), content, clock.instant()));
        return aiDocuments.save(doc);
    }
}
