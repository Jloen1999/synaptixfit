package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.CopySharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.CreateNoteUseCase;
import com.synaptixfit.application.port.input.academic.DeleteNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetSharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.ListNotesUseCase;
import com.synaptixfit.application.port.input.academic.ListSharedNotesUseCase;
import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.application.port.input.academic.UpdateNoteUseCase;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.CreateNoteRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.NoteResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.ScannedNoteDraftResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.SharedNoteResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.SharedNoteSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.UpdateNoteRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** Apuntes en Markdown (propios y compartidos). */
@Tag(name = "Academic - Notes")
@RestController
@RequestMapping("/api/v1/notes")
public class NoteController {

    private final ListNotesUseCase listNotes;
    private final ListSharedNotesUseCase listShared;
    private final GetNoteUseCase getNote;
    private final CreateNoteUseCase createNote;
    private final UpdateNoteUseCase updateNote;
    private final DeleteNoteUseCase deleteNote;
    private final GetSharedNoteUseCase getShared;
    private final CopySharedNoteUseCase copyShared;
    private final ReadNotePhotosUseCase readPhotos;

    public NoteController(ListNotesUseCase listNotes, ListSharedNotesUseCase listShared, GetNoteUseCase getNote,
                          CreateNoteUseCase createNote, UpdateNoteUseCase updateNote, DeleteNoteUseCase deleteNote,
                          GetSharedNoteUseCase getShared, CopySharedNoteUseCase copyShared,
                          ReadNotePhotosUseCase readPhotos) {
        this.readPhotos = readPhotos;
        this.getShared = getShared;
        this.copyShared = copyShared;
        this.listNotes = listNotes;
        this.listShared = listShared;
        this.getNote = getNote;
        this.createNote = createNote;
        this.updateNote = updateNote;
        this.deleteNote = deleteNote;
    }

    @GetMapping
    public PageResponse<NoteResponse> list(@CurrentUserId UUID userId,
                                           @RequestParam(required = false) UUID subjectId,
                                           @RequestParam(defaultValue = "false") boolean quickOnly,
                                           @RequestParam(defaultValue = "false") boolean unassignedOnly,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listNotes.listNotes(new ListNotesUseCase.Query(userId, subjectId, quickOnly,
                unassignedOnly, new PageRequest(page, size))), NoteResponse::from);
    }

    /**
     * Apuntes de otros usuarios que puedo leer. {@code scope}: {@code FRIENDS} (de mis amigos),
     * {@code PUBLIC} (comunidad: lo que ve cualquiera) o {@code ALL}. Con mi propio {@code authorId},
     * mis apuntes que otros pueden ver.
     */
    @GetMapping("/shared")
    public PageResponse<SharedNoteSummaryResponse> shared(@CurrentUserId UUID userId,
                                                          @RequestParam(defaultValue = "ALL") AudienceScope scope,
                                                          @RequestParam(required = false) UUID authorId,
                                                          @RequestParam(required = false) UUID catalogSubjectId,
                                                          @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listShared.listSharedNotes(new ListSharedNotesUseCase.Query(userId, scope, authorId,
                catalogSubjectId, new PageRequest(page, size))), s -> SharedNoteSummaryResponse.from(s, userId));
    }

    @GetMapping("/shared/{noteId}")
    public SharedNoteResponse sharedNote(@CurrentUserId UUID userId, @PathVariable UUID noteId) {
        return SharedNoteResponse.from(getShared.getSharedNote(userId, noteId), userId);
    }

    /** Guarda una copia privada del apunte en mis apuntes (en mi asignatura equivalente si la tengo). */
    @PostMapping("/shared/{noteId}/copy")
    @ResponseStatus(HttpStatus.CREATED)
    public NoteResponse copyShared(@CurrentUserId UUID userId, @PathVariable UUID noteId) {
        return NoteResponse.from(copyShared.copySharedNote(userId, noteId));
    }

    @GetMapping("/{noteId}")
    public NoteResponse get(@CurrentUserId UUID userId, @PathVariable UUID noteId) {
        return NoteResponse.from(getNote.getNote(userId, noteId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public NoteResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreateNoteRequest r) {
        return NoteResponse.from(createNote.createNote(new CreateNoteUseCase.Command(userId, r.subjectId(),
                r.title(), r.content(), r.visibility(), Boolean.TRUE.equals(r.quickNote()))));
    }

    /**
     * Lee fotos de apuntes en papel (campo {@code files}, de 1 a 5 imágenes) y devuelve un borrador
     * para revisar. No guarda nada: el apunte se crea después con {@code POST /notes} (ADR 0040).
     */
    @PostMapping(value = "/scan-drafts", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ScannedNoteDraftResponse scanDraft(@CurrentUserId UUID userId,
                                              @RequestPart("files") List<MultipartFile> files) {
        List<NotePhoto> photos = new ArrayList<>();
        for (MultipartFile file : files == null ? List.<MultipartFile>of() : files) {
            try {
                photos.add(new NotePhoto(file.getBytes(), file.getContentType()));
            } catch (IOException e) {
                throw new NoteScanUnsupportedFileException();
            }
        }
        return ScannedNoteDraftResponse.from(readPhotos.read(new ReadNotePhotosUseCase.Command(userId, photos)));
    }

    @PatchMapping("/{noteId}")
    public NoteResponse update(@CurrentUserId UUID userId, @PathVariable UUID noteId,
                               @Valid @RequestBody UpdateNoteRequest r) {
        return NoteResponse.from(updateNote.updateNote(new UpdateNoteUseCase.Command(userId, noteId, r.title(),
                r.content(), r.subjectId(), Boolean.TRUE.equals(r.detachSubject()), r.visibility(), r.quickNote())));
    }

    @DeleteMapping("/{noteId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID noteId) {
        deleteNote.deleteNote(userId, noteId);
    }
}
