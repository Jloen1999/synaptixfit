package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Borra un material propio con su banco, sesiones e historial (el apunte o archivo se conserva). */
public interface DeleteStudyMaterialUseCase {

    void deleteMaterial(UUID userId, UUID materialId);
}
