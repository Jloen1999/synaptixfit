package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.social.PostForbiddenException;
import com.synaptixfit.domain.exception.social.SocialCannotReportOwnContentException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Publicación del muro social. Solo su autor puede editarla o borrarla; cualquier otro usuario
 * que la vea puede reportarla para moderación.
 */
public final class Post {

    public static final int MAX_DESCRIPTION = 2000;
    public static final int MAX_IMAGE_URL = 2048;
    public static final int MAX_METADATA = 10_000;

    private final UUID id;
    private final UUID authorId;
    private final PostType type;
    private String description;
    private String imageUrl;
    private final String metadata;
    private final Instant createdAt;
    private Instant editedAt;
    private boolean reported;
    private UUID reportedBy;

    public Post(UUID id, UUID authorId, PostType type, String description, String imageUrl, String metadata,
                Instant createdAt, Instant editedAt, boolean reported, UUID reportedBy) {
        this.id = Objects.requireNonNull(id, "id");
        this.authorId = Objects.requireNonNull(authorId, "authorId");
        this.type = Guard.notNull(type, "type");
        this.description = Guard.length(description, "description", 1, MAX_DESCRIPTION);
        this.imageUrl = normalizeImageUrl(imageUrl);
        if (metadata != null && metadata.length() > MAX_METADATA) {
            throw new FieldValidationException("metadata", "INVALID_LENGTH", "metadata is too large");
        }
        this.metadata = metadata;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.editedAt = editedAt;
        this.reported = reported;
        this.reportedBy = reportedBy;
    }

    /** Crea una publicación nueva del autor. */
    /**
     * ¿Solo puede haber una publicación de este tipo por entidad vinculada ({@code metadata})? Compartir una
     * sesión desde su resumen dos veces (o al reabrirlo) no debe duplicarla en el muro.
     */
    public static boolean uniquePerMetadata(PostType type, String metadata) {
        return type == PostType.SESSION_COMPLETED && metadata != null;
    }

    public static Post publish(UUID authorId, PostType type, String description, String imageUrl, String metadata,
                               Instant now) {
        return new Post(UUID.randomUUID(), authorId, type, description, imageUrl, metadata, now, null, false, null);
    }

    public boolean isAuthoredBy(UUID userId) {
        return authorId.equals(userId);
    }

    /**
     * Edita la publicación. Los valores nulos no cambian; una URL de imagen en blanco la quita.
     * Marca {@code editedAt} para que el cliente muestre que fue editada.
     */
    public void edit(UUID editorId, String newDescription, String newImageUrl, Instant now) {
        ensureAuthor(editorId);
        if (newDescription != null) {
            this.description = Guard.length(newDescription, "description", 1, MAX_DESCRIPTION);
        }
        if (newImageUrl != null) {
            this.imageUrl = normalizeImageUrl(newImageUrl);
        }
        this.editedAt = Objects.requireNonNull(now);
    }

    /** Comprueba que quien borra es el autor. */
    public void ensureCanBeDeletedBy(UUID userId) {
        ensureAuthor(userId);
    }

    /** Marca la publicación para moderación. El autor no puede reportarse a sí mismo. */
    public void report(UUID reporterId) {
        if (isAuthoredBy(reporterId)) {
            throw new SocialCannotReportOwnContentException(id);
        }
        this.reported = true;
        this.reportedBy = reporterId;
    }

    /** Un moderador descarta el reporte: la publicación sigue visible. */
    public void dismissReport() {
        this.reported = false;
        this.reportedBy = null;
    }

    private void ensureAuthor(UUID userId) {
        if (!isAuthoredBy(userId)) {
            throw new PostForbiddenException(id);
        }
    }

    private static String normalizeImageUrl(String url) {
        if (url == null || url.isBlank()) {
            return null;
        }
        return Guard.length(url, "imageUrl", 1, MAX_IMAGE_URL);
    }

    public UUID id() { return id; }
    public UUID authorId() { return authorId; }
    public PostType type() { return type; }
    public String description() { return description; }
    public String imageUrl() { return imageUrl; }
    public String metadata() { return metadata; }
    public Instant createdAt() { return createdAt; }
    public Instant editedAt() { return editedAt; }
    public boolean reported() { return reported; }
    public UUID reportedBy() { return reportedBy; }
}
