package com.synaptixfit.application.port.input.planner;

import java.util.List;
import java.util.UUID;

/**
 * Clases que acaban de terminar y se dan por asistidas solas (ADR 0029): sin completar, sin «No fui» y de las
 * últimas 24 h. Solo las busca; cada una se completa aparte con {@link AttendClassUseCase} (una transacción por
 * clase, para que un fallo no deje sin asistencia a todas).
 */
public interface AttendEndedClassesUseCase {

    List<UUID> endedClassesToAttend();
}
