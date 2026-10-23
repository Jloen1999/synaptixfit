package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.BodyMeasurement;
import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.StudyModality;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WeightRecord;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.AcademicProfileEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.GoalHistoryEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.WeightHistoryEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.WellnessProfileEntity;
import java.util.ArrayList;
import java.util.List;

/** Perfil de dominio y sus historiales ↔ entidades, con la traducción de vocabularios de la BD. */
public final class ProfilePersistenceMapper {

    /** Reparto de días por defecto cuando una fila heredada solo guarda el número de días. */
    private static final List<List<Integer>> DEFAULT_DAYS = List.of(
            List.of(1), List.of(1, 4), List.of(1, 3, 5), List.of(1, 2, 4, 5), List.of(1, 2, 3, 4, 5),
            List.of(1, 2, 3, 4, 5, 6), List.of(1, 2, 3, 4, 5, 6, 7));

    private ProfilePersistenceMapper() {
    }

    // ---------------------------------------------------------------- bienestar

    public static WellnessProfile toDomain(WellnessProfileEntity e) {
        List<Integer> days = e.getDiasDisponibles();
        if (days == null || days.isEmpty()) {
            int count = Math.max(1, Math.min(7, e.getDiasDisponiblesSemana()));
            days = DEFAULT_DAYS.get(count - 1);
        }
        return WellnessProfile.builder()
                .id(e.getId())
                .userId(e.getUsuarioId())
                .age(e.getEdad())
                .sex(sexToDomain(e.getSexo()))
                .city(e.getCiudad())
                .measurement(new BodyMeasurement(e.getPesoKg(), e.getAlturaCm()))
                .activityLevel(activityToDomain(e.getNivelActividad()))
                .primaryGoal(goalToDomain(e.getObjetivoPrincipal()))
                .goals(e.getObjetivos())
                .equipment(e.getEquipamientoDisponible())
                .availableDays(days)
                .minutesPerSession(e.getMinutosPorSesion())
                .onboardingCompleted(e.isOnboardingCompletado())
                .createdAt(e.getCreadoEn())
                .updatedAt(e.getActualizadoEn())
                .build();
    }

