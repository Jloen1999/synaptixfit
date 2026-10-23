package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Motor de reglas deterministas: elige el split según los días disponibles y el nivel, asigna
 * grupos musculares a cada día y selecciona ejercicios del catálogo (filtrado por nivel,
 * equipamiento, modalidad del objetivo, músculos del día, ejercicios recientes y biometría),
 * puntuados por afinidad con el objetivo y equilibrando compuestos (≈60 %) y aislados.
 */
public final class RoutineRuleEngine {

    /** Tipo de división semanal. */
    public enum Split {
        FULL_BODY("Full-Body"), UPPER_LOWER("Upper/Lower"), PUSH_PULL_LEGS("Push/Pull/Legs");

        private final String label;

        Split(String label) {
            this.label = label;
        }

        public String label() {
            return label;
        }
    }

    /** Semana tipo resultante. */
    public record WeekTemplate(Split split, GoalParameters parameters, List<ProposedDay> days) {
        public WeekTemplate {
            days = List.copyOf(days);
        }

        public int exerciseCount() {
            return days.stream().mapToInt(d -> d.exercises().size()).sum();
        }
    }

    private record DayMuscles(int dayNumber, List<String> muscles) {
    }

    static final List<String> ALL = List.of("Pectoral mayor", "Deltoides anterior", "Deltoides medio",
            "Tríceps braquial", "Dorsal ancho", "Romboides", "Bíceps braquial", "Cuádriceps", "Isquiotibiales",
            "Glúteo mayor", "Recto abdominal", "Oblicuos", "Erectores espinales");
    static final List<String> UPPER = List.of("Pectoral mayor", "Deltoides anterior", "Deltoides medio",
            "Deltoides posterior", "Tríceps braquial", "Dorsal ancho", "Romboides", "Bíceps braquial",
            "Trapecio superior", "Braquial", "Braquiorradial");
    static final List<String> LOWER = List.of("Cuádriceps", "Isquiotibiales", "Glúteo mayor", "Recto abdominal",
            "Oblicuos", "Erectores espinales");
    static final List<String> PUSH = List.of("Pectoral mayor", "Deltoides anterior", "Deltoides medio",
            "Tríceps braquial");
    static final List<String> PULL = List.of("Dorsal ancho", "Romboides", "Deltoides posterior", "Bíceps braquial",
            "Trapecio superior", "Braquial");

    private RoutineRuleEngine() {
    }

    public static Split chooseSplit(int daysPerWeek, ActivityLevel level) {
        if (daysPerWeek >= 5) {
            return Split.PUSH_PULL_LEGS;
        }
        if (daysPerWeek >= 4 && level.rank() >= 2) {
            return Split.UPPER_LOWER;
        }
        return Split.FULL_BODY;
    }

    /** Ajustes biométricos: IMC &gt; 30 intensidad ≤ 0,65; edad &gt; 50 intensidad ≤ 0,70 y 8+ reps; menor de 18 ≤ 0,75. */
    public static GoalParameters adjustForBiometrics(GoalParameters params, TrainingProfile profile) {
        double intensity = params.relativeIntensity();
        int repsMin = params.repsMin();
        int repsMax = params.repsMax();
        if (profile.bmi() > 30) {
            intensity = Math.min(intensity, 0.65);
        }
        if (profile.age() > 50) {
            intensity = Math.min(intensity, 0.70);
            repsMin = Math.max(repsMin, 8);
            repsMax = Math.max(repsMax, repsMin);
        }
        if (profile.age() < 18) {
            intensity = Math.min(intensity, 0.75);
        }
        return params.withIntensityAndReps(intensity, repsMin, repsMax);
    }

