package com.synaptixfit.domain.port.output.badge;

import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Set;
import java.util.UUID;

/** Actividad del usuario registrada por otros módulos (solo lectura). */
public interface UserActivityPort {

    /** Días (en la zona indicada) con una sesión de entrenamiento, un check-in diario o un Pomodoro completado. */
    Set<LocalDate> activeDays(UUID userId, ZoneId zone);

    /** Datos para calcular las métricas de las insignias. */
    BadgeActivitySnapshot snapshot(UUID userId, ZoneId zone);
}
