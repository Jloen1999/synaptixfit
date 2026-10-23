package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.CreateNoteUseCase;
import com.synaptixfit.application.port.input.academic.DeleteNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetNoteUseCase;
import com.synaptixfit.application.port.input.academic.ListNotesUseCase;
import com.synaptixfit.application.port.input.academic.ListSharedNotesUseCase;
import com.synaptixfit.application.port.input.academic.PrivatizeUserNotesUseCase;
import com.synaptixfit.application.port.input.academic.UpdateNoteUseCase;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import java.time.Clock;
import java.util.UUID;

/**
 * Apuntes en Markdown: CRUD propio, apuntes compartidos por otros usuarios y paso a privado de
 * todos los apuntes cuando el perfil se hace privado (evento {@code UserPrivacyChanged}).
 */
public class NoteService implements ListNotesUseCase, ListSharedNotesUseCase, GetNoteUseCase, CreateNoteUseCase,
        UpdateNoteUseCase, DeleteNoteUseCase, PrivatizeUserNotesUseCase {

    private final NoteRepositoryPort notes;
    private final StudyMaterialRepositoryPort materials;
    private final AiDocumentRepositoryPort aiDocuments;
    private final Clock clock;
    private final AcademicLookups lookups;

    public NoteService(NoteRepositoryPort notes, SubjectRepositoryPort subjects,
                       StudyMaterialRepositoryPort materials, AiDocumentRepositoryPort aiDocuments, Clock clock) {
        this.notes = notes;
        this.materials = materials;
        this.aiDocuments = aiDocuments;
        this.clock = clock;
        this.lookups = new AcademicLookups(subjects, notes, null, materials, null, clock);
    }

    @Override
    public PageResult<Note> listNotes(Query q) {
        if (q.subjectId() != null) {
            lookups.subject(q.userId(), q.subjectId());
        }
        return notes.findByUser(q.userId(),
                new NoteRepositoryPort.Filter(q.subjectId(), q.quickOnly(), q.unassignedOnly()), q.page());
    }

    @Override
    public PageResult<SharedNote> listSharedNotes(UUID userId, PageRequest page) {
        return notes.findSharedWith(userId, page);
    }

    @Override
    public Note getNote(UUID userId, UUID noteId) {
        return lookups.note(userId, noteId);
    }

    @Override
    public Note createNote(CreateNoteUseCase.Command c) {
        if (c.subjectId() != null) {
            lookups.subject(c.userId(), c.subjectId());
        }
        return notes.save(Note.create(c.userId(), c.subjectId(), c.title(), c.content(), c.visibility(),
                c.quickNote(), clock.instant()));
    }

    @Override
    public Note updateNote(UpdateNoteUseCase.Command c) {
        Note note = lookups.note(c.userId(), c.noteId());
        if (c.title() != null) {
            note.retitle(c.title());
        }
        if (c.content() != null) {
            note.rewrite(c.content());
        }
        if (c.detachSubject()) {
            note.moveToSubject(null);
        } else if (c.subjectId() != null) {
            note.moveToSubject(lookups.subject(c.userId(), c.subjectId()).id());
        }
        if (c.visibility() != null) {
            note.changeVisibility(c.visibility());
        }
        if (c.quickNote() != null) {
            note.markQuickNote(c.quickNote());
        }
        note.touch(clock.instant());
        Note saved = notes.save(note);
        // El material de estudio del apunte sigue su título y su asignatura (si sigue teniendo una).
        materials.findByOrigin(c.userId(), StudySourceType.NOTE, saved.id()).ifPresent(m -> {
            m.retitle(saved.title());
            if (saved.subjectId() != null) {
                m.moveToSubject(saved.subjectId());
            }
            materials.save(m);
        });
        return saved;
    }

    @Override
    public int privatizeAll(UUID userId) {
        int changed = 0;
        for (Note note : notes.findNonPrivateByUser(userId)) {
            if (note.privatize()) {
                note.touch(clock.instant());
                notes.save(note);
                changed++;
            }
        }
        return changed;
    }

    @Override
    public void deleteNote(UUID userId, UUID noteId) {
        Note note = lookups.note(userId, noteId);
        materials.findByOrigin(userId, StudySourceType.NOTE, note.id()).ifPresent(m -> materials.delete(m.id()));
        aiDocuments.deleteBySource(userId, AiDocumentSource.NOTE, note.id().toString());
        notes.delete(note.id());
    }
}