    public static WeekTemplate generate(TrainingProfile profile, List<Exercise> catalog, GoalParameters baseParams,
                                        TrainingHistory history) {
        GoalParameters params = adjustForBiometrics(baseParams, profile);
        Split split = chooseSplit(profile.daysPerWeek(), profile.activityLevel());
        List<Integer> dayNumbers = profile.trainingDayNumbers();
        List<ProposedDay> days = new ArrayList<>();
        for (int i = 0; i < dayNumbers.size(); i++) {
            DayMuscles dm = new DayMuscles(dayNumbers.get(i), musclesFor(split, i));
            List<Exercise> pool = filter(catalog, profile, params, dm, history.recentExerciseNames());
            if (pool.isEmpty()) {
                pool = filter(catalog, profile, params, dm, Set.of());
            }
            pool = rank(pool, params, profile);
            List<ProposedExercise> selected = selectBalanced(pool, params, profile);
            selected = biometricAdjustments(selected, profile, params, catalog, dm);
            days.add(new ProposedDay(dm.dayNumber(), dayName(i + 1, dm.muscles()), selected));
        }
        return new WeekTemplate(split, params, days);
    }

    private static List<String> musclesFor(Split split, int index) {
        return switch (split) {
            case FULL_BODY -> ALL;
            case UPPER_LOWER -> index % 2 == 0 ? UPPER : LOWER;
            case PUSH_PULL_LEGS -> switch (index % 3) {
                case 0 -> PUSH;
                case 1 -> PULL;
                default -> LOWER;
            };
        };
    }

    /** Nombre del día según los grupos que trabaja: «D1 · Empuje», «D2 · Full-Body»… */
    public static String dayName(int position, List<String> muscles) {
        Set<String> m = muscles.stream().map(ExerciseEligibility::normalize).collect(Collectors.toSet());
        boolean push = m.stream().anyMatch(x -> x.contains("pectoral") || x.contains("deltoides anterior")
                || x.contains("deltoides medio") || x.contains("triceps"));
        boolean pull = m.stream().anyMatch(x -> x.contains("dorsal") || x.contains("biceps")
                || x.contains("romboides") || x.contains("trapecio"));
        boolean legs = m.stream().anyMatch(x -> x.contains("cuadriceps") || x.contains("isquiotibiales")
                || x.contains("gluteo"));
        String prefix = "D" + position + " · ";
        if (push && pull && legs) {
            return prefix + "Full-Body";
        }
        List<String> parts = new ArrayList<>();
        if (push) {
            parts.add("Empuje");
        }
        if (pull) {
            parts.add("Tracción");
        }
        if (legs) {
            parts.add("Pierna");
        }
        return prefix + (parts.isEmpty() ? "Entrenamiento" : String.join(" + ", parts));
    }

    private static List<Exercise> filter(List<Exercise> catalog, TrainingProfile profile, GoalParameters params,
                                         DayMuscles dm, Set<String> recentNames) {
        Set<String> dayMuscles = dm.muscles().stream().map(ExerciseEligibility::normalize).collect(Collectors.toSet());
        return catalog.stream()
                .filter(e -> ExerciseEligibility.eligible(e, profile))
                .filter(e -> params.modalities().contains(e.modality()))
                .filter(e -> e.targetMuscleNames().stream().map(ExerciseEligibility::normalize)
                        .anyMatch(dayMuscles::contains))
                .filter(e -> !recentNames.contains(e.name().toLowerCase(Locale.ROOT)))
                .toList();
    }

    static List<Exercise> rank(List<Exercise> pool, GoalParameters params, TrainingProfile profile) {
        return pool.stream()
                .sorted(Comparator.comparingDouble((Exercise e) -> -score(e, params, profile))
                        .thenComparing(Exercise::name))
                .toList();
    }

    /** Afinidad 0-1 con el objetivo: finalidad (40 %), compuesto (25 %), dificultad (20 %), versatilidad y biometría. */
    static double score(Exercise e, GoalParameters params, TrainingProfile profile) {
        double score = 0;
        if (!e.purposes().isEmpty()) {
            long matches = e.purposes().stream().filter(p -> p.equalsIgnoreCase(params.goal().label())).count();
            score += (double) matches / e.purposes().size() * 0.40;
        }
        if (params.prioritizeCompound() && e.secondaryMuscles().size() >= 2) {
            score += 0.25;
        }
        score += difficultyScore(e.difficulty(), params.goal()) * 0.20;
        if (e.purposes().size() >= 2) {
            score += 0.10;
        }
        if (e.purposes().size() >= 3) {
            score += 0.05;
        }
        if (profile != null) {
            if (profile.bmi() < 18.5 && e.hasPurpose(TrainingGoal.HYPERTROPHY)) {
                score += 0.10;
            }
            if (profile.age() < 18 && e.equipmentNames().stream()
                    .anyMatch(eq -> ExerciseEligibility.normalize(eq).contains("peso corporal"))) {
                score += 0.15;
            }
        }
        return Math.max(0, Math.min(1, score));
    }

