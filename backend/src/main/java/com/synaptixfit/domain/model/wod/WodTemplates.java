package com.synaptixfit.domain.model.wod;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * WOD de ejemplo (ADR 0069): sin material o con poco, de 4 a 20 minutos. El nombre de cada plantilla y de cada
 * movimiento lo pone el cliente en cada idioma a partir del código; aquí solo está lo que se hace. Los nombres son
 * propios y neutros: ninguno es el de un entreno registrado por una marca.
 */
public final class WodTemplates {

    /** Una plantilla: código estable y su pizarra (sin título: lo pone el cliente). */
    public record Template(String code, WodDefinition definition) {
    }

    public static final List<Template> ALL = List.of(
            template("TRIPLE_TEN", WodFormat.FOR_TIME, 900, 5,
                    WodMovement.template("AIR_SQUAT", 10, WodUnit.REPS),
                    WodMovement.template("PUSH_UP", 10, WodUnit.REPS),
                    WodMovement.template("SIT_UP", 10, WodUnit.REPS)),
            template("TWELVE_NONSTOP", WodFormat.AMRAP, 720, null,
                    WodMovement.template("BURPEE", 5, WodUnit.REPS),
                    WodMovement.template("AIR_SQUAT", 10, WodUnit.REPS),
                    WodMovement.template("SIT_UP", 15, WodUnit.REPS)),
            template("MINUTE_BY_MINUTE", WodFormat.EMOM, 600, null,
                    WodMovement.template("BURPEE", 5, WodUnit.REPS),
                    WodMovement.template("AIR_SQUAT", 10, WodUnit.REPS)),
            template("FOUR_MINUTES", WodFormat.TABATA, null, null,
                    WodMovement.template("AIR_SQUAT", null, WodUnit.REPS)),
            template("RUN_AND_PUSH", WodFormat.FOR_TIME, 1200, 3,
                    WodMovement.template("RUN", 400, WodUnit.METERS),
                    WodMovement.template("PUSH_UP", 15, WodUnit.REPS),
                    WodMovement.template("LUNGE", 20, WodUnit.REPS)),
            template("TWO_DUMBBELLS", WodFormat.AMRAP, 900, null,
                    WodMovement.template("DUMBBELL_THRUSTER", 10, 15, 7.5),
                    WodMovement.template("DUMBBELL_ROW", 10, 15, 7.5),
                    WodMovement.template("RUN", 200, WodUnit.METERS)),
            template("SWING_CLOCK", WodFormat.EMOM, 720, null,
                    WodMovement.template("KETTLEBELL_SWING", 12, 16, 8)),
            template("LONG_LIST", WodFormat.FOR_TIME, 900, 1,
                    WodMovement.template("JUMP_ROPE", 100, WodUnit.REPS),
                    WodMovement.template("AIR_SQUAT", 40, WodUnit.REPS),
                    WodMovement.template("SIT_UP", 30, WodUnit.REPS),
                    WodMovement.template("PUSH_UP", 20, WodUnit.REPS),
                    WodMovement.template("BURPEE", 10, WodUnit.REPS)));

    private WodTemplates() {
    }

    public static Optional<Template> find(String code) {
        return ALL.stream().filter(t -> t.code().equals(code)).findFirst();
    }

    /** La de ejemplo de un día: van rotando, así cada día enseña una distinta y todo el mundo ve la misma. */
    public static Template ofDay(LocalDate day) {
        return ALL.get((int) Math.floorMod(day.toEpochDay(), (long) ALL.size()));
    }

    private static Template template(String code, WodFormat format, Integer capSeconds, Integer rounds,
                                     WodMovement... movements) {
        return new Template(code, new WodDefinition(null, null, format, capSeconds, rounds, List.of(movements)));
    }
}
