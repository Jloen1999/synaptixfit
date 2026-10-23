package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.academic.SignedUrl;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.shared.Visibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** DTOs de apuntes y archivos de asignatura. */
public final class NoteDtos {

    private NoteDtos() {
    }

    public record CreateNoteRequest(UUID subjectId,
                                    @NotBlank @Size(max = 200) String title,
                                    @Size(max = 200_000) String content,
                                    Visibility visibility,
                                    Boolean quickNote) {
    }

    /** Texto reconocido por el escáner del cliente que se guarda como apunte privado. */
    public record ScannedNoteRequest(@NotBlank @Size(max = 200) String title,
                                     @NotBlank @Size(max = 200_000) String text,
                                     UUID subjectId) {
    }

    /** Edición parcial: nulos sin cambios; {@code detachSubject} deja el apunte sin asignatura. */
    public record UpdateNoteRequest(@Size(min = 1, max = 200) String title,
                                    @Size(max = 200_000) String content,
                                    UUID subjectId,
                                    Boolean detachSubject,
                                    Visibility visibility,
                                    Boolean quickNote) {
    }

    public record NoteResponse(UUID id, UUID subjectId, String title, String content, Visibility visibility,
                               boolean quickNote, Instant createdAt, Instant updatedAt) {

        public static NoteResponse from(Note n) {
            return new NoteResponse(n.id(), n.subjectId(), n.title(), n.content(), n.visibility(), n.quickNote(),
                    n.createdAt(), n.updatedAt());
        }
    }

    public record SharedNoteResponse(UUID id, UUID authorId, String authorName, String authorAvatarUrl,
                                     UUID subjectId, String title, String content, Visibility visibility,
                                     Instant createdAt, Instant updatedAt) {

        public static SharedNoteResponse from(SharedNote s) {
            Note n = s.note();
            return new SharedNoteResponse(n.id(), n.userId(), s.authorName(), s.authorAvatarUrl(), n.subjectId(),
                    n.title(), n.content(), n.visibility(), n.createdAt(), n.updatedAt());
        }
    }

    // ------------------------------------------------------------------ archivos

    public record FileUploadRequest(@NotBlank @Size(max = 255) String fileName,
                                    @NotBlank @Size(max = 150) String mimeType,
                                    @NotNull @Positive Long sizeBytes) {
    }

    /** Clave reservada y URL prefirmada: el cliente hace {@code method} a {@code uploadUrl} con {@code headers}. */
    public record FileUploadResponse(String objectKey, String uploadUrl, String method, Map<String, String> headers,
                                     Instant expiresAt) {

        public static FileUploadResponse from(String objectKey, SignedUrl url) {
            return new FileUploadResponse(objectKey, url.url(), url.method(), url.headers(), url.expiresAt());
        }
    }

    public record ConfirmFileRequest(@NotBlank @Size(max = 1024) String objectKey,
                                     @NotBlank @Size(max = 255) String fileName,
                                     @NotBlank @Size(max = 150) String mimeType,
                                     @NotNull @Positive Long sizeBytes) {
    }

    public record SubjectFileResponse(UUID id, UUID subjectId, String fileName, String mimeType, long sizeBytes,
                                      String publicUrl, boolean aiReadable, Instant createdAt) {

        public static SubjectFileResponse from(SubjectFile f) {
            String url = f.storedUrl() != null && f.storedUrl().startsWith("http") ? f.storedUrl() : null;
            return new SubjectFileResponse(f.id(), f.subjectId(), f.fileName(), f.mimeType(), f.sizeBytes(), url,
                    f.isAiReadable(), f.createdAt());
        }
    }

    public record SignedUrlResponse(String url, String method, Map<String, String> headers, Instant expiresAt) {

        public static SignedUrlResponse from(SignedUrl u) {
            return new SignedUrlResponse(u.url(), u.method(), u.headers(), u.expiresAt());
        }
    }
}
