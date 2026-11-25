package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.GetSubjectDocumentAvailabilityUseCase;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Implementa {@link GetSubjectDocumentAvailabilityUseCase} (ADR 0064): los documentos de IA de los apuntes y archivos
 * de una asignatura con dos consultas a {@link AiDocumentRepositoryPort} en vez de una por elemento.
 */
public class SubjectDocumentAvailabilityService implements GetSubjectDocumentAvailabilityUseCase {

    /** Las mismas páginas que recorre el cliente al leer los apuntes de una asignatura. */
    static final int MAX_PAGES = 10;

    private final SubjectRepositoryPort subjects;
    private final NoteRepositoryPort notes;
    private final SubjectFileRepositoryPort files;
    private final AiDocumentRepositoryPort aiDocuments;

    public SubjectDocumentAvailabilityService(SubjectRepositoryPort subjects, NoteRepositoryPort notes,
                                              SubjectFileRepositoryPort files, AiDocumentRepositoryPort aiDocuments) {
        this.subjects = subjects;
        this.notes = notes;
        this.files = files;
        this.aiDocuments = aiDocuments;
    }

    @Override
    public List<SourceDocuments> availableDocuments(UUID userId, UUID subjectId) {
        subjects.findByIdAndUser(subjectId, userId).orElseThrow(() -> new SubjectNotFoundException(subjectId));
        List<String> noteIds = noteIds(userId, subjectId);
        // Solo los archivos que la IA puede leer pueden tener documentos.
        List<String> fileIds = files.findBySubject(userId, subjectId).stream()
                .filter(SubjectFile::isAiReadable).map(SubjectFile::id).map(UUID::toString).toList();
        List<SourceDocuments> result = new ArrayList<>();
        collect(result, StudySourceType.NOTE, aiDocuments.typesForAll(userId, AiDocumentSource.NOTE, noteIds));
        collect(result, StudySourceType.FILE, aiDocuments.typesForAll(userId, AiDocumentSource.FILE, fileIds));
        return result;
    }

    /** Los apuntes de la asignatura, página a página como los lee el cliente (como mucho {@link #MAX_PAGES}). */
    private List<String> noteIds(UUID userId, UUID subjectId) {
        List<String> ids = new ArrayList<>();
        NoteRepositoryPort.Filter filter = new NoteRepositoryPort.Filter(subjectId, false, false);
        for (int page = 0; page < MAX_PAGES; page++) {
            List<Note> items = notes.findByUser(userId, filter, new PageRequest(page, PageRequest.MAX_SIZE)).items();
            items.forEach(n -> ids.add(n.id().toString()));
            if (items.size() < PageRequest.MAX_SIZE) {
                break;
            }
        }
        return ids;
    }

    private static void collect(List<SourceDocuments> into, StudySourceType type,
                                Map<String, Set<AiDocumentType>> found) {
        found.forEach((id, types) -> {
            if (!types.isEmpty()) {
                into.add(new SourceDocuments(type, UUID.fromString(id), Set.copyOf(types)));
            }
        });
    }
}
