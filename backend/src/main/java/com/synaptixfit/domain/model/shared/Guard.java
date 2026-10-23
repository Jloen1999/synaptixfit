package com.synaptixfit.domain.model.shared;

import com.synaptixfit.domain.exception.FieldValidationException;

/** Comprobaciones de invariantes reutilizables por los modelos de dominio. */
public final class Guard {

    private Guard() {
    }

    public static <T> T notNull(T value, String field) {
        if (value == null) {
            throw new FieldValidationException(field, "REQUIRED", field + " is required");
        }
        return value;
    }

    public static String notBlank(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new FieldValidationException(field, "REQUIRED", field + " is required");
        }
        return value.strip();
    }

    public static String length(String value, String field, int min, int max) {
        String v = notBlank(value, field);
        if (v.length() < min || v.length() > max) {
            throw new FieldValidationException(field, "INVALID_LENGTH",
                    field + " length must be between " + min + " and " + max);
        }
        return v;
    }

    public static int range(int value, String field, int min, int max) {
        if (value < min || value > max) {
            throw new FieldValidationException(field, "OUT_OF_RANGE",
                    field + " must be between " + min + " and " + max);
        }
        return value;
    }

    public static double range(double value, String field, double min, double max) {
        if (value < min || value > max) {
            throw new FieldValidationException(field, "OUT_OF_RANGE",
                    field + " must be between " + min + " and " + max);
        }
        return value;
    }
}
