package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code test_sessions}. */
@Entity
@Table(name = "test_sessions")
public class TestSessionEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID userId;
    @Column(name = "material_id", nullable = false, updatable = false)
    private UUID materialId;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "preguntas_ids", nullable = false)
    private List<String> questionIds;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "respuestas", nullable = false)
    private Map<String, String> answers;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "resultados", nullable = false)
    private Map<String, Boolean> results;
    @Column(name = "indice_actual", nullable = false)
    private int currentIndex;
    @Column(name = "status", nullable = false)
    private String status;
    @Column(name = "score", nullable = false)
    private int score;
    @Column(name = "total_preguntas", nullable = false)
    private int totalQuestions;
    @Column(name = "iniciado_en", nullable = false, updatable = false)
    private Instant startedAt;
    @Column(name = "completado_en")
    private Instant completedAt;
    @Column(name = "xp_otorgado", nullable = false)
    private boolean xpAwarded;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public UUID getMaterialId() { return materialId; }
    public void setMaterialId(UUID materialId) { this.materialId = materialId; }
    public List<String> getQuestionIds() { return questionIds; }
    public void setQuestionIds(List<String> questionIds) { this.questionIds = questionIds; }
    public Map<String, String> getAnswers() { return answers; }
    public void setAnswers(Map<String, String> answers) { this.answers = answers; }
    public Map<String, Boolean> getResults() { return results; }
    public void setResults(Map<String, Boolean> results) { this.results = results; }
    public int getCurrentIndex() { return currentIndex; }
    public void setCurrentIndex(int currentIndex) { this.currentIndex = currentIndex; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getScore() { return score; }
    public void setScore(int score) { this.score = score; }
    public int getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(int totalQuestions) { this.totalQuestions = totalQuestions; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getCompletedAt() { return completedAt; }
    public void setCompletedAt(Instant completedAt) { this.completedAt = completedAt; }
    public boolean isXpAwarded() { return xpAwarded; }
    public void setXpAwarded(boolean xpAwarded) { this.xpAwarded = xpAwarded; }
}
