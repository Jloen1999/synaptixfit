package com.synaptixfit.domain.model.planner;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;

/**
 * Catálogo de deportes de una actividad apuntada (ADR 0068). El código es estable: viaja por la API y se guarda
 * tal cual. Cada deporte conserva su {@link ActivityKind} de antes, que las apps ya instaladas siguen leyendo.
 */
public enum Sport {
    RUN(SportCategory.ENDURANCE, ActivityKind.RUN),
    WALK(SportCategory.ENDURANCE, ActivityKind.WALK),
    BIKE(SportCategory.ENDURANCE, ActivityKind.BIKE),
    SWIM(SportCategory.ENDURANCE, ActivityKind.SWIM),
    FOOTBALL(SportCategory.MATCH, ActivityKind.MATCH, "futbol", "football", "soccer", "futebol"),
    PADEL(SportCategory.MATCH, ActivityKind.MATCH, "padel", "paddle"),
    BASKETBALL(SportCategory.MATCH, ActivityKind.MATCH, "baloncesto", "basket", "basquet"),
    VOLLEYBALL(SportCategory.MATCH, ActivityKind.MATCH, "voley", "volley", "voleibol", "volei"),
    TENNIS(SportCategory.MATCH, ActivityKind.MATCH, "tenis", "tennis"),
    /** Entreno del día por formato (ADR 0069): lo apunta el servidor al guardar una marca de WOD. */
    WOD(SportCategory.OTHER, ActivityKind.OTHER),
    OTHER(SportCategory.OTHER, ActivityKind.OTHER);

    private final SportCategory category;
    private final ActivityKind legacyKind;
    private final List<String> titleWords;

    Sport(SportCategory category, ActivityKind legacyKind, String... titleWords) {
        this.category = category;
        this.legacyKind = legacyKind;
        this.titleWords = List.of(titleWords);
    }

    public SportCategory category() {
        return category;
    }

    /** La clase de antes ({@code kind}), que se sigue guardando y devolviendo. */
    public ActivityKind legacyKind() {
        return legacyKind;
    }

    /**
     * Deporte de una actividad que solo trae la clase de antes: el suyo si se medía en distancia; si era un partido,
     * el que nombre su título («Fútbol», «Pádel con Ana»); en otro caso, {@link #OTHER}. Es la misma regla con la que
     * la migración V1083 rellenó las actividades ya guardadas.
     */
    public static Sport fromLegacy(ActivityKind kind, String title) {
        if (kind == null) {
            return OTHER;
        }
        return switch (kind) {
            case RUN -> RUN;
            case WALK -> WALK;
            case BIKE -> BIKE;
            case SWIM -> SWIM;
            case MATCH -> fromTitle(title);
            case OTHER -> OTHER;
        };
    }

    private static Sport fromTitle(String title) {
        if (title == null) {
            return OTHER;
        }
        // Sin tildes y en minúsculas: «Fútbol», «FUTBOL» y «futbol sala» nombran el mismo deporte.
        String plain = Normalizer.normalize(title, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
        for (Sport sport : values()) {
            if (sport.titleWords.stream().anyMatch(plain::contains)) {
                return sport;
            }
        }
        return OTHER;
    }
}
