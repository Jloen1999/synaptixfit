package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training;

import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PlanIntensity;
import com.synaptixfit.domain.model.training.PlanStatus;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.SessionType;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.ActivityLevel;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/** Traducción entre los enums del dominio y los valores (en español) guardados en la base de datos. */
public final class TrainingDbValues {

    private TrainingDbValues() {
    }

    private static final Map<Difficulty, String> DIFFICULTY = Map.of(Difficulty.BEGINNER, "principiante",
            Difficulty.INTERMEDIATE, "intermedio", Difficulty.ADVANCED, "avanzado");
    private static final Map<Modality, String> MODALITY = Map.of(Modality.STRENGTH, "fuerza",
            Modality.MOBILITY, "movilidad", Modality.METABOLIC, "metabolica", Modality.AEROBIC, "aerobica");
    private static final Map<MeasurementType, String> MEASUREMENT = Map.of(MeasurementType.REPETITIONS, "repeticiones",
            MeasurementType.WEIGHT, "peso", MeasurementType.TIME, "tiempo", MeasurementType.DISTANCE, "distancia",
            MeasurementType.CALORIES, "calorias");
    private static final Map<WeekType, String> WEEK_TYPE = Map.of(WeekType.ADAPTATION, "adaptacion",
            WeekType.LOAD, "carga", WeekType.PEAK, "pico", WeekType.DELOAD, "descarga");
    private static final Map<ProgressStatus, String> DAY_STATUS = Map.of(ProgressStatus.PENDING, "pendiente",
            ProgressStatus.IN_PROGRESS, "en_progreso", ProgressStatus.COMPLETED, "completado",
            ProgressStatus.SKIPPED, "saltado");
    /** Las semanas usan el femenino «completada» y nunca quedan saltadas. */
    private static final Map<ProgressStatus, String> WEEK_STATUS = Map.of(ProgressStatus.PENDING, "pendiente",
            ProgressStatus.IN_PROGRESS, "en_progreso", ProgressStatus.COMPLETED, "completada");
    private static final Map<RoutineStatus, String> ROUTINE_STATUS = Map.of(RoutineStatus.ACTIVE, "activo",
            RoutineStatus.PAUSED, "pausado", RoutineStatus.COMPLETED, "completado", RoutineStatus.ARCHIVED, "archivado");
    private static final Map<SessionType, String> SESSION_TYPE = Map.of(SessionType.FREE, "libre",
            SessionType.ROUTINE, "rutina", SessionType.WEEKLY, "semanal");
    private static final Map<PlanIntensity, String> INTENSITY = Map.of(PlanIntensity.LOW, "baja",
            PlanIntensity.MODERATE, "moderada", PlanIntensity.HIGH, "alta");
    private static final Map<PlanStatus, String> PLAN_STATUS = Map.of(PlanStatus.ACTIVE, "activo",
            PlanStatus.PAUSED, "pausado", PlanStatus.COMPLETED, "completado", PlanStatus.ADJUSTED, "ajustado");
    private static final Map<RecommendationType, String> RECOMMENDATION = Map.of(
            RecommendationType.PROGRESSION, "progresion", RecommendationType.DEGRADATION, "degradacion",
            RecommendationType.DELOAD, "descarga", RecommendationType.VARIANT, "variante",
            RecommendationType.ACADEMIC, "academico");
    private static final Map<ActivityLevel, String> ACTIVITY = Map.of(ActivityLevel.SEDENTARY, "sedentario",
            ActivityLevel.LIGHT, "ligero", ActivityLevel.MODERATE, "moderado", ActivityLevel.HIGH, "alto");

    public static String toDb(Difficulty v) { return DIFFICULTY.get(v); }
    public static String toDb(Modality v) { return MODALITY.get(v); }
    public static String toDb(MeasurementType v) { return MEASUREMENT.get(v); }
    public static String toDb(WeekType v) { return WEEK_TYPE.get(v); }
    public static String dayStatusToDb(ProgressStatus v) { return DAY_STATUS.get(v); }
    public static String weekStatusToDb(ProgressStatus v) { return WEEK_STATUS.get(v); }
    public static String toDb(RoutineStatus v) { return ROUTINE_STATUS.get(v); }
    public static String toDb(SessionType v) { return SESSION_TYPE.get(v); }
    public static String toDb(PlanIntensity v) { return INTENSITY.get(v); }
    public static String toDb(PlanStatus v) { return PLAN_STATUS.get(v); }
    public static String toDb(RecommendationType v) { return RECOMMENDATION.get(v); }

    public static Difficulty difficulty(String db) { return from(DIFFICULTY, db, Difficulty.INTERMEDIATE); }
    public static Modality modality(String db) { return from(MODALITY, db, Modality.STRENGTH); }

    /** {@code categoria} guarda el nombre del enum en minúsculas; nula o desconocida, se deduce de la modalidad. */
    public static ExerciseCategory category(String db) {
        if (db == null || db.isBlank()) {
            return null;
        }
        try {
            return ExerciseCategory.valueOf(db.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public static String toDb(ExerciseCategory v) {
        return v == null ? null : v.name().toLowerCase(Locale.ROOT);
    }
    public static WeekType weekType(String db) { return from(WEEK_TYPE, db, WeekType.LOAD); }
    public static ProgressStatus dayStatus(String db) { return from(DAY_STATUS, db, ProgressStatus.PENDING); }
    public static ProgressStatus weekStatus(String db) { return from(WEEK_STATUS, db, ProgressStatus.PENDING); }
    public static RoutineStatus routineStatus(String db) { return from(ROUTINE_STATUS, db, RoutineStatus.ACTIVE); }
    public static SessionType sessionType(String db) { return from(SESSION_TYPE, db, SessionType.FREE); }
    public static PlanIntensity intensity(String db) { return from(INTENSITY, db, PlanIntensity.MODERATE); }
    public static PlanStatus planStatus(String db) { return from(PLAN_STATUS, db, PlanStatus.ACTIVE); }
    public static RecommendationType recommendationType(String db) {
        return from(RECOMMENDATION, db, RecommendationType.PROGRESSION);
    }
    public static ActivityLevel activityLevel(String db) { return from(ACTIVITY, db, ActivityLevel.LIGHT); }

    /** Tipos de medición; los valores desconocidos se ignoran. */
    public static List<MeasurementType> measurementTypes(String[] db) {
        if (db == null) {
            return List.of();
        }
        Map<String, MeasurementType> inverse = inverse(MEASUREMENT);
        return Arrays.stream(db).map(inverse::get).filter(Objects::nonNull).distinct().toList();
    }

    public static String[] measurementTypesToDb(List<MeasurementType> types) {
        return types.stream().map(MEASUREMENT::get).toArray(String[]::new);
    }

    private static <E> E from(Map<E, String> map, String db, E fallback) {
        if (db == null) {
            return fallback;
        }
        return inverse(map).getOrDefault(db, fallback);
    }

    private static <E> Map<String, E> inverse(Map<E, String> map) {
        return map.entrySet().stream().collect(Collectors.toMap(Map.Entry::getValue, Map.Entry::getKey));
    }
}
