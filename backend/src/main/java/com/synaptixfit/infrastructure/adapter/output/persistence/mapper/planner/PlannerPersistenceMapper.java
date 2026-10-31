package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.CalendarBlockEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.DeadlineEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.FocusSessionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.StudyPlanEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.WeeklyLoadEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Locale;

/**
 * Modelos del planificador ↔ entidades JPA. Traduce los enums de dominio a los valores (en español)
 * de la base de datos.
 */
public final class PlannerPersistenceMapper {

    private PlannerPersistenceMapper() {
    }

    // ------------------------------------------------------------------ bloques

    public static CalendarBlock toDomain(CalendarBlockEntity e) {
        CalendarBlock.Details details = new CalendarBlock.Details(e.getAsignaturaId(), e.getTemas(), e.getUbicacion(),
                priorityToDomain(e.getPrioridad()), e.isPrivate(), classKindToDomain(e.getTipoClase()), e.getRutinaId(),
                e.getSemanaRutinaId(), e.getDiaRutinaId(), e.getRetoId(), e.getHitoId(), e.getEntregaExamenId());
        return CalendarBlock.builder()
                .id(e.getId())
                .userId(e.getUsuarioId())
                .range(new TimeRange(e.getHoraInicio(), e.getHoraFin()))
                .dayOfWeek(e.getDiaSemana() == null ? 1 : e.getDiaSemana())
                .type(ActivityType.fromCode(e.getTipoActividad()))
                .details(details)
                .hasConflict(e.isTieneConflicto())
                .studyPlanId(e.getPlanEstudioId())
                .completed(e.isCompletado())
                .attendanceRegisteredAt(e.getAsistenciaRegistradaEn())
                .fixed(e.isEsFijo())
                .immovable(e.isEsHitoInamovible())
                .xpAwarded(e.isXpBloqueOtorgado())
                .icsUid(e.getIcsUid())
                .studyMaterialId(e.getMaterialEstudioId())
                .metValue(e.getMetValue() == null ? null : e.getMetValue().doubleValue())
                .caloriesBurned(e.getCaloriasQuemadas() == null ? null : e.getCaloriasQuemadas().doubleValue())
                .cognitiveLoad(e.getCargaCognitivaGenerada() == null ? null : e.getCargaCognitivaGenerada().doubleValue())
                .createdAt(e.getCreadoEn())
                .build();
    }

    public static void copyToEntity(CalendarBlock b, CalendarBlockEntity e) {
        CalendarBlock.Details d = b.details();
        e.setId(b.id());
        e.setUsuarioId(b.userId());
        e.setAsignaturaId(d.subjectId());
        e.setHoraInicio(b.start());
        e.setHoraFin(b.end());
        e.setUbicacion(d.location());
        e.setTieneConflicto(b.hasConflict());
        e.setPlanEstudioId(b.studyPlanId());
        e.setPrioridad(priorityToDb(d.priority()));
        e.setTipoActividad(b.type().code());
        e.setRutinaId(d.routineId());
        e.setTemas(d.topics());
        e.setCompletado(b.completed());
        e.setAsistenciaRegistradaEn(b.attendanceRegisteredAt());
        e.setEsFijo(b.fixed());
        e.setDiaSemana(b.dayOfWeek());
        e.setXpBloqueOtorgado(b.xpAwarded());
        e.setRetoId(d.challengeId());
        e.setHitoId(d.milestoneId());
        e.setDiaRutinaId(d.routineDayId());
        e.setSemanaRutinaId(d.routineWeekId());
        e.setEntregaExamenId(d.deadlineId());
        e.setEsHitoInamovible(b.immovable());
        e.setIcsUid(b.icsUid());
        e.setPrivate(d.isPrivate());
        e.setTipoClase(classKindToDb(d.classKind()));
        e.setMetValue(decimal(b.metValue(), 2));
        e.setCaloriasQuemadas(decimal(b.caloriesBurned(), 2));
        e.setCargaCognitivaGenerada(decimal(b.cognitiveLoad(), 4));
        e.setMaterialEstudioId(b.studyMaterialId());
    }

    // ------------------------------------------------------------------ entregas

    public static Deadline toDomain(DeadlineEntity e) {
        return Deadline.builder()
                .id(e.getId())
                .userId(e.getUsuarioId())
                .subjectId(e.getAsignaturaId())
                .title(e.getTitulo())
                .type(deadlineTypeToDomain(e.getTipo()))
                .dueAt(e.getFechaLimite())
                .difficulty(priorityToDomain(e.getDificultad()))
                .description(e.getDescripcion())
                .completed(e.isEstaCompletado())
                .studyPlanId(e.getPlanEstudioId())
                .xpAwarded(e.isXpEntregaOtorgado())
                .icsUid(e.getIcsUid())
                .createdAt(e.getCreadoEn())
                .updatedAt(e.getActualizadoEn())
                .build();
    }

    public static void copyToEntity(Deadline d, DeadlineEntity e) {
        e.setId(d.id());
        e.setUsuarioId(d.userId());
        e.setAsignaturaId(d.subjectId());
        e.setTitulo(d.title());
        e.setTipo(deadlineTypeToDb(d.type()));
        e.setFechaLimite(d.dueAt());
        e.setDificultad(priorityToDb(d.difficulty()));
        e.setDescripcion(d.description());
        e.setEstaCompletado(d.completed());
        e.setPlanEstudioId(d.studyPlanId());
        e.setXpEntregaOtorgado(d.xpAwarded());
        e.setIcsUid(d.icsUid());
    }

