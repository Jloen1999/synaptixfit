package com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code preguntas}. */
@Entity
@Table(name = "preguntas")
public class QuestionEntity {

    @Id
    @Column(name = "id")
    private UUID id;
    @Column(name = "banco_id", nullable = false, updatable = false)
    private UUID bankId;
    @Column(name = "tipo", nullable = false)
    private String type;
    @Column(name = "enunciado", nullable = false)
    private String statement;
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "opciones")
    private List<String> options;
    @Column(name = "respuesta_correcta", nullable = false)
    private String correctAnswer;
    @Column(name = "explicacion")
    private String explanation;
    @Column(name = "orden", nullable = false)
    private int position;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBankId() { return bankId; }
    public void setBankId(UUID bankId) { this.bankId = bankId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getStatement() { return statement; }
    public void setStatement(String statement) { this.statement = statement; }
    public List<String> getOptions() { return options; }
    public void setOptions(List<String> options) { this.options = options; }
    public String getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }
}
