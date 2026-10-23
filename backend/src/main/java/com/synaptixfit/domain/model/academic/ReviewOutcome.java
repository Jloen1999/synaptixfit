package com.synaptixfit.domain.model.academic;

/** Material tras un repaso, su registro de auditoría y la XP concedida (0 si el repaso no tocaba). */
public record ReviewOutcome(StudyMaterial material, ReviewRecord record, int xpAwarded) {
}
