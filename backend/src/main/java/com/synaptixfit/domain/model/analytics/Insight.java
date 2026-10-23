package com.synaptixfit.domain.model.analytics;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Interpretación de la analítica como dato estructurado. El cliente redacta la frase con sus
 * traducciones a partir de {@code type} + {@code variant} y de los parámetros numéricos.
 *
 * @param variant subcaso dentro del tipo (p. ej. {@code BUILDING} en una racha de 2-6 días)
 */
public record Insight(Type type, Severity severity, String variant, Map<String, Number> params) {

    public Insight {
        params = java.util.Collections.unmodifiableMap(new LinkedHashMap<>(params));
    }

    public enum Type { STREAK, CONSISTENCY, VOLUME, CORRELATION }

    /** Tono del mensaje: refuerzo positivo, informativo o aviso. */
    public enum Severity { POSITIVE, INFO, WARNING }
}