    public static void copyToEntity(WellnessProfile p, WellnessProfileEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.userId());
        e.setEdad(p.age());
        e.setSexo(sexToDb(p.sex()));
        e.setCiudad(p.city());
        e.setPesoKg(p.weightKg());
        e.setAlturaCm(p.heightCm());
        e.setImc(p.bmi());
        e.setNivelActividad(activityToDb(p.activityLevel()));
        e.setObjetivoPrincipal(p.primaryGoal().label());
        e.setObjetivos(new ArrayList<>(p.goals()));
        e.setEquipamientoDisponible(new ArrayList<>(p.equipment()));
        e.setDiasDisponibles(new ArrayList<>(p.availableDays()));
        e.setDiasDisponiblesSemana(p.daysPerWeek());
        e.setMinutosPorSesion(p.minutesPerSession());
        e.setOnboardingCompletado(p.onboardingCompleted());
        e.setCreadoEn(p.createdAt());
        e.setActualizadoEn(p.updatedAt());
    }

    // ---------------------------------------------------------------- historiales

    public static WeightRecord toDomain(WeightHistoryEntity e) {
        return new WeightRecord(e.getId(), e.getUsuarioId(), e.getPesoKg(), e.getAlturaCm(), e.getImc(),
                e.getRegistradoEn());
    }

    public static WeightHistoryEntity toEntity(WeightRecord r) {
        WeightHistoryEntity e = new WeightHistoryEntity();
        e.setId(r.id());
        e.setUsuarioId(r.userId());
        e.setPesoKg(r.weightKg());
        e.setAlturaCm(r.heightCm());
        e.setImc(r.bmi());
        e.setRegistradoEn(r.recordedAt());
        return e;
    }

    public static GoalHistoryEntry toDomain(GoalHistoryEntity e) {
        return new GoalHistoryEntry(e.getId(), e.getUsuarioId(), goalToDomain(e.getObjetivo()),
                e.getObjetivoAnterior() == null ? null : goalToDomain(e.getObjetivoAnterior()),
                e.getFechaInicio(), e.getFechaFin(), e.getRutinaIds(), e.getCreadoEn());
    }

    public static void copyToEntity(GoalHistoryEntry g, GoalHistoryEntity e) {
        e.setId(g.id());
        e.setUsuarioId(g.userId());
        e.setObjetivo(g.goal().label());
        e.setObjetivoAnterior(g.previousGoal() == null ? null : g.previousGoal().label());
        e.setFechaInicio(g.startDate());
        e.setFechaFin(g.endDate());
        e.setRutinaIds(new ArrayList<>(g.routineIds()));
        e.setCreadoEn(g.createdAt());
    }

    // ---------------------------------------------------------------- académico

    public static AcademicProfile toDomain(AcademicProfileEntity e) {
        return new AcademicProfile(e.getId(), e.getUsuarioId(), e.getUniversidad(), e.getCarrera(),
                e.getSemestreActual(), modalityToDomain(e.getModalidad()), e.getCreditosSemestreActual(),
                e.getHorasObjetivoEstudioSemana(), e.getPromedioObjetivo(), e.getFechaInicioClases(),
                e.getFechaFinClases(), e.getCreadoEn(), e.getActualizadoEn());
    }

    public static void copyToEntity(AcademicProfile p, AcademicProfileEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.userId());
        e.setUniversidad(p.university());
        e.setCarrera(p.degree());
        e.setSemestreActual(p.semester());
        e.setModalidad(modalityToDb(p.modality()));
        e.setCreditosSemestreActual(p.semesterCredits());
        e.setHorasObjetivoEstudioSemana(p.weeklyStudyHoursGoal());
        e.setPromedioObjetivo(p.targetGpa());
        e.setFechaInicioClases(p.classesStartDate());
        e.setFechaFinClases(p.classesEndDate());
        e.setCreadoEn(p.createdAt());
        e.setActualizadoEn(p.updatedAt());
    }

    // ---------------------------------------------------------------- vocabularios

    static Sex sexToDomain(String value) {
        return switch (value) {
            case "hombre" -> Sex.MALE;
            case "mujer" -> Sex.FEMALE;
            case "no_binario" -> Sex.NON_BINARY;
            default -> Sex.PREFER_NOT_TO_SAY;
        };
    }

    static String sexToDb(Sex sex) {
        return switch (sex) {
            case MALE -> "hombre";
            case FEMALE -> "mujer";
            case NON_BINARY -> "no_binario";
            case PREFER_NOT_TO_SAY -> "prefiero_no_decirlo";
        };
    }

    static ActivityLevel activityToDomain(String value) {
        return switch (value) {
            case "ligero" -> ActivityLevel.LIGHT;
            case "moderado" -> ActivityLevel.MODERATE;
            case "alto" -> ActivityLevel.HIGH;
            default -> ActivityLevel.SEDENTARY;
        };
    }

    static String activityToDb(ActivityLevel level) {
        return switch (level) {
            case SEDENTARY -> "sedentario";
            case LIGHT -> "ligero";
            case MODERATE -> "moderado";
            case HIGH -> "alto";
        };
    }

    static StudyModality modalityToDomain(String value) {
        return switch (value) {
            case "hibrida" -> StudyModality.HYBRID;
            case "virtual" -> StudyModality.ONLINE;
            default -> StudyModality.IN_PERSON;
        };
    }

    static String modalityToDb(StudyModality modality) {
        return switch (modality) {
            case IN_PERSON -> "presencial";
            case HYBRID -> "hibrida";
            case ONLINE -> "virtual";
        };
    }

    /** Los textos heredados que no son finalidades estándar se reducen como en el sistema antiguo. */
    static TrainingGoal goalToDomain(String value) {
        return TrainingGoal.fromLabel(value).orElse(TrainingGoal.HYPERTROPHY);
    }
}
