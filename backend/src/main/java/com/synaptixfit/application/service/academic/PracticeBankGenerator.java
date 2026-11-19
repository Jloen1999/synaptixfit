package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Crea con IA las preguntas del banco de un material y guarda la marca de práctica en los documentos de IA
 * de su fuente, para los iconos del cliente. «Crear preguntas» (ADR 0058) va en dos pasos: {@link #draft}
 * pide las nuevas por tandas ({@link QuestionBatch}) sin transacción y {@link #save} las guarda en una
 * transacción corta; el asistente de IA usa la versión de siempre ({@link #generate}).
 */
final class PracticeBankGenerator {

    /** Preguntas listas para guardar y cuántas se pidieron (las del documento más las nuevas). */
    record Drafts(List<QuestionDraft> questions, int requested) {
    }

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

    /** Banco de 10 preguntas en una llamada que sustituye al anterior (asistente de IA). Devuelve la marca. */
    AiDocument generate(UUID userId, StudyMaterial material, AcademicLookups.ResolvedSource source) {
        StudyAssistantPort.PracticeQuestions generated = assistant.practiceQuestions(List.of(source.source()));
        if (generated.questions().isEmpty()) {
            throw new AiUnavailableException("AI returned no questions");
        }
        QuestionBank bank = saveBank(userId, material);
        List<Question> questions = new ArrayList<>();
        for (int i = 0; i < generated.questions().size(); i++) {
            questions.add(Question.from(generated.questions().get(i), bank.id(), i));
        }
        banks.replaceQuestions(bank.id(), questions);
        return saveMarker(userId, material, source.title(), bank, questions.size());
    }

    /**
     * «Crear preguntas», fase de IA (sin transacción): las del documento ya revisadas más las nuevas, pedidas
     * por tandas y sin repetir los enunciados de {@code existing}. Si una tanda falla tras reintentarla se
     * devuelven las conseguidas; solo falla si no se consiguió ninguna y alguna tanda falló.
     */
    Drafts draft(GenerateQuestionBankUseCase.Command c, StudyAssistantPort.Source source, List<String> existing) {
        List<QuestionBatch> plan = QuestionBatch.plan(c.format(), c.newQuestions(),
                c.supportedTypes().contains(QuestionType.MULTIPLE_ANSWER));
        int requested = c.documentQuestions().size() + c.newQuestions();
        if (requested == 0) {
            throw new FieldValidationException("newQuestions", "OUT_OF_RANGE", "nothing to create");
        }
        List<String> known = new ArrayList<>(existing);
        List<QuestionDraft> fresh = new ArrayList<>(QuestionDraft.withoutRepeats(known, c.documentQuestions()));
        fresh.forEach(d -> known.add(d.statement()));
        for (QuestionBatch batch : plan) {
            List<QuestionDraft> got;
            try {
                got = AiBatches.withRetry(() -> assistant.practiceQuestions(List.of(source), batch,
                        List.copyOf(known)).questions());
            } catch (AiUnavailableException | AiQuotaExceededException e) {
                if (fresh.isEmpty()) {
                    throw e;
                }
                break;
            }
            List<QuestionDraft> unique = QuestionDraft.withoutRepeats(known, got).stream()
                    .filter(d -> c.supportedTypes().contains(d.type()))
                    .limit(batch.total()).toList();
            fresh.addAll(unique);
            unique.forEach(d -> known.add(d.statement()));
        }
        return new Drafts(fresh, requested);
    }

    /**
     * «Crear preguntas», guardado (en una transacción corta): con {@link BankUpdateMode#ADD} se añaden sin
     * repetir los enunciados que ya hay; con {@link BankUpdateMode#REPLACE} sustituyen a las de antes.
     * Devuelve cuántas se guardaron; si no queda ninguna nueva, no toca el banco.
     */
    int save(UUID userId, StudyMaterial material, String title, BankUpdateMode mode, List<QuestionDraft> drafts) {
        boolean add = mode == BankUpdateMode.ADD;
        Optional<QuestionBank> current = banks.findByMaterial(material.id());
        List<Question> existing = current.map(b -> banks.findQuestions(b.id())).orElse(List.of());
        List<QuestionDraft> toSave = add
                ? QuestionDraft.withoutRepeats(existing.stream().map(Question::statement).toList(), drafts)
                : QuestionDraft.withoutRepeats(List.of(), drafts);
        if (toSave.isEmpty()) {
            return 0;
        }
        QuestionBank bank = saveBank(userId, material);
        int start = add ? existing.stream().mapToInt(Question::order).max().orElse(-1) + 1 : 0;
        List<Question> questions = new ArrayList<>();
        for (int i = 0; i < toSave.size(); i++) {
            questions.add(Question.from(toSave.get(i), bank.id(), start + i));
        }
        if (add) {
            banks.addQuestions(bank.id(), questions);
        } else {
            banks.replaceQuestions(bank.id(), questions);
        }
        saveMarker(userId, material, title, bank, banks.countQuestions(bank.id()));
        return toSave.size();
    }

    private QuestionBank saveBank(UUID userId, StudyMaterial material) {
        QuestionBank bank = banks.findByMaterial(material.id())
                .map(b -> b.regenerated(clock.instant()))
                .orElseGet(() -> QuestionBank.create(material.id(), userId, clock.instant()));
        return banks.save(bank);
    }

    private AiDocument saveMarker(UUID userId, StudyMaterial material, String title, QuestionBank bank,
                                  int questionCount) {
        String content = codec.encodePractice(
                new StudyDocumentCodecPort.PracticeMarker(material.id(), bank.id(), questionCount));
        AiDocumentSource docSource = AiDocumentSource.of(material.originType());
        String sourceId = material.originId().toString();
        AiDocument doc = aiDocuments.find(userId, docSource, sourceId, AiDocumentType.PRACTICE)
                .map(d -> d.withContent(content, title, material.subjectId(), clock.instant()))
                .orElseGet(() -> AiDocument.create(userId, material.subjectId(), docSource, sourceId,
                        AiDocumentType.PRACTICE, title, content, clock.instant()));
        return aiDocuments.save(doc);
    }
}
