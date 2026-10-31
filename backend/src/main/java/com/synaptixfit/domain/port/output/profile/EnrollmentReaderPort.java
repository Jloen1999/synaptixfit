package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading;

/**
 * Lee con IA un documento de matrícula a partir de su texto, que llega ya sin datos personales
 * (PersonalDataRedactor). Lanza AiUnavailableException si la respuesta no es válida.
 */
public interface EnrollmentReaderPort {

    EnrollmentReading read(String redactedText);
}
