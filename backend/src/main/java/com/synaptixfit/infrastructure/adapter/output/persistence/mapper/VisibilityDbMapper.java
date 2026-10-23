package com.synaptixfit.infrastructure.adapter.output.persistence.mapper;

import com.synaptixfit.domain.model.shared.Visibility;
import java.util.Locale;

/** Visibilidad de dominio ↔ valor en base de datos ('private' | 'friends' | 'public'). */
public final class VisibilityDbMapper {

    private VisibilityDbMapper() {
    }

    public static String toDb(Visibility visibility) {
        return visibility.name().toLowerCase(Locale.ROOT);
    }

    public static Visibility toDomain(String value) {
        return value == null ? Visibility.PRIVATE : Visibility.valueOf(value.toUpperCase(Locale.ROOT));
    }
}
