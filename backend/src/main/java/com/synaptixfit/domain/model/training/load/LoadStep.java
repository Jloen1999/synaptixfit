package com.synaptixfit.domain.model.training.load;

import java.util.List;

/**
 * Escalones de peso según el material (ADR 0054, {@code formulas.md}): la barra va de 2,5 en 2,5 kg (barra vacía,
 * 20 kg, como mínimo) y sube 2,5 kg en tren superior y 5 kg en pierna o cadera; las mancuernas, de 2 en 2 kg por
 * mano (mínimo 2); la pesa rusa salta a la siguiente que existe; en máquina o polea, una placa (≈ 5 kg). Sin perfil
 * conocido se sube 2,5 kg. Redondear siempre hacia abajo: un peso que no existe se cambia por el de debajo.
 */
public final class LoadStep {

    public static final double BARBELL_KG = 20;
    public static final double DUMBBELL_MIN_KG = 2;
    public static final double PLATE_KG = 5;
    public static final double GENERIC_KG = 2.5;
    /** Pesas rusas habituales en un gimnasio o en casa. */
    public static final List<Double> KETTLEBELLS = List.of(4.0, 6.0, 8.0, 10.0, 12.0, 16.0, 20.0, 24.0, 28.0, 32.0);

    private LoadStep() {
    }

    /** Cuánto se sube de una vez; nulo si el ejercicio no lleva kilos (peso corporal, gomas). */
    public static Double increment(LoadProfile profile) {
        if (profile == null) {
            return GENERIC_KG;
        }
        return switch (profile.type()) {
            case BARBELL -> profile.lowerBody() ? 5.0 : 2.5;
            case DUMBBELL_PAIR, DUMBBELL_SINGLE -> 2.0;
            case KETTLEBELL -> null;
            case MACHINE, CABLE -> PLATE_KG;
            case BODYWEIGHT, BAND -> null;
        };
    }

    /** El escalón siguiente; el mismo peso si el material no lo permite. */
    public static double up(double kg, LoadProfile profile) {
        if (profile != null && profile.type() == LoadType.KETTLEBELL) {
            return KETTLEBELLS.stream().filter(k -> k > kg).findFirst().orElse(kg);
        }
        Double step = increment(profile);
        return step == null ? kg : floor(kg + step, profile);
    }

    /** El escalón anterior, sin bajar del mínimo del material. */
    public static double down(double kg, LoadProfile profile) {
        if (profile != null && profile.type() == LoadType.KETTLEBELL) {
            return KETTLEBELLS.reversed().stream().filter(k -> k < kg).findFirst().orElse(kg);
        }
        Double step = increment(profile);
        if (step == null || kg - step <= 0) {
            return kg;
        }
        return Math.max(minimum(profile), floor(kg - step, profile));
    }

    /** Baja un {@code percent} % y redondea hacia abajo al material, sin bajar del mínimo. */
    public static double reduce(double kg, double percent, LoadProfile profile) {
        double target = kg * (1 - percent / 100.0);
        return Math.max(Math.min(kg, minimum(profile)), floor(target, profile));
    }

    /** El peso que existe en ese material igual o por debajo de {@code kg} (nunca por debajo del mínimo). */
    public static double floor(double kg, LoadProfile profile) {
        if (profile == null) {
            return Math.floor(kg * 2) / 2.0;
        }
        return switch (profile.type()) {
            case BARBELL -> Math.max(BARBELL_KG, Math.floor(kg / 2.5) * 2.5);
            case DUMBBELL_PAIR, DUMBBELL_SINGLE -> Math.max(DUMBBELL_MIN_KG, Math.floor(kg / 2) * 2);
            case KETTLEBELL -> KETTLEBELLS.reversed().stream().filter(k -> k <= kg).findFirst()
                    .orElse(KETTLEBELLS.getFirst());
            case MACHINE, CABLE, BODYWEIGHT, BAND -> Math.floor(kg * 2) / 2.0;
        };
    }

    /** El peso más bajo que existe en ese material. */
    public static double minimum(LoadProfile profile) {
        if (profile == null) {
            return 0;
        }
        return switch (profile.type()) {
            case BARBELL -> BARBELL_KG;
            case DUMBBELL_PAIR, DUMBBELL_SINGLE -> DUMBBELL_MIN_KG;
            case KETTLEBELL -> KETTLEBELLS.getFirst();
            case MACHINE, CABLE, BODYWEIGHT, BAND -> 0;
        };
    }
}
