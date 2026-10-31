package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.enrollment.EnrollmentProposal;
import java.util.UUID;

/**
 * Lee un documento de matrícula (carta de pago, resguardo) y propone universidad, carrera y
 * asignaturas. Exige el permiso expreso del usuario; el documento no se guarda.
 */
public interface ReadEnrollmentUseCase {

    /** @param consent el usuario ha aceptado que se lea el documento (datos personales) */
    record Command(UUID userId, byte[] content, String mimeType, boolean consent) {
    }

    EnrollmentProposal readEnrollment(Command command);
}
