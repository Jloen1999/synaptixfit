package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code intentos_pregunta}. */
@Entity
@Table(name = "intentos_pregunta")
public class QuestionAttemptEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "pregunta_id", nullable = false, updatable = false)
    private UUID questionId;
    @Column(name = "es_correcta", nullable = false)
    private boolean correct;
    @Column(name = "respondido_en", nullable = false)
    private Instant answeredAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getQuestionId() { return questionId; }
    public void setQuestionId(UUID questionId) { this.questionId = questionId; }
    public boolean isCorrect() { return correct; }
    public void setCorrect(boolean correct) { this.correct = correct; }
    public Instant getAnsweredAt() { return answeredAt; }
    public void setAnsweredAt(Instant answeredAt) { this.answeredAt = answeredAt; }
}
