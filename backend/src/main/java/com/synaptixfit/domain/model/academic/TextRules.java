package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;

/** Reglas de texto comunes del módulo académico. */
final class TextRules {

    private TextRules() {
    }

    /** Texto opcional: en blanco equivale a «sin valor»; si hay valor, se acota su longitud. */
    static String optional(String value, String field, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return Guard.length(value, field, 1, max);
    }

    /** Texto que puede estar vacío pero no superar el máximo. */
    static String bounded(String value, String field, int max) {
        String v = value == null ? "" : value;
        if (v.length() > max) {
            throw new FieldValidationException(field, "INVALID_LENGTH",
                    field + " length must be at most " + max);
        }
        return v;
    }
}
