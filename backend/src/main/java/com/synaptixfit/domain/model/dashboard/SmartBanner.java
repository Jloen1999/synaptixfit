package com.synaptixfit.domain.model.dashboard;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Mensaje prioritario del día para el inicio. El cliente lo redacta con sus traducciones a partir
 * de {@code type} y los parámetros numéricos (sustituye a los textos fijos y a la llamada a la IA
 * de {@code smart_banner_provider.dart}).
 */
public record SmartBanner(Type type, Map<String, Number> params) {

    public SmartBanner {
        params = Collections.unmodifiableMap(new LinkedHashMap<>(params));
    }

    /** Tipos en orden de prioridad (el primero que aplica gana). */
    public enum Type {
        /** ACWR en zona de peligro o sobreentrenamiento: params acwr, maxStudyMinutes. */
        PHYSICAL_OVERLOAD,
        /** Entregas o exámenes pendientes en los próximos 7 días: params count, daysUntilNext. */
        UPCOMING_DEADLINES,
        /** Fatiga media de los check-ins de los últimos 3 días &gt; 50: params fatigueScore. */
        HIGH_FATIGUE,
        /** Adherencia académica &lt; 40: params adherence. */
        LOW_ADHERENCE,
        /** Energía &lt; 30 (con check-in): params energy. */
        LOW_ENERGY,
        /** Capacidad atencional &lt; 0.4 tras una racha de estudio: params attentionCapacity, cognitiveLoad. */
        ATTENTION_DEPLETED,
        /** Energía &gt; 70 y estrés semanal &lt; 5: params energy, stress. */
        PEAK_DAY,
        /** 5+ días seguidos con estudio completado: params days. */
        STUDY_STREAK,
        /** Racha de 5+ días: params days. */
        TRAINING_STREAK,
        /** Vuelta tras 7-30 días sin entrenar (retomar al 80 %): params daysInactive, loadFactor. */
        COMEBACK,
        /** Check-in de hoy pendiente. */
        CHECK_IN_PENDING,
        /** Mensaje genérico de equilibrio. */
        BALANCE
    }
}
