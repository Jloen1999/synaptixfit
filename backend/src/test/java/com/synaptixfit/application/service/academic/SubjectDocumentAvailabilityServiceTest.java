package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.GetSubjectDocumentAvailabilityUseCase.SourceDocuments;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Los documentos de IA de toda la lista «Material» de una vez (ADR 0064). */
class SubjectDocumentAvailabilityServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final SubjectDocumentAvailabilityService service = new SubjectDocumentAvailabilityService(f.subjects,
            f.notes, f.files, f.aiDocuments);
    private final UUID user = UUID.randomUUID();

    private void doc(UUID subjectId, AiDocumentSource source, UUID id, AiDocumentType type) {
        f.aiDocuments.save(AiDocument.create(user, subjectId, source, id.toString(), type, "t", "c",
                AcademicFakes.NOW));
    }

    @Test
    void eachNoteAndReadableFileWithDocumentsComesOnceWithItsTypes() {
        Subject s = f.subject(user, "Bases de datos");
        Note withDocs = f.note(user, s.id(), "SQL");
        f.note(user, s.id(), "Sin documentos");
        SubjectFile pdf = f.file(user, s.id(), "tema.pdf", "application/pdf");
        Note elsewhere = f.note(user, f.subject(user, "Otra").id(), "Otra");
        doc(s.id(), AiDocumentSource.NOTE, withDocs.id(), AiDocumentType.SUMMARY);
        doc(s.id(), AiDocumentSource.NOTE, withDocs.id(), AiDocumentType.PRACTICE);
        doc(s.id(), AiDocumentSource.FILE, pdf.id(), AiDocumentType.MIND_MAP);
        doc(s.id(), AiDocumentSource.NOTE, elsewhere.id(), AiDocumentType.SUMMARY);

        List<SourceDocuments> found = service.availableDocuments(user, s.id());

        assertThat(found).containsExactlyInAnyOrder(
                new SourceDocuments(StudySourceType.NOTE, withDocs.id(),
                        Set.of(AiDocumentType.SUMMARY, AiDocumentType.PRACTICE)),
                new SourceDocuments(StudySourceType.FILE, pdf.id(), Set.of(AiDocumentType.MIND_MAP)));
    }

    @Test
    void someoneElsesSubjectDoesNotExist() {
        Subject s = f.subject(user, "Bases de datos");
        assertThatThrownBy(() -> service.availableDocuments(UUID.randomUUID(), s.id()))
                .isInstanceOf(SubjectNotFoundException.class);
    }
}
