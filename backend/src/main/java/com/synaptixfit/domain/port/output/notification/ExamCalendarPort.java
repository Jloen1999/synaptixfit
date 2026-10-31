package com.synaptixfit.domain.port.output.notification;

import java.time.Instant;
import java.util.UUID;

/** ¿Tiene el usuario un examen pendiente en [from, to)? Lo usa el modo exámenes automático. */
@FunctionalInterface
public interface ExamCalendarPort {

    boolean hasExamBetween(UUID userId, Instant from, Instant to);
}
