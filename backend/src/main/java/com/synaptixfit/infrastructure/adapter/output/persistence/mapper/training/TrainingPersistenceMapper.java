package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.DailyCheckInEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RecommendationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.SessionSetEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.TrainingSessionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.WeeklyPlanEntity;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Sesiones, check-ins, planes semanales y sugerencias ↔ sus entidades JPA. */
public final class TrainingPersistenceMapper {

    private static final String ADJUSTMENTS = "adjustments";

    private TrainingPersistenceMapper() {
    }

    // ------------------------------------------------------------------ sesiones

    public static TrainingSession toDomain(TrainingSessionEntity e, List<SessionSetEntity> sets) {
        return new TrainingSession(e.getId(), e.getUsuarioId(), e.getRutinaId(), e.getDiaId(),
                TrainingDbValues.sessionType(e.getTipo()), e.getCreadoEn(), e.getCompletadaEn(), e.getDuracionMinutos(),
                e.getRpe(), e.getCaloriasQuemadas(), e.getXpOtorgado(),
                sets.stream().map(TrainingPersistenceMapper::toDomain).toList());
    }

    public static SessionSet toDomain(SessionSetEntity e) {
        return new SessionSet(e.getId(), e.getSeleccionId(), Math.max(1, e.getNumeroSerie()),
                e.getRepeticionesRealizadas(), e.getPesoKg(), e.isCompletada(), Math.max(0, e.getFailedReps()),
                e.getDuracionSegundos(), e.getDistanciaMetros(), e.getEjercicioId());
    }

    public static void copy(TrainingSession s, TrainingSessionEntity e) {
        e.setId(s.id());
        e.setUsuarioId(s.userId());
        e.setRutinaId(s.routineId());
        e.setDiaId(s.dayId());
        e.setTipo(TrainingDbValues.toDb(s.type()));
        e.setCreadoEn(s.startedAt());
        e.setCompletadaEn(s.completedAt());
        e.setDuracionMinutos(s.durationMinutes());
        e.setRpe(s.rpe());
        e.setCaloriasQuemadas(s.calories());
        e.setXpOtorgado(s.xpAwarded());
    }

    public static void copy(SessionSet s, UUID sessionId, SessionSetEntity e) {
        e.setId(s.id());
        e.setSesionId(sessionId);
        e.setSeleccionId(s.plannedExerciseId());
        e.setNumeroSerie(s.setNumber());
        e.setRepeticionesRealizadas(s.repsDone());
        e.setPesoKg(s.weightKg());
        e.setCompletada(s.completed());
        e.setFailedReps(s.failedReps());
        e.setDuracionSegundos(s.durationSeconds());
        e.setDistanciaMetros(s.distanceMeters());
        // Una serie ya guardada conserva su ejercicio aunque su hueco desaparezca de la rutina.
        if (s.exerciseId() != null) {
            e.setEjercicioId(s.exerciseId());
        }
    }

    // ------------------------------------------------------------------ check-in

    /** Los registros heredados pueden tener valores nulos: se usan los mismos valores por defecto que la app anterior. */
    public static DailyCheckIn toDomain(DailyCheckInEntity e) {
        return new DailyCheckIn(e.getId(), e.getUsuarioId(), e.getFecha(), orDefault(e.getCalidadSueno(), 3),
                orDefault(e.getNivelEstres(), 3), orDefault(e.getNivelEnergia(), 3), orDefault(e.getDolorMuscular(), 1),
                e.getZonasDolor() == null ? List.of() : Arrays.asList(e.getZonasDolor()),
                e.getListoParaEntrenar() == null || e.getListoParaEntrenar(), e.getNotas(), e.getCreadoEn());
    }

    public static void copy(DailyCheckIn c, DailyCheckInEntity e) {
        e.setId(c.id());
        e.setUsuarioId(c.userId());
        e.setFecha(c.date());
        e.setCalidadSueno(c.sleepQuality());
        e.setNivelEstres(c.stress());
        e.setNivelEnergia(c.energy());
        e.setDolorMuscular(c.soreness());
        e.setZonasDolor(c.painZones().toArray(String[]::new));
        e.setListoParaEntrenar(c.readyToTrain());
        e.setNotas(c.notes());
        if (e.getCreadoEn() == null) {
            e.setCreadoEn(c.createdAt());
        }
    }

    private static int orDefault(Integer value, int fallback) {
        return value == null || value < 1 || value > 5 ? fallback : value;
    }

    // ------------------------------------------------------------------ plan semanal

    public static WeeklyTrainingPlan toDomain(WeeklyPlanEntity e) {
        return new WeeklyTrainingPlan(e.getId(), e.getUsuarioId(), e.getSemanaInicio(), e.getSesionesPlanificadas(),
                TrainingDbValues.intensity(e.getIntensidad()), e.getDuracionMinPorSesion(),
                TrainingDbValues.planStatus(e.getEstado()), e.getNotas());
    }

