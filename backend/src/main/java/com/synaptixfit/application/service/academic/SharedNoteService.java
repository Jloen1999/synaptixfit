package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.CopySharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetSharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.ListSharedNotesUseCase;
import com.synaptixfit.domain.model.academic.AcademicSearch;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.model.academic.AuthoredNote;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.academic.SharedNoteSummary;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import java.time.Clock;
import java.util.List;
import java.util.UUID;

/**
 * Apuntes compartidos por otros usuarios: listado de resúmenes, lectura de uno y copia privada.
 * La visibilidad la decide {@link EffectiveVisibility}; un apunte que no se puede ver se trata como
 * inexistente ({@code NOTE_NOT_FOUND}). Usa {@link NoteRepositoryPort} y {@link SubjectRepositoryPort}.
 */
public class SharedNoteService implements ListSharedNotesUseCase, GetSharedNoteUseCase, CopySharedNoteUseCase {

    private final NoteRepositoryPort notes;
    private final SubjectRepositoryPort subjects;
    private final Clock clock;

    public SharedNoteService(NoteRepositoryPort notes, SubjectRepositoryPort subjects, Clock clock) {
        this.notes = notes;
        this.subjects = subjects;
        this.clock = clock;
    }

    @Override
    public PageResult<SharedNoteSummary> listSharedNotes(Query q) {
        if (q.userId().equals(q.authorId())) {
            // Mi perfil público: lo mío que otros pueden llegar a ver (visibilidad efectiva no privada).
            return notes.findOwnShared(q.userId(), EffectiveVisibility.sharedLevels(), q.catalogSubjectId(), q.page());
        }
        AudienceScope scope = q.scope() == null ? AudienceScope.ALL : q.scope();
        String folded = q.search() == null || q.search().isBlank() ? null : AcademicSearch.fold(q.search().strip());
        return notes.findShared(q.userId(), new NoteRepositoryPort.SharedFilter(scope, q.authorId(),
                q.catalogSubjectId(), folded), q.page());
    }

    @Override
    public SharedNote getSharedNote(UUID userId, UUID noteId) {
        AuthoredNote found = notes.findAuthored(userId, noteId).orElseThrow(() -> new NoteNotFoundException(noteId));
        Note note = found.note();
        boolean own = note.userId().equals(userId);
        if (!own && !EffectiveVisibility.canView(note.visibility(), found.audience())) {
            throw new NoteNotFoundException(noteId);
        }
        return new SharedNote(note, found.authorName(), found.authorAvatarUrl(), found.catalogSubjectId(),
                found.catalogSubjectName(), EffectiveVisibility.of(note.visibility(), found.audience().authorPrivacy()));
    }

    @Override
    public Note copySharedNote(UUID userId, UUID noteId) {
        SharedNote source = getSharedNote(userId, noteId);
        Note original = source.note();
        // La copia es siempre privada y va a la asignatura del usuario que corresponde a la misma
        // asignatura del plan de estudios (si no la tiene o está archivada, queda sin asignatura).
        // Copiar un apunte propio se permite (es un duplicado privado); el cliente no lo ofrece.
        UUID subjectId = source.catalogSubjectId() == null ? null
                : subjects.findByUserAndCatalogIds(userId, List.of(source.catalogSubjectId())).stream()
                        .filter(s -> !s.archived())
                        .map(Subject::id)
                        .findFirst()
                        .orElse(null);
        return notes.save(Note.create(userId, subjectId, original.title(), original.content(), Visibility.PRIVATE,
                false, clock.instant()));
    }
}
