package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.SaveCreatedQuestionsUseCase;
import com.synaptixfit.application.port.input.academic.ScanDocumentQuestionsUseCase;
import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.DocumentQuestionScan;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBankGeneration;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import java.time.Clock;
import java.util.List;
import java.util.UUID;

/**
 * «Crear preguntas» y lectura de las preguntas del documento (ADR 0058). Las llamadas a la IA (por tandas,
 * con reintento, {@link PracticeBankGenerator}, {@link DocumentQuestionScanner}) van sin transacción para no
 * retener una conexión de la base de datos durante minutos; el guardado es otro caso de uso, corto y
 * transaccional ({@link SaveCreatedQuestionsUseCase}), como la importación de la guía (ADR 0015).
 */
public class QuestionCreationService implements GenerateQuestionBankUseCase, ScanDocumentQuestionsUseCase {

    private final QuestionBankRepositoryPort banks;
    private final AcademicLookups lookups;
    private final PracticeBankGenerator generator;
    private final DocumentQuestionScanner scanner;
    private final SaveCreatedQuestionsUseCase save;
    private final GetQuestionBankUseCase getBank;

    public QuestionCreationService(QuestionBankRepositoryPort banks, StudyMaterialRepositoryPort materials,
                                   SubjectRepositoryPort subjects, NoteRepositoryPort notes,
                                   SubjectFileRepositoryPort files, AiDocumentRepositoryPort aiDocuments,
                                   StudyDocumentCodecPort codec, StudyAssistantPort assistant,
                                   FileStoragePort storage, SaveCreatedQuestionsUseCase save,
                                   GetQuestionBankUseCase getBank, Clock clock) {
        this.banks = banks;
        this.save = save;
        this.getBank = getBank;
        this.lookups = new AcademicLookups(subjects, notes, files, materials, storage, clock);
        this.generator = new PracticeBankGenerator(banks, aiDocuments, codec, assistant, clock);
        this.scanner = new DocumentQuestionScanner(assistant);
    }

    @Override
    public QuestionBankGeneration generateBank(GenerateQuestionBankUseCase.Command c) {
        StudyMaterial m = lookups.material(c.userId(), c.materialId());
        AcademicLookups.ResolvedSource source = lookups.resolve(c.userId(),
                new StudySourceRef(m.originType(), m.originId()));
        // Al añadir, la IA recibe los enunciados que ya hay para no repetirlos (el guardado vuelve a filtrar).
        List<String> existing = c.mode() != BankUpdateMode.ADD ? List.of()
                : banks.findByMaterial(m.id()).map(b -> banks.findQuestions(b.id()).stream()
                        .map(Question::statement).toList()).orElse(List.of());
        PracticeBankGenerator.Drafts drafts = generator.draft(c, source.source(), existing);
        int created = drafts.questions().isEmpty() ? 0 : save.saveCreatedQuestions(
                new SaveCreatedQuestionsUseCase.Command(c.userId(), m.id(), c.mode(), drafts.questions()));
        return new QuestionBankGeneration(getBank.getBank(c.userId(), m.id(), c.supportedTypes()),
                drafts.requested(), created);
    }

    @Override
    public DocumentQuestionScan scanDocumentQuestions(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        return scanner.scan(lookups.resolve(userId, new StudySourceRef(m.originType(), m.originId())).source());
    }
}