    private static double difficultyScore(Difficulty d, TrainingGoal goal) {
        return switch (goal) {
            case MAX_STRENGTH, POWER -> d == Difficulty.ADVANCED ? 1.0 : d == Difficulty.INTERMEDIATE ? 0.4 : 0.0;
            case MOBILITY, STABILITY -> d == Difficulty.BEGINNER ? 1.0 : d == Difficulty.INTERMEDIATE ? 0.6 : 0.3;
            default -> d == Difficulty.INTERMEDIATE ? 1.0 : d == Difficulty.BEGINNER ? 0.5 : 0.7;
        };
    }

    private static List<ProposedExercise> selectBalanced(List<Exercise> pool, GoalParameters params,
                                                         TrainingProfile profile) {
        List<Exercise> compounds = pool.stream().filter(Exercise::isCompound).toList();
        List<Exercise> isolated = pool.stream().filter(e -> !e.isCompound()).toList();
        LinkedHashSet<Exercise> selected = new LinkedHashSet<>();
        Set<String> usedPrimaries = new HashSet<>();
        int maxCompounds = (int) Math.ceil(params.exercisesPerDay() * 0.6);
        int taken = 0;
        for (Exercise e : compounds) {
            if (taken >= maxCompounds) {
                break;
            }
            if (takeDistinctPrimary(e, selected, usedPrimaries)) {
                taken++;
            }
        }
        for (Exercise e : isolated) {
            if (selected.size() >= params.exercisesPerDay()) {
                break;
            }
            takeDistinctPrimary(e, selected, usedPrimaries);
        }
        for (Exercise e : pool) {
            if (selected.size() >= params.exercisesPerDay()) {
                break;
            }
            selected.add(e);
        }
        return selected.stream().limit(params.exercisesPerDay()).map(e -> toProposed(e, params, profile)).toList();
    }

    private static boolean takeDistinctPrimary(Exercise e, Set<Exercise> selected, Set<String> usedPrimaries) {
        String primary = e.targetMuscles().isEmpty() ? "" : ExerciseEligibility.normalize(e.targetMuscles().getFirst().name());
        if (!primary.isEmpty() && usedPrimaries.contains(primary)) {
            return false;
        }
        selected.add(e);
        usedPrimaries.add(primary);
        return true;
    }

    /** Parámetros iniciales de un ejercicio: puntos medios del objetivo, tiempo/distancia según nivel y peso estimado. */
    static ProposedExercise toProposed(Exercise e, GoalParameters params, TrainingProfile profile) {
        int level = profile.activityLevel().rank();
        boolean usesTime = e.measuredBy(MeasurementType.TIME);
        boolean usesDistance = e.measuredBy(MeasurementType.DISTANCE);
        boolean isometric = e.isIsometric();
        boolean usesWeight = e.measuredBy(MeasurementType.WEIGHT) || e.modality() == Modality.STRENGTH;
        int secondsPerExercise = params.exercisesPerDay() > 0
                ? profile.minutesPerSession() * 60 / params.exercisesPerDay() : 600;
        double levelFactor = 0.6 + level * 0.15;

        Integer duration = usesTime && !isometric
                ? clamp((int) Math.round(secondsPerExercise * 0.35 * levelFactor), 120, 3600) : null;
        Integer distance = usesDistance ? clamp((int) Math.round((500 + level * 500) * levelFactor), 200, 10_000) : null;
        Integer iso = isometric ? clamp(15 + level * 15, 10, 120) : null;
        Double weight = null;
        List<Double> perSet = null;
        if (usesWeight && profile.weightKg() > 0 && e.measuredBy(MeasurementType.WEIGHT)) {
            weight = Math.max(1.0, Math.min(300.0,
                    profile.weightKg() * bodyWeightShare(e.name()) * params.relativeIntensity()));
            perSet = ProgressionCalculator.warmupWeights(weight, params.defaultSets());
        }
        return new ProposedExercise(e.id(), e.name(), ExerciseParameters.clamped(params.defaultSets(),
                params.defaultReps(), params.defaultRest(), weight, perSet, duration, distance, iso));
    }

