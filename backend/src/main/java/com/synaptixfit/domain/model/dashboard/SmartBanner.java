package com.synaptixfit.domain.model.dashboard;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Mensaje prioritario del día para el inicio. El cliente lo redacta con sus traducciones a partir
 * de {@code type} y los parámetros numéricos (sustituye a los textos fijos y a la llamada a la IA
 * de {@code smart_banner_provider.dart}).
 *
 * @param labels textos que el cliente cita tal cual (p. ej. el nombre del bloque) y, en
 *               {@code MISSED_BLOCKS}, el id del bloque para actuar sobre él
 */
public record SmartBanner(Type type, Map<String, Number> params, Map<String, String> labels) {

    public SmartBanner {
        params = Collections.unmodifiableMap(new LinkedHashMap<>(params));
        labels = labels == null ? Map.of() : Collections.unmodifiableMap(new LinkedHashMap<>(labels));
    }

    public SmartBanner(Type type, Map<String, Number> params) {
        this(type, params, Map.of());
    }

    /** El mismo aviso con más datos (números y textos) para que el cliente lo concrete. */
    public SmartBanner with(Map<String, Number> moreParams, Map<String, String> moreLabels) {
        Map<String, Number> p = new LinkedHashMap<>(params);
        p.putAll(moreParams);
        Map<String, String> l = new LinkedHashMap<>(labels);
        l.putAll(moreLabels);
        return new SmartBanner(type, p, l);
    }

    /** Tipos en orden de prioridad (el primero que aplica gana). */
    public enum Type {
        /** ACWR en zona de peligro o sobreentrenamiento: params acwr, maxStudyMinutes. */
        PHYSICAL_OVERLOAD,
        /** Entregas o exámenes vencidos sin completar (últimos 14 días): params count. */
        OVERDUE_DEADLINES,
        /** Entregas o exámenes pendientes en los próximos 7 días: params count, daysUntilNext. */
        UPCOMING_DEADLINES,
        /**
         * Bloques de ayer u hoy que pasaron sin hacerse: params count y, del más reciente, startMinutes
         * (minuto del día) y yesterday (1 si fue ayer); labels title (asignatura o temas, puede faltar),
         * activity (tipo, p. ej. STUDY) y blockId (id del bloque, para actuar sobre él desde el aviso).
         */
        MISSED_BLOCKS,
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
