package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Elige la asignatura propia con la que cuentan las rondas (nula: ninguna). Solo la ve quien la elige (ADR 0045). */
public interface ChooseStudyRoomSubjectUseCase {

    StudyRoomView chooseSubject(UUID userId, UUID roomId, UUID subjectId);
}
