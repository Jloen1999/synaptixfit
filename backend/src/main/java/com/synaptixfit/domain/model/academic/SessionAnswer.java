package com.synaptixfit.domain.model.academic;

/** Respuesta registrada en una sesión: corrección y estado actualizado. */
public record SessionAnswer(AnswerResult result, TestSessionView view) {
}
