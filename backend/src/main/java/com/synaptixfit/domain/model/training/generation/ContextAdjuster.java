package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.neuro.CrossRegulation;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Adapta la semana tipo al contexto académico, físico y al check-in del día.
 *
 * <p>Factor de carga total (FCT, 0-1): horas de estudio/30 (25 %), estrés/10 (25 %),
 * evaluaciones/5 (15 %), déficit de sueño sobre 8 h (15 %) y, con check-in, dolor (10 %) y falta de
 * energía (10 %). El volumen se reduce con la regulación cruzada ({@link CrossRegulation#modifiedVolume})
 * cuando hay un examen a 60 días o menos, en modo exámenes, con FCT alto, energía baja, sin racha,
 * perdiendo peso, con fatiga, sin ganas de entrenar o con mal sueño; aumenta si se gana peso.
 *
 * <p>El factor de volumen se aplica al número de ejercicios por día (el sistema heredado lo
 * calculaba pero nunca lo aplicaba) y el delta de series y descanso a cada ejercicio.
 */
public final class ContextAdjuster {

    private static final double STUDY_HOURS_THRESHOLD = 30;
    private static final double SLEEP_HOURS_THRESHOLD = 8;

    private static final Map<String, List<String>> PAIN_ZONE_MUSCLES = Map.of(
            "piernas", List.of("Cuádriceps", "Isquiotibiales", "Glúteo mayor", "Glúteo medio", "Aductores",
                    "Abductores", "Gemelos", "Sóleo", "Tibial anterior"),
            "espalda", List.of("Dorsal ancho", "Romboides", "Trapecio superior", "Trapecio medio",
                    "Trapecio inferior", "Erectores espinales"),
            "hombros", List.of("Deltoides anterior", "Deltoides medio", "Deltoides posterior"),
            "brazos", List.of("Bíceps braquial", "Tríceps braquial", "Braquial", "Braquiorradial"),
            "pecho", List.of("Pectoral mayor", "Pectoral menor", "Serrato anterior"),
            "core", List.of("Recto abdominal", "Oblicuos", "Transverso abdominal"));

    private ContextAdjuster() {
    }

    /** Ajuste calculado. */
    public record Adjustment(double volumeFactor, int deltaSets, int deltaRest, double totalLoadFactor,
                             List<String> reasons) {
        public Adjustment {
            reasons = List.copyOf(reasons);
        }

        public boolean isNeutral() {
            return volumeFactor == 1.0 && deltaSets == 0 && deltaRest == 0;
        }
    }

    public static double totalLoadFactor(AcademicContext ac, DailyCheckIn checkIn) {
        double fct = 0;
        fct += clamp01(ac.realStudyHours() / STUDY_HOURS_THRESHOLD) * 0.25;
        fct += clamp01(ac.stressLevel() / 10.0) * 0.25;
        fct += clamp01(ac.evaluationsThisWeek() / 5.0) * 0.15;
        fct += clamp01((SLEEP_HOURS_THRESHOLD - ac.averageSleepHours()) / SLEEP_HOURS_THRESHOLD) * 0.15;
        if (checkIn != null) {
            fct += clamp01((checkIn.soreness() - 1) / 4.0) * 0.10;
            fct += clamp01((6 - checkIn.energy()) / 5.0) * 0.10;
        }
        return clamp01(fct);
    }

    /**
     * Estado energético 0-100 (fórmula heredada): energía 30 %, sueño 25 %, recuperación 20 %, margen
     * cognitivo 15 % y estrés 10 %, con penalizaciones por sueño, dolor o energía muy bajos. Sin
     * check-in vale 50.
     */
    public static double energyState(DailyCheckIn checkIn, AcademicContext ac) {
        if (checkIn == null) {
            return 50;
        }
        double energy = checkIn.energy() / 5.0 * 100;
        double sleep = checkIn.sleepQuality() / 5.0 * 100;
        double recovery = (5 - checkIn.soreness()) / 5.0 * 100;
        double cognitive = clamp01(1.0 - ac.realStudyHours() / 40.0) * 100;
        double stress = (10.0 - ac.stressLevel()) / 10.0 * 100;
        double base = energy * 0.30 + sleep * 0.25 + recovery * 0.20 + cognitive * 0.15 + stress * 0.10;
        double gateSleep = checkIn.sleepQuality() <= 1 ? 0.40 : checkIn.sleepQuality() == 2 ? 0.70 : 1.0;
        double gateRecovery = checkIn.soreness() >= 4 ? 0.60 : checkIn.soreness() == 3 ? 0.85 : 1.0;
        double gateEnergy = checkIn.energy() <= 1 ? 0.50 : checkIn.energy() == 2 ? 0.75 : 1.0;
        return Math.max(0, Math.min(100, base * gateSleep * gateRecovery * gateEnergy));
    }

    public static Adjustment compute(AcademicContext ac, PhysiologicalContext physio, DailyCheckIn checkIn) {
        double factor = 1.0;
        int deltaSets = 0;
        int deltaRest = 0;
        List<String> reasons = new ArrayList<>();
        double fct = totalLoadFactor(ac, checkIn);

        if (ac.daysToNextExam() != null && ac.daysToNextExam() <= 60) {
            double load = ac.cognitiveLoad() != null ? ac.cognitiveLoad() : fct;
            double vMod = Math.max(0.4, Math.min(1.0,
                    CrossRegulation.modifiedVolume(1.0, load, 1.0, ac.daysToNextExam())));
            if (vMod < factor) {
                factor = vMod;
                reasons.add("Regulación cruzada: examen en " + ac.daysToNextExam() + " días");
            }
        }
        if (ac.examWithinSevenDays()) {
            factor *= 0.70;
            deltaSets -= 1;
            deltaRest += 30;
            reasons.add("Modo exámenes activo");
        }
        if (fct > 0.7) {
            factor *= 0.50;
            deltaSets -= 1;
            deltaRest += 30;
            reasons.add(String.format(Locale.ROOT, "Carga total muy alta (FCT %.2f)", fct));
        } else if (fct > 0.5) {
            factor *= 0.80;
            deltaSets -= 1;
            deltaRest += 20;
            reasons.add(String.format(Locale.ROOT, "Carga total alta (FCT %.2f)", fct));
        } else if (fct > 0.3) {
            factor *= 0.90;
            deltaRest += 15;
            reasons.add(String.format(Locale.ROOT, "Carga total moderada (FCT %.2f)", fct));
        }
        double energy = energyState(checkIn, ac);
        if (energy < 30) {
            factor *= 0.40;
            deltaRest += 60;
            reasons.add(String.format(Locale.ROOT, "Estado energético crítico (%.0f/100), sesión de recuperación", energy));
        } else if (energy < 50) {
            factor *= 0.75;
            deltaRest += 20;
            reasons.add(String.format(Locale.ROOT, "Estado energético bajo (%.0f/100), menos intensidad", energy));
        }
        if (ac.acwr() != null && ac.acwr() > 1.5) {
            factor *= 0.85;
            reasons.add(String.format(Locale.ROOT, "Carga física aguda alta (ACWR %.2f)", ac.acwr()));
        }
        if (physio.streak() == 0) {
            factor *= 0.75;
            deltaSets -= 1;
            reasons.add("Sin racha activa, rutina de reenganche");
        }
        if (physio.losingWeight()) {
            factor *= 0.85;
            deltaSets -= 1;
            reasons.add("Tendencia de pérdida de peso, preservar masa muscular");
        }
        if (physio.gainingWeight()) {
            factor *= 1.10;
            deltaSets += 1;
            reasons.add("Tendencia de ganancia de peso, más volumen");
        }
        if (checkIn != null) {
            if (checkIn.requiresAdaptation()) {
                factor *= 0.80;
                deltaSets -= 1;
                reasons.add("Fatiga alta (" + checkIn.fatigueScore() + "/100)");
            }
            if (!checkIn.readyToTrain()) {
                factor *= 0.60;
                deltaSets -= 2;
                deltaRest += 30;
                reasons.add("No te sientes listo para entrenar");
            }
            if (checkIn.sleepQuality() <= 2) {
                factor *= 0.70;
                deltaRest += 30;
                reasons.add("Sueño deficiente (" + checkIn.sleepQuality() + "/5)");
            }
            if (checkIn.stress() >= 4) {
                deltaRest += 15;
                reasons.add("Estrés elevado (" + checkIn.stress() + "/5), movilidad recomendada");
            }
            if (checkIn.energy() <= 2) {
                factor *= 0.75;
                reasons.add("Energía baja (" + checkIn.energy() + "/5)");
            }
            if (checkIn.soreness() >= 4) {
                factor *= 0.85;
                reasons.add("Dolor muscular alto (" + checkIn.soreness() + "/5)");
            }
        }
        return new Adjustment(Math.max(0.3, Math.min(1.5, factor)), Math.max(-3, Math.min(2, deltaSets)),
                Math.max(-30, Math.min(60, deltaRest)), fct, reasons);
    }

    /** Aplica el ajuste: menos ejercicios por día según el factor y delta de series/descanso por ejercicio. */
    public static List<ProposedDay> apply(List<ProposedDay> days, Adjustment adj, GoalParameters params) {
        if (adj.isNeutral()) {
            return days;
        }
        return days.stream().map(day -> {
            List<ProposedExercise> exercises = day.exercises();
            if (adj.volumeFactor() < 1.0 && exercises.size() > 2) {
                int keep = Math.max(2, (int) Math.ceil(exercises.size() * adj.volumeFactor()));
                exercises = exercises.subList(0, Math.min(keep, exercises.size()));
            }
            return day.withExercises(exercises.stream().map(e -> {
                ExerciseParameters p = e.parameters();
                int sets = Math.max(1, Math.min(params.setsMax() + 1, p.sets() + adj.deltaSets()));
                int rest = Math.max(params.restMin(), Math.min(params.restMax() + 60, p.restSeconds() + adj.deltaRest()));
                return e.withParameters(RoutineRuleEngine.withSets(ExerciseParameters.clamped(p.sets(), p.reps(), rest,
                        p.weightKg(), p.weightsKg(), p.targetDurationSeconds(), p.distanceMeters(),
                        p.isometricSeconds()), sets));
            }).toList());
        }).toList();
    }

    /**
     * Filtro fino por check-in: quita ejercicios de los músculos de las zonas con dolor; con dolor ≥ 4
     * quita los muy compuestos (3+ secundarios); con estrés ≥ 4 añade uno de movilidad si no hay.
     */
    public static List<ProposedDay> filterByCheckIn(List<ProposedDay> days, DailyCheckIn checkIn,
                                                    List<Exercise> catalog) {
        if (checkIn == null) {
            return days;
        }
        Map<UUID, Exercise> byId = catalog.stream().collect(Collectors.toMap(Exercise::id, Function.identity(), (a, b) -> a));
        Set<String> avoid = checkIn.painZones().stream()
                .flatMap(z -> PAIN_ZONE_MUSCLES.getOrDefault(ExerciseEligibility.normalize(z), List.of()).stream())
                .map(ExerciseEligibility::normalize).collect(Collectors.toSet());
        boolean excludeHeavyCompounds = checkIn.soreness() >= 4;
        Optional<Exercise> mobility = catalog.stream().filter(Exercise::active)
                .filter(e -> e.modality() == Modality.MOBILITY).min(Comparator.comparing(Exercise::name));
        return days.stream().map(day -> {
            List<ProposedExercise> kept = day.exercises().stream().filter(p -> {
                Exercise e = byId.get(p.exerciseId());
                if (e == null) {
                    return true;
                }
                boolean painful = e.targetMuscleNames().stream().map(ExerciseEligibility::normalize).anyMatch(avoid::contains);
                boolean heavy = excludeHeavyCompounds && e.secondaryMuscles().size() >= 3;
                return !painful && !heavy;
            }).collect(Collectors.toCollection(ArrayList::new));
            if (checkIn.stress() >= 4 && mobility.isPresent()) {
                boolean hasMobility = kept.stream().map(p -> byId.get(p.exerciseId()))
                        .anyMatch(e -> e != null && e.modality() == Modality.MOBILITY);
                if (!hasMobility) {
                    Exercise m = mobility.get();
                    kept.add(new ProposedExercise(m.id(), m.name(), ExerciseParameters.clamped(2, 10, 30, null, null,
                            m.measuredBy(MeasurementType.TIME) && !m.isIsometric() ? 600 : null, null,
                            m.isIsometric() ? 30 : null)));
                }
            }
            return day.withExercises(kept);
        }).toList();
    }

    private static double clamp01(double v) {
        return Math.max(0, Math.min(1, v));
    }
}