    // ------------------------------------------------------------------ planes

    public static StudyPlan toDomain(StudyPlanEntity e) {
        return new StudyPlan(e.getId(), e.getUsuarioId(), e.getNombre(), e.getSemanaInicio(),
                VisibilityDbMapper.toDomain(e.getVisibilidad()), e.isXpPlanificacionOtorgado(),
                e.getXpPlanificacionPuntos());
    }

    public static void copyToEntity(StudyPlan p, StudyPlanEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.userId());
        e.setNombre(p.name());
        e.setSemanaInicio(p.weekStart());
        e.setSemanaFin(p.weekEnd());
        e.setVisibilidad(VisibilityDbMapper.toDb(p.visibility()));
        e.setXpPlanificacionOtorgado(p.xpAwarded());
        e.setXpPlanificacionPuntos(p.xpPoints());
    }

    // ------------------------------------------------------------------ carga semanal

    public static WeeklyAcademicLoad toDomain(WeeklyLoadEntity e) {
        return new WeeklyAcademicLoad(e.getId(), e.getUsuarioId(), e.getSemanaInicio(), e.getHorasEstudioPlaneadas(),
                e.getHorasEstudioReales(), e.getEvaluacionesSemana(), e.getEntregasSemana(), e.getNivelEstres(),
                e.getHorasSuenoPromedio(), e.getNotas(), e.isXpEstudioOtorgado());
    }

    public static void copyToEntity(WeeklyAcademicLoad l, WeeklyLoadEntity e) {
        e.setId(l.id());
        e.setUsuarioId(l.userId());
        e.setSemanaInicio(l.weekStart());
        e.setHorasEstudioPlaneadas(l.plannedHours());
        e.setHorasEstudioReales(l.actualHours());
        e.setEvaluacionesSemana(l.exams());
        e.setEntregasSemana(l.deliveries());
        e.setNivelEstres(l.stressLevel());
        e.setHorasSuenoPromedio(l.sleepHours());
        e.setNotas(l.notes());
        e.setXpEstudioOtorgado(l.xpAwarded());
    }

    // ------------------------------------------------------------------ pomodoro

    public static FocusSession toDomain(FocusSessionEntity e) {
        return new FocusSession(e.getId(), e.getUsuarioId(), phaseToDomain(e.getTipoFase()), e.getDuracionMinutos(),
                Math.max(1, e.getCiclosCompletados()), e.isCompletada(), e.getFecha(), e.getBloqueId(),
                e.getAsignaturaId(), e.getXpOtorgado(), e.getCreadoEn());
    }

    public static FocusSessionEntity toEntity(FocusSession s) {
        FocusSessionEntity e = new FocusSessionEntity();
        e.setId(s.id());
        e.setUsuarioId(s.userId());
        e.setDuracionMinutos(s.durationMinutes());
        e.setCiclosCompletados(s.cycles());
        e.setTipoFase(phaseToDb(s.phase()));
        e.setCompletada(s.completed());
        e.setFecha(s.date());
        e.setBloqueId(s.blockId());
        e.setAsignaturaId(s.subjectId());
        e.setXpOtorgado(s.xpAwarded());
        e.setCreadoEn(s.createdAt());
        return e;
    }

    // ------------------------------------------------------------------ vocabularios

    public static String priorityToDb(Priority p) {
        return switch (p == null ? Priority.MEDIUM : p) {
            case LOW -> "baja";
            case MEDIUM -> "media";
            case HIGH -> "alta";
        };
    }

    public static Priority priorityToDomain(String v) {
        if ("baja".equals(v)) {
            return Priority.LOW;
        }
        return "alta".equals(v) ? Priority.HIGH : Priority.MEDIUM;
    }

    public static String deadlineTypeToDb(DeadlineType t) {
        return switch (t) {
            case EXAM -> "examen";
            case ASSIGNMENT -> "entrega";
            case PRESENTATION -> "presentacion";
            case OTHER -> "otro";
        };
    }

    public static DeadlineType deadlineTypeToDomain(String v) {
        return switch (v == null ? "" : v) {
            case "examen" -> DeadlineType.EXAM;
            case "presentacion" -> DeadlineType.PRESENTATION;
            case "otro" -> DeadlineType.OTHER;
            default -> DeadlineType.ASSIGNMENT;
        };
    }

    static String classKindToDb(ClassKind k) {
        if (k == null) {
            return null;
        }
        return k == ClassKind.THEORY ? "teoria" : "practica";
    }

    static ClassKind classKindToDomain(String v) {
        if (v == null) {
            return null;
        }
        return switch (v) {
            case "teoria", "theory" -> ClassKind.THEORY;
            case "practica", "practice" -> ClassKind.PRACTICE;
            default -> null;
        };
    }

    /** Código de la fase en {@code sesiones_focus.tipo_fase}. */
    public static String phaseToDb(FocusSession.FocusPhase phase) {
        return phase.name().toLowerCase(Locale.ROOT);
    }

    static FocusSession.FocusPhase phaseToDomain(String v) {
        return switch (v == null ? "" : v) {
            case "short_break" -> FocusSession.FocusPhase.SHORT_BREAK;
            case "long_break" -> FocusSession.FocusPhase.LONG_BREAK;
            default -> FocusSession.FocusPhase.FOCUS;
        };
    }

    private static BigDecimal decimal(Double value, int scale) {
        return value == null ? null : BigDecimal.valueOf(value).setScale(scale, RoundingMode.HALF_UP);
    }
}
