package com.synaptixfit.domain.model.wod;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.text.Normalizer;
import java.util.Locale;

/**
 * Un movimiento de un WOD: «10 sentadillas», «400 m corriendo», «12 balanceos con pesa rusa (16 kg)».
 *
 * @param code     movimiento de una plantilla de ejemplo ({@code AIR_SQUAT}); el cliente lo nombra en cada idioma
 * @param name     nombre que escribió la persona; obligatorio si no hay código
 * @param quantity cuánto; nulo = «las que puedas» (Tabata)
 * @param rxKg     peso tal cual está escrito (opcional)
 * @param scaledKg peso adaptado (opcional)
 */
public record WodMovement(String code, String name, Integer quantity, WodUnit unit, Double rxKg, Double scaledKg) {

    public static final int NAME_MAX = 60;
    public static final int CODE_MAX = 30;
    public static final int MAX_QUANTITY = 10_000;
    public static final double MIN_KG = 0.5;
    public static final double MAX_KG = 500;

    public WodMovement {
        code = code == null || code.isBlank() ? null : code.strip();
        name = name == null || name.isBlank() ? null : name.strip().replaceAll("\\s+", " ");
        if (code == null && name == null) {
            throw new FieldValidationException("movements", "REQUIRED", "a movement needs a name");
        }
        if (name != null) {
            Guard.length(name, "movements", 1, NAME_MAX);
        }
        if (code != null) {
            Guard.length(code, "movements", 1, CODE_MAX);
        }
        if (quantity != null) {
            Guard.range(quantity, "movements", 1, MAX_QUANTITY);
        }
        unit = unit == null ? WodUnit.REPS : unit;
        if (rxKg != null) {
            Guard.range(rxKg, "movements", MIN_KG, MAX_KG);
        }
        if (scaledKg != null) {
            Guard.range(scaledKg, "movements", MIN_KG, MAX_KG);
        }
    }

    public static WodMovement template(String code, Integer quantity, WodUnit unit) {
        return new WodMovement(code, null, quantity, unit, null, null);
    }

    public static WodMovement template(String code, Integer quantity, double rxKg, double scaledKg) {
        return new WodMovement(code, null, quantity, WodUnit.REPS, rxKg, scaledKg);
    }

    /**
     * Cómo cuenta para saber si dos WOD son el mismo: el código si viene de una plantilla (así da igual el idioma) o
     * el nombre sin tildes ni mayúsculas, con su cantidad, su unidad y sus pesos.
     */
    String signaturePart() {
        String who = code != null ? "#" + code : Normalizer.normalize(name, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
        return who + ":" + quantity + ":" + unit + ":" + rxKg + ":" + scaledKg;
    }
}
