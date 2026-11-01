package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.CreateNoteUseCase;
import com.synaptixfit.application.port.input.academic.UpdateNoteUseCase;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.academic.SharedNoteSummary;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Lectura y copia de apuntes compartidos, y el límite de visibilidad que pone el perfil. */
class SharedNoteServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final SharedNoteService shared = new SharedNoteService(f.notes, f.subjects, AcademicFakes.CLOCK);
    private final NoteService notes = new NoteService(f.notes, f.subjects, f.materials, f.aiDocuments, f.users,
            AcademicFakes.CLOCK);
    private final UUID author = UUID.randomUUID();
    private final UUID reader = UUID.randomUUID();

    private Note publicNote() {
        return f.notes.save(Note.create(author, null, "Tema 1", "# Tema 1\nTexto", Visibility.PUBLIC, false,
                AcademicFakes.NOW));
    }

    @Test
    void aPublicNoteOfAFriendsOnlyProfileIsOnlyReadByFriends() {
        Note note = publicNote();
        f.audiences.put(author, new AuthorAudience(true, false, Visibility.FRIENDS, false, false));
        assertThatThrownBy(() -> shared.getSharedNote(reader, note.id())).isInstanceOf(NoteNotFoundException.class);

        f.audiences.put(author, new AuthorAudience(true, false, Visibility.FRIENDS, true, false));
        SharedNote read = shared.getSharedNote(reader, note.id());
        assertThat(read.note().content()).isEqualTo("# Tema 1\nTexto");
        assertThat(read.visibility()).isEqualTo(Visibility.FRIENDS);
    }

    @Test
    void aBlockOrAShadowbanHidesTheNoteAndTheOwnerAlwaysReadsIt() {
        Note note = publicNote();
        f.audiences.put(author, new AuthorAudience(true, false, Visibility.PUBLIC, true, true));
        assertThatThrownBy(() -> shared.getSharedNote(reader, note.id())).isInstanceOf(NoteNotFoundException.class);
        f.audiences.put(author, new AuthorAudience(true, true, Visibility.PUBLIC, false, false));
        assertThatThrownBy(() -> shared.getSharedNote(reader, note.id())).isInstanceOf(NoteNotFoundException.class);

        assertThat(shared.getSharedNote(author, note.id()).note().id()).isEqualTo(note.id());
    }

    @Test
    void theCopyIsPrivateAndGoesToTheEquivalentSubject() {
        Note note = publicNote();
        UUID catalog = UUID.randomUUID();
        f.authorCatalogSubject.put(note.id(), catalog);
        f.audiences.put(author, new AuthorAudience(true, false, Visibility.PUBLIC, false, false));
        Subject mine = f.subjects.save(Subject.builder().id(UUID.randomUUID()).userId(reader).name("Tema")
                .catalogSubjectId(catalog).createdAt(AcademicFakes.NOW).build());

        Note copy = shared.copySharedNote(reader, note.id());

        assertThat(copy.id()).isNotEqualTo(note.id());
        assertThat(copy.userId()).isEqualTo(reader);
        assertThat(copy.subjectId()).isEqualTo(mine.id());
        assertThat(copy.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(copy.content()).isEqualTo(note.content());
    }

    @Test
    void aNoteIsNeverSharedBeyondTheProfilePrivacy() {
        f.privacy.put(author, Visibility.FRIENDS);
        Note created = notes.createNote(new CreateNoteUseCase.Command(author, null, "Tema", "x", Visibility.PUBLIC,
                false));
        assertThat(created.visibility()).isEqualTo(Visibility.FRIENDS);

        f.privacy.put(author, Visibility.PRIVATE);
        Note updated = notes.updateNote(new UpdateNoteUseCase.Command(author, created.id(), null, null, null, false,
                Visibility.PUBLIC, null));
        assertThat(updated.visibility()).isEqualTo(Visibility.PRIVATE);
    }

    @Test
    void theExcerptIsPlainTextAndShort() {
        assertThat(SharedNoteSummary.excerptOf("# Título\n\n**Negrita** y [enlace](http://x)\n- punto"))
                .isEqualTo("Título Negrita y enlace punto");
        String excerpt = SharedNoteSummary.excerptOf("palabra ".repeat(100));
        assertThat(excerpt).endsWith("…");
        assertThat(excerpt.length()).isLessThanOrEqualTo(SharedNoteSummary.EXCERPT_LENGTH + 1);
    }
}