    /** Fracción del peso corporal que se mueve en cada ejercicio (estimación heredada por nombre). */
    static double bodyWeightShare(String exerciseName) {
        String n = ExerciseEligibility.normalize(exerciseName);
        if (n.contains("sentadilla") || n.contains("squat")) {
            return 0.50;
        }
        if (n.contains("peso muerto") || n.contains("deadlift")) {
            return 0.60;
        }
        if (n.contains("press banca") || n.contains("press de banca") || n.contains("bench press")) {
            return 0.35;
        }
        if (n.contains("dominada") || n.contains("pull up")) {
            return 0.80;
        }
        if (n.contains("remo") || n.contains("row")) {
            return 0.30;
        }
        if (n.contains("press militar") || n.contains("overhead press")) {
            return 0.25;
        }
        if (n.contains("curl") || n.contains("biceps")) {
            return 0.10;
        }
        if (n.contains("extension") || n.contains("triceps")) {
            return 0.10;
        }
        if (n.contains("elevacion") || n.contains("lateral")) {
            return 0.05;
        }
        return 0.15;
    }

    private static List<ProposedExercise> biometricAdjustments(List<ProposedExercise> selected, TrainingProfile profile,
                                                               GoalParameters params, List<Exercise> catalog,
                                                               DayMuscles dm) {
        List<ProposedExercise> result = profile.bmi() < 18.5
                ? selected.stream().map(p -> catalog.stream().filter(e -> e.id().equals(p.exerciseId())).findFirst()
                        .filter(e -> e.secondaryMuscles().size() >= 2)
                        .map(e -> p.withParameters(withSets(p.parameters(), p.parameters().sets() + 1)))
                        .orElse(p)).collect(Collectors.toCollection(ArrayList::new))
                : new ArrayList<>(selected);
        if (profile.age() > 50) {
            Set<java.util.UUID> ids = result.stream().map(ProposedExercise::exerciseId).collect(Collectors.toSet());
            boolean hasMobility = catalog.stream().anyMatch(e -> ids.contains(e.id()) && e.modality() == Modality.MOBILITY);
            Set<String> dayMuscles = dm.muscles().stream().map(ExerciseEligibility::normalize).collect(Collectors.toSet());
            if (!hasMobility) {
                catalog.stream()
                        .filter(e -> e.modality() == Modality.MOBILITY)
                        .filter(e -> ExerciseEligibility.eligible(e, profile))
                        .filter(e -> e.targetMuscleNames().stream().map(ExerciseEligibility::normalize)
                                .anyMatch(dayMuscles::contains))
                        .min(Comparator.comparing(Exercise::name))
                        .ifPresent(e -> result.add(new ProposedExercise(e.id(), e.name(), ExerciseParameters.clamped(
                                params.defaultSets(), params.defaultReps(), params.defaultRest(), null, null,
                                e.measuredBy(MeasurementType.TIME) && !e.isIsometric() ? 600 : null,
                                e.measuredBy(MeasurementType.DISTANCE) ? 1000 : null,
                                e.isIsometric() ? 30 : null))));
            }
        }
        return result;
    }

    static ExerciseParameters withSets(ExerciseParameters p, int sets) {
        List<Double> perSet = p.weightKg() != null && p.weightKg() > 0
                ? ProgressionCalculator.warmupWeights(p.weightKg(), sets) : p.weightsKg();
        return ExerciseParameters.clamped(sets, p.reps(), p.restSeconds(), p.weightKg(), perSet,
                p.targetDurationSeconds(), p.distanceMeters(), p.isometricSeconds());
    }

    private static int clamp(int v, int min, int max) {
        return Math.max(min, Math.min(max, v));
    }
}
