package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.exception.social.CommentForbiddenException;
import com.synaptixfit.domain.exception.social.CommentNotFoundException;
import com.synaptixfit.domain.exception.social.SocialCannotReportOwnContentException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Comentario de una publicación (1-500 caracteres). El borrado es lógico. Solo el autor del
 * comentario puede editarlo o borrarlo (como en el sistema anterior); los moderadores lo borran
 * desde la administración.
 */
public final class Comment {

    public static final int MAX_TEXT = 500;

    private final UUID id;
    private final UUID postId;
    private final UUID authorId;
    private String text;
    private final Instant createdAt;
    private Instant editedAt;
    private boolean deleted;
    private boolean reported;
    private UUID reportedBy;

    public Comment(UUID id, UUID postId, UUID authorId, String text, Instant createdAt, Instant editedAt,
                   boolean deleted, boolean reported, UUID reportedBy) {
        this.id = Objects.requireNonNull(id, "id");
        this.postId = Objects.requireNonNull(postId, "postId");
        this.authorId = Objects.requireNonNull(authorId, "authorId");
        this.text = Guard.length(text, "text", 1, MAX_TEXT);
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.editedAt = editedAt;
        this.deleted = deleted;
        this.reported = reported;
        this.reportedBy = reportedBy;
    }

    public static Comment write(UUID postId, UUID authorId, String text, Instant now) {
        return new Comment(UUID.randomUUID(), postId, authorId, text, now, null, false, false, null);
    }

    public boolean isAuthoredBy(UUID userId) {
        return authorId.equals(userId);
    }

    public void edit(UUID editorId, String newText, Instant now) {
        ensureAlive();
        if (!isAuthoredBy(editorId)) {
            throw new CommentForbiddenException(id);
        }
        this.text = Guard.length(newText, "text", 1, MAX_TEXT);
        this.editedAt = Objects.requireNonNull(now);
    }

    /** Borrado lógico por su autor. */
    public void delete(UUID userId) {
        ensureAlive();
        if (!isAuthoredBy(userId)) {
            throw new CommentForbiddenException(id);
        }
        this.deleted = true;
    }

    public void report(UUID reporterId) {
        ensureAlive();
        if (isAuthoredBy(reporterId)) {
            throw new SocialCannotReportOwnContentException(id);
        }
        this.reported = true;
        this.reportedBy = reporterId;
    }

    public void dismissReport() {
        this.reported = false;
        this.reportedBy = null;
    }

    /** Borrado lógico por un moderador: también cierra el reporte. */
    public void removeByModerator() {
        this.deleted = true;
        this.reported = false;
    }

    private void ensureAlive() {
        if (deleted) {
            throw new CommentNotFoundException(id);
        }
    }

    public UUID id() { return id; }
    public UUID postId() { return postId; }
    public UUID authorId() { return authorId; }
    public String text() { return text; }
    public Instant createdAt() { return createdAt; }
    public Instant editedAt() { return editedAt; }
    public boolean deleted() { return deleted; }
    public boolean reported() { return reported; }
    public UUID reportedBy() { return reportedBy; }
}
