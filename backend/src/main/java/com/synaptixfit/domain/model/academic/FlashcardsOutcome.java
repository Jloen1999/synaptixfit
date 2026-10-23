package com.synaptixfit.domain.model.academic;

/** Resultado de una ronda de flashcards: repaso aplicado, calidad derivada y XP concedida. */
public record FlashcardsOutcome(StudyMaterial material, ReviewRecord record, int quality, int xpAwarded) {
}
