package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Apunte en Markdown, con o sin asignatura. Las notas rápidas son apuntes cortos marcados
 * como tales. Título de 1 a 200 caracteres; contenido de hasta 200 000 caracteres.
 */
public final class Note {

    public static final int MAX_CONTENT = 200_000;

    private final UUID id;
    private final UUID userId;
    private UUID subjectId;
    private String title;
    private String content;
    private Visibility visibility;
    private boolean quickNote;
    private final Instant createdAt;
    private Instant updatedAt;

    public Note(UUID id, UUID userId, UUID subjectId, String title, String content, Visibility visibility,
                boolean quickNote, Instant createdAt, Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.subjectId = subjectId;
        this.title = Guard.length(title, "title", 1, 200);
        this.content = TextRules.bounded(content, "content", MAX_CONTENT);
        this.visibility = visibility == null ? Visibility.PRIVATE : visibility;
        this.quickNote = quickNote;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.updatedAt = updatedAt == null ? createdAt : updatedAt;
    }

    public static Note create(UUID userId, UUID subjectId, String title, String content, Visibility visibility,
                              boolean quickNote, Instant now) {
        return new Note(UUID.randomUUID(), userId, subjectId, title, content, visibility, quickNote, now, now);
    }

    public void retitle(String value) {
        this.title = Guard.length(value, "title", 1, 200);
    }

    public void rewrite(String value) {
        this.content = TextRules.bounded(value, "content", MAX_CONTENT);
    }

    public void moveToSubject(UUID value) {
        this.subjectId = value;
    }

    public void changeVisibility(Visibility value) {
        this.visibility = Guard.notNull(value, "visibility");
    }

    /** Deja de compartir el apunte. Devuelve true si cambia. */
    public boolean privatize() {
        if (visibility == Visibility.PRIVATE) {
            return false;
        }
        visibility = Visibility.PRIVATE;
        return true;
    }

    public void markQuickNote(boolean value) {
        this.quickNote = value;
    }

    public void touch(Instant now) {
        this.updatedAt = now;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID subjectId() { return subjectId; }
    public String title() { return title; }
    public String content() { return content; }
    public Visibility visibility() { return visibility; }
    public boolean quickNote() { return quickNote; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
