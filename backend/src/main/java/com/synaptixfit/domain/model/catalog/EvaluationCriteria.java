package com.synaptixfit.domain.model.catalog;

/** Ponderación de la evaluación de una asignatura del catálogo (porcentajes). */
public record EvaluationCriteria(double finalExamPercent, double continuousAssessmentPercent, double labPercent) {
}
