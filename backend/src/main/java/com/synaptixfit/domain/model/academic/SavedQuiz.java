package com.synaptixfit.domain.model.academic;

/** Cuestionario generado guardado para repasar: apunte con su contenido, material y banco. */
public record SavedQuiz(Note note, StudyMaterial material, QuestionBank bank, int questionCount) {
}