    public static void copy(WeeklyTrainingPlan p, WeeklyPlanEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.userId());
        e.setSemanaInicio(p.weekStart());
        e.setSesionesPlanificadas(p.plannedSessions());
        e.setIntensidad(TrainingDbValues.toDb(p.intensity()));
        e.setDuracionMinPorSesion(p.minutesPerSession());
        e.setEstado(TrainingDbValues.toDb(p.status()));
        e.setNotas(p.notes());
    }

    // ------------------------------------------------------------------ sugerencias

    /**
     * {@code datos} guarda los detalles libres de la sugerencia y, en la clave {@value #ADJUSTMENTS},
     * los ajustes por ejercicio planificado.
     */
    public static Recommendation toDomain(RecommendationEntity e) {
        Map<String, Object> data = e.getDatos() == null ? new LinkedHashMap<>() : new LinkedHashMap<>(e.getDatos());
        List<ExerciseAdjustment> adjustments = new ArrayList<>();
        if (data.remove(ADJUSTMENTS) instanceof List<?> list) {
            for (Object item : list) {
                if (item instanceof Map<?, ?> m) {
                    ExerciseAdjustment a = adjustment(m);
                    if (a != null) {
                        adjustments.add(a);
                    }
                }
            }
        }
        data.values().removeIf(java.util.Objects::isNull);
        return new Recommendation(e.getId(), e.getUsuarioId(), TrainingDbValues.recommendationType(e.getTipo()),
                e.getTitulo(), e.getDescripcion(), e.getEjercicioId(), e.getRutinaId(), adjustments, data,
                e.isAplicada(), e.getCreadoEn());
    }

    public static void copy(Recommendation r, RecommendationEntity e) {
        e.setId(r.id());
        e.setUsuarioId(r.userId());
        e.setTipo(TrainingDbValues.toDb(r.type()));
        e.setTitulo(r.title());
        e.setDescripcion(r.description());
        e.setEjercicioId(r.exerciseId());
        e.setRutinaId(r.routineId());
        e.setAplicada(r.applied());
        if (e.getCreadoEn() == null) {
            e.setCreadoEn(r.createdAt());
        }
        Map<String, Object> data = new LinkedHashMap<>(r.details());
        if (!r.adjustments().isEmpty()) {
            data.put(ADJUSTMENTS, r.adjustments().stream().map(TrainingPersistenceMapper::toMap).toList());
        }
        e.setDatos(data);
    }

    private static Map<String, Object> toMap(ExerciseAdjustment a) {
        ExerciseParameters p = a.parameters();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("plannedExerciseId", a.plannedExerciseId().toString());
        m.put("exerciseId", a.exerciseId() == null ? null : a.exerciseId().toString());
        m.put("exerciseName", a.exerciseName());
        m.put("reason", a.reason());
        m.put("sets", p.sets());
        m.put("reps", p.reps());
        m.put("restSeconds", p.restSeconds());
        m.put("weightKg", p.weightKg());
        m.put("weightsKg", p.weightsKg());
        m.put("targetDurationSeconds", p.targetDurationSeconds());
        m.put("distanceMeters", p.distanceMeters());
        m.put("isometricSeconds", p.isometricSeconds());
        m.put("repsPerSet", p.repsPerSet());
        m.put("isometricSecondsPerSet", p.isometricSecondsPerSet());
        return m;
    }

    private static ExerciseAdjustment adjustment(Map<?, ?> m) {
        try {
            UUID planned = UUID.fromString(String.valueOf(m.get("plannedExerciseId")));
            Object exerciseId = m.get("exerciseId");
            List<Double> weights = m.get("weightsKg") instanceof List<?> l
                    ? l.stream().filter(Number.class::isInstance).map(n -> ((Number) n).doubleValue()).toList() : null;
            ExerciseParameters params = ExerciseParameters.clamped(intOf(m.get("sets"), 3), intOf(m.get("reps"), 10),
                    intOf(m.get("restSeconds"), 90), doubleOf(m.get("weightKg")), weights,
                    integerOf(m.get("targetDurationSeconds")), integerOf(m.get("distanceMeters")),
                    integerOf(m.get("isometricSeconds")), integersOf(m.get("repsPerSet")),
                    integersOf(m.get("isometricSecondsPerSet")));
            return new ExerciseAdjustment(planned, exerciseId == null ? null : UUID.fromString(exerciseId.toString()),
                    (String) m.get("exerciseName"), params, (String) m.get("reason"));
        } catch (RuntimeException ex) {
            return null;
        }
    }

    private static int intOf(Object v, int fallback) {
        return v instanceof Number n ? n.intValue() : fallback;
    }

    private static Integer integerOf(Object v) {
        return v instanceof Number n ? n.intValue() : null;
    }

    private static List<Integer> integersOf(Object v) {
        return v instanceof List<?> l
                ? l.stream().filter(Number.class::isInstance).map(n -> ((Number) n).intValue()).toList() : null;
    }

    private static Double doubleOf(Object v) {
        return v instanceof Number n ? n.doubleValue() : null;
    }
}
