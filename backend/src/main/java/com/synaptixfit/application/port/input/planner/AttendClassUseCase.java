package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Da por asistida una clase que terminó (ADR 0029): la completa como si se marcara a mano (XP, carga cognitiva,
 * semana y evento). Vuelve a leer la clase bloqueándola y no hace nada si ya está completada, tiene «No fui» o aún
 * no ha terminado; repetirlo no cambia nada.
 *
 * @return si la completó
 */
public interface AttendClassUseCase {

    boolean attendClass(UUID blockId);
}
