package com.synaptixfit.domain.model.training.load;

/**
 * Con qué se carga un ejercicio (ADR 0054). Decide cómo se redondea un peso al material que existe y cuánto se sube
 * de una vez ({@link LoadStep}); en máquinas, poleas, peso corporal y gomas no se propone un peso de partida.
 */
public enum LoadType {
    /** Barra olímpica de 20 kg con discos de 1,25 kg por lado. */
    BARBELL,
    /** Dos mancuernas: el peso es el de cada mano. */
    DUMBBELL_PAIR,
    /** Una sola mancuerna (sentadilla sumo, hip thrust). */
    DUMBBELL_SINGLE,
    KETTLEBELL,
    MACHINE,
    CABLE,
    BODYWEIGHT,
    BAND;

    /** Máquina o polea: cada marca pesa distinto y las placas no son kilos reales. */
    public boolean machine() {
        return this == MACHINE || this == CABLE;
    }

    /** Sin kilos que mover: se progresa con repeticiones o con la variante. */
    public boolean unloaded() {
        return this == BODYWEIGHT || this == BAND;
    }
}
