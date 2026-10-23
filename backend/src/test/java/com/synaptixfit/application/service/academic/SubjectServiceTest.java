package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.UpdateSubjectUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.CatalogSubjectNotFoundException;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.CatalogSubject;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.SubjectPriority;
import com.synaptixfit.domain.model.academic.SubjectSummary;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SubjectServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final SubjectService service = new SubjectService(f.subjects, f.semesters, f.catalogPort, f.files,
            f.aiDocuments, f.storage, f.events::add, AcademicFakes.CLOCK);
    private final UUID user = UUID.randomUUID();
    private final UUID stranger = UUID.randomUUID();

    @Test
    void createsWithDefaultsAndValidatesInvariants() {
        Subject s = service.createSubject(new CreateSubjectUseCase.Command(user, "Cálculo", null, null, null, null,
                null, null, null, null));
        assertThat(s.credits()).isEqualTo(3);
        assertThat(s.perceivedDifficulty()).isEqualTo(3);
        assertThat(s.priority()).isEqualTo(SubjectPriority.MEDIUM);

        assertThatThrownBy(() -> service.createSubject(new CreateSubjectUseCase.Command(user, "C", null, null, null,
                null, null, null, null, null))).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.createSubject(new CreateSubjectUseCase.Command(user, "Física", null, null,
                31, null, null, null, null, null))).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.createSubject(new CreateSubjectUseCase.Command(user, "Física", null, null,
                null, 6, null, null, null, null))).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void listIncludesContentCountsAndFiltersArchived() {
        Subject s = f.subject(user, "Álgebra");
        f.note(user, s.id(), "Tema 1");
        f.note(user, s.id(), "Tema 2");
        f.file(user, s.id(), "a.pdf", "application/pdf");
        Subject archived = f.subject(user, "Historia");
        archived.archive();
        f.subjects.save(archived);

        List<SubjectSummary> active = service.listSubjects(user, false);
        assertThat(active).hasSize(1);
        assertThat(active.getFirst().noteCount()).isEqualTo(2);
        assertThat(active.getFirst().fileCount()).isEqualTo(1);
        assertThat(service.listSubjects(user, true)).extracting(x -> x.subject().name()).containsExactly("Historia");
    }

    @Test
    void updateIsPartialAndForeignSubjectIsNotFound() {
        Subject s = f.subject(user, "Redes");
        SubjectSummary updated = service.updateSubject(new UpdateSubjectUseCase.Command(user, s.id(), null, "RED",
                "", 6, null, SubjectPriority.HIGH, null, false, null, null, true));
        assertThat(updated.subject().code()).isEqualTo("RED");
        assertThat(updated.subject().credits()).isEqualTo(6);
        assertThat(updated.subject().priority()).isEqualTo(SubjectPriority.HIGH);
        assertThat(updated.subject().archived()).isTrue();
        assertThat(updated.subject().name()).isEqualTo("Redes");

        assertThatThrownBy(() -> service.getSubject(stranger, s.id()))
                .isInstanceOf(SubjectNotFoundException.class)
                .hasFieldOrPropertyWithValue("code", "SUBJECT_NOT_FOUND");
        assertThatThrownBy(() -> service.deleteSubject(stranger, s.id())).isInstanceOf(SubjectNotFoundException.class);
    }

    @Test
    void createFromCatalogReactivatesInsteadOfDuplicating() {
        CatalogSubject cs = new CatalogSubject(UUID.randomUUID(), UUID.randomUUID(), "Programación", 1, 1,
                "OBLIGATORIA", 6.0, 150, null, null);
        f.catalog.add(cs);

        Subject created = service.createFromCatalog(user, List.of(cs.id())).getFirst();
        assertThat(created.catalogSubjectId()).isEqualTo(cs.id());
        assertThat(created.credits()).isEqualTo(6);
        assertThat(created.description()).isEqualTo("Curso 1 · Sem 1 · OBLIGATORIA · 6.0 ECTS");

        created.archive();
        f.subjects.save(created);
        Subject again = service.createFromCatalog(user, List.of(cs.id(), cs.id())).getFirst();
        assertThat(again.id()).isEqualTo(created.id());
        assertThat(again.archived()).isFalse();
        assertThat(f.subjectStore).hasSize(1);
        assertThat(service.listCatalogSubjects(user).getFirst().selected()).isTrue();

        assertThatThrownBy(() -> service.createFromCatalog(user, List.of(UUID.randomUUID())))
                .isInstanceOf(CatalogSubjectNotFoundException.class);
    }

    @Test
    void semesterAssignmentIsUpsertAndOwned() {
        Subject s = f.subject(user, "Optativa");
        service.assignSemester(user, s.id(), 2, 1);
        service.assignSemester(user, s.id(), 3, 2);
        assertThat(service.listSemesters(user)).singleElement()
                .satisfies(a -> assertThat(a.course()).isEqualTo(3));
        assertThatThrownBy(() -> service.assignSemester(user, s.id(), 1, 3))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> service.assignSemester(stranger, s.id(), 1, 1))
                .isInstanceOf(SubjectNotFoundException.class);
    }

    @Test
    void deleteRemovesFilesObjectsDocumentsAndSemester() {
        Subject s = f.subject(user, "Química");
        SubjectFile file = f.file(user, s.id(), "lab.pdf", "application/pdf");
        f.aiDocuments.save(AiDocument.create(user, s.id(), AiDocumentSource.FILE, file.id().toString(),
                AiDocumentType.SUMMARY, "lab", "md", AcademicFakes.NOW));
        f.aiDocuments.save(AiDocument.create(user, s.id(), AiDocumentSource.SUBJECT, s.id().toString(),
                AiDocumentType.TEACHING_GUIDE, "Química", "x", AcademicFakes.NOW));
        service.assignSemester(user, s.id(), 1, 1);

        service.deleteSubject(user, s.id());

        assertThat(f.subjectStore).isEmpty();
        assertThat(f.fileStore).isEmpty();
        assertThat(f.docStore).isEmpty();
        assertThat(f.semesterStore).isEmpty();
        assertThat(f.deletedObjects).containsExactly(file.objectKey());
    }
}
