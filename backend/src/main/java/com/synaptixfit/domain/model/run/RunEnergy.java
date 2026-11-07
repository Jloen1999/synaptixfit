package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.neuro.ExerciseEnergy;
import com.synaptixfit.domain.model.planner.ActivityKind;

/**
 * Gasto calórico de una carrera, andando o en bici (formulas.md, «Carreras con GPS»): {@code kcal = MET · kg · h}
 * con las horas en movimiento, igual que {@link ExerciseEnergy}.
 *
 * <ul>
 *   <li>Correr y andar: ecuaciones metabólicas del ACSM (<i>Guidelines for Exercise Testing and Prescription</i>,
 *   11.ª ed., 2021) en llano: VO₂ = 3,5 + 0,2·v al correr y 3,5 + 0,1·v al andar (v en m/min, VO₂ en
 *   ml·kg⁻¹·min⁻¹), y MET = VO₂ ÷ 3,5.</li>
 *   <li>Bici: MET por velocidad del <i>Compendium of Physical Activities</i> (códigos 01010-01050).</li>
 * </ul>
 */
public final class RunEnergy {

    private RunEnergy() {
    }

    public static double met(ActivityKind kind, double speedKmh) {
        double metersPerMinute = speedKmh * 1000 / 60;
        return switch (kind) {
            case BIKE -> bikeMet(speedKmh);
            case WALK -> (3.5 + 0.1 * metersPerMinute) / 3.5;
            default -> (3.5 + 0.2 * metersPerMinute) / 3.5;
        };
    }

    private static double bikeMet(double speedKmh) {
        if (speedKmh < 16) {
            return 4.0;
        }
        if (speedKmh < 19) {
            return 6.8;
        }
        if (speedKmh < 22) {
            return 8.0;
        }
        if (speedKmh < 25) {
            return 10.0;
        }
        return 12.0;
    }

    /** @param weightKg peso del perfil; sin él, el de referencia de {@link ExerciseEnergy} */
    public static int kcal(ActivityKind kind, RunMetrics metrics, Double weightKg) {
        if (metrics.movingSeconds() <= 0) {
            return 0;
        }
        return (int) Math.round(ExerciseEnergy.calories(met(kind, metrics.speedKmh()), weightKg,
                metrics.movingSeconds()));
    }
}
