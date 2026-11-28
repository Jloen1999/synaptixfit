package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;

/**
 * Qué deporte fue una actividad apuntada y, si es de partido, cómo fue (ADR 0068). Solo describe: no cambia la
 * racha, la XP, la carga ni los retos, que cuentan la actividad como siempre.
 *
 * @param sport     deporte del catálogo
 * @param name      nombre libre, solo en {@link Sport#OTHER} («Escalada»); sin espacios de más, 40 letras como mucho
 * @param mode      partido o entreno; solo en deportes de partido (por defecto, partido)
 * @param result    resultado, solo de un partido; opcional
 * @param scoreText marcador tal como lo escribe la persona («6-4 6-3»), solo de un partido; opcional
 */
public record SportDetails(Sport sport, String name, SportMode mode, MatchResult result, String scoreText) {

    public static final int NAME_MAX = 40;
    public static final int SCORE_MAX = 20;

    public SportDetails {
        Guard.notNull(sport, "sport");
        name = sport == Sport.OTHER ? normalizedName(name) : null;
        if (sport.category() == SportCategory.MATCH) {
            mode = mode == null ? SportMode.MATCH : mode;
        } else {
            mode = null;
        }
        if (mode == SportMode.MATCH) {
            scoreText = scoreText == null || scoreText.isBlank() ? null : scoreText.strip();
            if (scoreText != null && scoreText.length() > SCORE_MAX) {
                throw new FieldValidationException("scoreText", "TOO_LONG",
                        "score must be at most " + SCORE_MAX + " characters");
            }
        } else {
            // Un entreno no se gana ni se pierde: el resultado y el marcador solo tienen sentido en un partido.
            result = null;
            scoreText = null;
        }
    }

    /** Solo el deporte, sin datos de partido. */
    public static SportDetails of(Sport sport) {
        return new SportDetails(sport, null, null, null, null);
    }

    /** Lo que se deduce de una actividad que solo trae la clase de antes y su título (apps ya instaladas). */
    public static SportDetails fromLegacy(ActivityKind kind, String title) {
        return new SportDetails(Sport.fromLegacy(kind, title), title, null, null, null);
    }

    /** Sin espacios al principio, al final ni repetidos: «  tiro   con arco » y «tiro con arco» son el mismo. */
    private static String normalizedName(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String clean = raw.strip().replaceAll("\\s+", " ");
        return clean.length() > NAME_MAX ? clean.substring(0, NAME_MAX).stripTrailing() : clean;
    }
}
