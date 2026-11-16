package com.synaptixfit.domain.model.training.load;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Cómo se carga un ejercicio y su peso de partida (tabla {@code cargas_iniciales_ejercicio}, ADR 0054): la fracción
 * del peso corporal que se propone a quien empieza, el peso fijo si no se conoce el peso corporal, el tope del
 * primer día y si es de pierna o cadera (en barra sube de 5 en 5 kg en vez de 2,5).
 *
 * @param bodyWeightFraction kg totales (o por mano en mancuernas) por kg de peso corporal; nula si no se estima
 * @param defaultKg          peso de partida sin peso corporal; nulo si no se propone
 * @param capKg              peso máximo que se propone el primer día; nulo sin tope
 */
public record LoadProfile(LoadType type, Double bodyWeightFraction, Double defaultKg, Double capKg,
                          boolean lowerBody) {

    public LoadProfile {
        Guard.notNull(type, "loadType");
        if (bodyWeightFraction != null) {
            Guard.range(bodyWeightFraction, "bodyWeightFraction", 0, 2);
        }
        if (defaultKg != null) {
            Guard.range(defaultKg, "defaultKg", 0, 500);
        }
        if (capKg != null) {
            Guard.range(capKg, "capKg", 0, 500);
        }
    }
}
