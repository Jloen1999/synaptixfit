package com.synaptixfit.domain.model.wod;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Lo que dice la pizarra de un WOD (ADR 0069): título y parte de fuerza opcionales, formato, límite de tiempo,
 * rondas y movimientos. Las reglas de cada formato viven aquí:
 * <ul>
 *   <li>Por tiempo: 1-50 rondas (por defecto 1) y límite opcional.</li>
 *   <li>AMRAP: límite obligatorio, sin rondas.</li>
 *   <li>EMOM: límite obligatorio en minutos enteros; las rondas son esos minutos.</li>
 *   <li>Tabata: siempre 8 rondas de 20 s + 10 s (4 minutos), se mande lo que se mande.</li>
 * </ul>
 */
public record WodDefinition(String title, String strength, WodFormat format, Integer timeCapSeconds, Integer rounds,
                            List<WodMovement> movements) {

    public static final int TITLE_MAX = 80;
    public static final int STRENGTH_MAX = 300;
    public static final int MAX_MOVEMENTS = 12;
    public static final int MIN_CAP_SECONDS = 60;
    /** Una hora: más no es un WOD, es una sesión entera. */
    public static final int MAX_CAP_SECONDS = 3600;
    public static final int MAX_ROUNDS = 50;

    public WodDefinition {
        Guard.notNull(format, "format");
        title = title == null || title.isBlank() ? null : Guard.length(title.strip(), "title", 1, TITLE_MAX);
        strength = strength == null || strength.isBlank() ? null
                : Guard.length(strength.strip(), "strength", 1, STRENGTH_MAX);
        Guard.notNull(movements, "movements");
        if (movements.isEmpty() || movements.size() > MAX_MOVEMENTS) {
            throw new FieldValidationException("movements", "OUT_OF_RANGE",
                    "a WOD needs between 1 and " + MAX_MOVEMENTS + " movements");
        }
        movements = List.copyOf(movements);
        switch (format) {
            case FOR_TIME -> {
                rounds = rounds == null ? 1 : Guard.range(rounds, "rounds", 1, MAX_ROUNDS);
                if (timeCapSeconds != null) {
                    Guard.range(timeCapSeconds, "timeCapSeconds", MIN_CAP_SECONDS, MAX_CAP_SECONDS);
                }
            }
            case AMRAP -> {
                Guard.range(Guard.notNull(timeCapSeconds, "timeCapSeconds"), "timeCapSeconds", MIN_CAP_SECONDS,
                        MAX_CAP_SECONDS);
                rounds = null;
            }
            case EMOM -> {
                Guard.range(Guard.notNull(timeCapSeconds, "timeCapSeconds"), "timeCapSeconds", MIN_CAP_SECONDS,
                        MAX_CAP_SECONDS);
                if (timeCapSeconds % 60 != 0) {
                    throw new FieldValidationException("timeCapSeconds", "INVALID", "EMOM lasts whole minutes");
                }
                rounds = timeCapSeconds / 60;
            }
            case TABATA -> {
                timeCapSeconds = WodFormat.TABATA_SECONDS;
                rounds = WodFormat.TABATA_ROUNDS;
            }
        }
    }

    /** La misma pizarra con otro título (el de una plantilla, que pone el cliente en su idioma). */
    public WodDefinition titled(String newTitle) {
        return new WodDefinition(newTitle, strength, format, timeCapSeconds, rounds, movements);
    }

    /**
     * Huella de lo que se hace (formato, límite, rondas y movimientos; ni el título ni la fuerza): dos WOD con la
     * misma huella son «el mismo» y comparten mejor marca.
     */
    public String signature() {
        return format + "|" + timeCapSeconds + "|" + rounds + "|"
                + movements.stream().map(WodMovement::signaturePart).collect(Collectors.joining(";"));
    }
}
