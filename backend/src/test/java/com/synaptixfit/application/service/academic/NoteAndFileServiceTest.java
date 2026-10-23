package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.ConfirmFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.CreateNoteUseCase;
import com.synaptixfit.application.port.input.academic.ListNotesUseCase;
import com.synaptixfit.application.port.input.academic.RequestFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.UpdateNoteUseCase;
import com.synaptixfit.domain.exception.academic.FileAlreadyRegisteredException;
import com.synaptixfit.domain.exception.academic.FileTooLargeException;
import com.synaptixfit.domain.exception.academic.FileTypeNotAllowedException;
import com.synaptixfit.domain.exception.academic.InvalidFileUploadException;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.exception.academic.SubjectFileNotFoundException;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.FileUploadTicket;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class NoteAndFileServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final NoteService notes = new NoteService(f.notes, f.subjects, f.materials, f.aiDocuments,
            AcademicFakes.CLOCK);
    private final SubjectFileService files = new SubjectFileService(f.files, f.subjects, f.materials, f.aiDocuments,
            f.storage, AcademicFakes.CLOCK);
    private final UUID user = UUID.randomUUID();
    private final UUID stranger = UUID.randomUUID();

    @Test
    void notesRequireOwnSubjectAndSupportFilters() {
        Subject s = f.subject(user, "Lengua");
        Subject foreign = f.subject(stranger, "Ajena");
        notes.createNote(new CreateNoteUseCase.Command(user, s.id(), "Sintaxis", "# Oración", null, false));
        notes.createNote(new CreateNoteUseCase.Command(user, null, "Idea", "comprar libro", Visibility.FRIENDS, true));

        assertThatThrownBy(() -> notes.createNote(new CreateNoteUseCase.Command(user, foreign.id(), "x", "", null,
                false))).isInstanceOf(SubjectNotFoundException.class);
        assertThat(notes.listNotes(new ListNotesUseCase.Query(user, null, true, false, new PageRequest(0, 20)))
                .items()).extracting(Note::title).containsExactly("Idea");
        assertThat(notes.listNotes(new ListNotesUseCase.Query(user, s.id(), false, false, new PageRequest(0, 20)))
                .totalItems()).isEqualTo(1);
        assertThat(notes.listNotes(new ListNotesUseCase.Query(user, null, false, true, new PageRequest(0, 20)))
                .items()).extracting(Note::visibility).containsExactly(Visibility.FRIENDS);
    }

    @Test
    void updateKeepsMaterialInSyncAndForeignNoteIsNotFound() {
        Subject s1 = f.subject(user, "Uno");
        Subject s2 = f.subject(user, "Dos");
        Note n = f.note(user, s1.id(), "Original");
        StudyMaterial m = f.material(user, s1.id(), n.id());

        Note updated = notes.updateNote(new UpdateNoteUseCase.Command(user, n.id(), "Renombrado", null, s2.id(),
                false, Visibility.PUBLIC, null));
        assertThat(updated.subjectId()).isEqualTo(s2.id());
        assertThat(updated.visibility()).isEqualTo(Visibility.PUBLIC);
        assertThat(f.materialStore.get(m.id()).title()).isEqualTo("Renombrado");
        assertThat(f.materialStore.get(m.id()).subjectId()).isEqualTo(s2.id());

        Note detached = notes.updateNote(new UpdateNoteUseCase.Command(user, n.id(), null, null, null, true, null,
                null));
        assertThat(detached.subjectId()).isNull();

        assertThatThrownBy(() -> notes.getNote(stranger, n.id()))
                .isInstanceOf(NoteNotFoundException.class)
                .hasFieldOrPropertyWithValue("code", "NOTE_NOT_FOUND");
    }

    @Test
    void deletingNoteRemovesMaterialAndAiDocuments() {
        Subject s = f.subject(user, "Arte");
        Note n = f.note(user, s.id(), "Barroco");
        f.material(user, s.id(), n.id());
        f.aiDocuments.save(AiDocument.create(user, s.id(), AiDocumentSource.NOTE, n.id().toString(),
                AiDocumentType.SUMMARY, "Barroco", "md", AcademicFakes.NOW));

        notes.deleteNote(user, n.id());

        assertThat(f.noteStore).isEmpty();
        assertThat(f.materialStore).isEmpty();
        assertThat(f.docStore).isEmpty();
    }

    @Test
    void uploadFlowValidatesTypeSizeAndKeyOwnership() {
        Subject s = f.subject(user, "Biología");
        FileUploadTicket ticket = files.requestUpload(new RequestFileUploadUseCase.Command(user, s.id(),
                "Tema 1 (célula).pdf", "application/pdf", 2048));
        assertThat(ticket.objectKey())
                .isEqualTo("usuarios/" + user + "/asignaturas/" + s.id() + "/archivos/"
                        + AcademicFakes.NOW.toEpochMilli() + "_Tema_1_c_lula_.pdf");
        assertThat(ticket.upload().method()).isEqualTo("PUT");

        assertThatThrownBy(() -> files.requestUpload(new RequestFileUploadUseCase.Command(user, s.id(), "x.exe",
                "application/x-msdownload", 10))).isInstanceOf(FileTypeNotAllowedException.class);
        assertThatThrownBy(() -> files.requestUpload(new RequestFileUploadUseCase.Command(user, s.id(), "big.pdf",
                "application/pdf", 26L * 1024 * 1024))).isInstanceOf(FileTooLargeException.class);
        assertThatThrownBy(() -> files.requestUpload(new RequestFileUploadUseCase.Command(stranger, s.id(), "a.pdf",
                "application/pdf", 10))).isInstanceOf(SubjectNotFoundException.class);

        SubjectFile saved = files.confirmUpload(new ConfirmFileUploadUseCase.Command(user, s.id(), ticket.objectKey(),
                "Tema 1 (célula).pdf", "application/pdf; charset=binary", 2048));
        assertThat(saved.mimeType()).isEqualTo("application/pdf");
        assertThat(saved.isAiReadable()).isTrue();

        assertThatThrownBy(() -> files.confirmUpload(new ConfirmFileUploadUseCase.Command(user, s.id(),
                ticket.objectKey(), "dup.pdf", "application/pdf", 10)))
                .isInstanceOf(FileAlreadyRegisteredException.class);
        String otherUsersKey = "usuarios/" + stranger + "/asignaturas/" + s.id() + "/archivos/1_a.pdf";
        assertThatThrownBy(() -> files.confirmUpload(new ConfirmFileUploadUseCase.Command(user, s.id(),
                otherUsersKey, "a.pdf", "application/pdf", 10))).isInstanceOf(InvalidFileUploadException.class);
    }

    @Test
    void downloadAndDeleteAreOwned() {
        Subject s = f.subject(user, "Geografía");
        SubjectFile file = f.file(user, s.id(), "mapa.png", "image/png");
        f.material(user, s.id(), UUID.randomUUID());
        f.materials.save(StudyMaterial.create(user, s.id(), StudySourceType.FILE, file.id(), "mapa", AcademicFakes.NOW));

        assertThat(files.downloadUrl(user, file.id()).method()).isEqualTo("GET");
        assertThatThrownBy(() -> files.downloadUrl(stranger, file.id()))
                .isInstanceOf(SubjectFileNotFoundException.class);

        files.deleteFile(user, file.id());
        assertThat(f.fileStore).isEmpty();
        assertThat(f.deletedObjects).containsExactly(file.objectKey());
        assertThat(f.materialStore.values()).noneMatch(m -> m.originType() == StudySourceType.FILE);
    }

    @Test
    void privatizingNotesHidesSharedOnesIdempotently() {
        Note shared = f.note(user, null, "Compartido");
        shared.changeVisibility(Visibility.FRIENDS);
        f.notes.save(shared);
        f.note(user, null, "Privado");
        Note foreign = f.note(UUID.randomUUID(), null, "Ajeno");
        foreign.changeVisibility(Visibility.PUBLIC);
        f.notes.save(foreign);

        assertThat(notes.privatizeAll(user)).isEqualTo(1);
        assertThat(notes.privatizeAll(user)).isZero();
        assertThat(f.notes.findNonPrivateByUser(user)).isEmpty();
        assertThat(f.notes.findNonPrivateByUser(foreign.userId())).hasSize(1);
    }
}
