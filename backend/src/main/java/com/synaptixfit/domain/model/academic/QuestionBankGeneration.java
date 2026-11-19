package com.synaptixfit.domain.model.academic;

/**
 * Resultado de «Crear preguntas»: el banco y cuántas se pidieron y se guardaron. Puede haber menos si una
 * tanda de la IA falló tras reintentarla (se conservan las anteriores) o si ya tenías esa pregunta.
 */
public record QuestionBankGeneration(QuestionBankView view, int requested, int created) {
}
