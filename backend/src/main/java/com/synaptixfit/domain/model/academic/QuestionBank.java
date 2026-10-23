package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Banco de preguntas de un material de estudio. {@code xpAwarded} evita repetir la XP de práctica libre. */
public record QuestionBank(UUID id, UUID materialId, UUID userId, boolean xpAwarded, Instant generatedAt) {

    public QuestionBank {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(materialId, "materialId");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(generatedAt, "generatedAt");
    }

    public static QuestionBank create(UUID materialId, UUID userId, Instant now) {
        return new QuestionBank(UUID.randomUUID(), materialId, userId, false, now);
    }

    public QuestionBank regenerated(Instant now) {
        return new QuestionBank(id, materialId, userId, xpAwarded, now);
    }

    public QuestionBank withXpAwarded() {
        return new QuestionBank(id, materialId, userId, true, generatedAt);
    }
}
