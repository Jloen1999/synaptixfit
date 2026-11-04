package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.LinkedDeadline;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.MilestoneStatus;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.challenge.UnlockCondition;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeProgressEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.MilestoneEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/** Reto y tareas de dominio ↔ entidades; traduce los vocabularios en español de la BD. */
public final class ChallengePersistenceMapper {

    private ChallengePersistenceMapper() {
    }

    /**
     * @param deadlines   foto de las entregas vinculadas (por id) y {@code blocks}, bloques por tarea: datos de
     *                    solo lectura de Planificador que el reto usa para saber qué lo completa (ADR 0028)
     */
    public static Challenge toDomain(ChallengeEntity e, List<MilestoneEntity> milestones,
                                     Map<UUID, LinkedDeadline> deadlines, Map<UUID, StudyBlockProgress> blocks) {
        return Challenge.builder()
                .id(e.getId())
                .ownerId(e.getUsuarioId())
                .title(e.getTitulo())
                .type(ChallengeType.valueOf(e.getTipo().toUpperCase(Locale.ROOT)))
                .goal(e.getMeta())
                .visibility(VisibilityDbMapper.toDomain(e.getVisibilidad()))
                .completed(e.isEstaCompletado())
                .startAt(e.getFechaInicio())
                .endAt(e.getFechaFin())
                .createdAt(e.getCreadoEn())
                .updatedAt(e.getActualizadoEn())
                .currentStreak(e.getRachaActual())
                .bestStreak(e.getMejorRacha())
                .lastActiveDay(e.getUltimoDiaActivo())
                .subjectId(e.getAsignaturaId())
                .difficulty(difficultyToDomain(e.getDificultad()))
                .link(linkToDomain(e.getEntidadVinculadaTipo(), e.getEntidadVinculadaId()))
                .xpAwarded(e.getXpOtorgado())
                .originId(e.getOrigenId())
                .originOwnerId(e.getOrigenPropietarioId())
                .originOwnerName(e.getOrigenPropietarioNombre())
                .manualProgress(e.getProgresoManual())
                .sessionTarget(e.getSesionesObjetivo())
                .sessionsCompleted(e.getSesionesCompletadas())
                .milestones(milestones.stream().map(ChallengePersistenceMapper::toDomain).toList())
                .linkedDeadlines(deadlines)
                .studyBlocks(blocks)
                .build();
    }

    public static Milestone toDomain(MilestoneEntity e) {
        List<UUID> deps = e.getDependencias() == null ? List.of() : Arrays.asList(e.getDependencias());
        return new Milestone(e.getId(), e.getTitulo(), e.getPorcentajePeso(), e.getIndiceOrden(),
                e.getProgresoActual(), e.isEstaCompletado(), statusToDomain(e.getEstado()), deps,
                UnlockCondition.valueOf(e.getTipoCondicion()), e.getCondicionN(), e.getAsignaturaId(),
                difficultyToDomain(e.getDificultad()),
                linkToDomain(e.getEntidadVinculadaTipo(), e.getEntidadVinculadaId()), e.getXpOtorgado(),
                e.getApunteId(), e.getArchivoId());
    }

    public static void copyToEntity(Challenge c, ChallengeEntity e) {
        e.setId(c.id());
        e.setUsuarioId(c.ownerId());
        e.setTitulo(c.title());
        e.setTipo(c.type().name().toLowerCase(Locale.ROOT));
        e.setMeta(c.goal());
        e.setVisibilidad(VisibilityDbMapper.toDb(c.visibility()));
        e.setEstaCompletado(c.completed());
        e.setFechaInicio(c.startAt());
        e.setFechaFin(c.endAt());
        e.setCreadoEn(c.createdAt());
        e.setActualizadoEn(c.updatedAt());
        e.setRachaActual(c.currentStreak());
        e.setMejorRacha(c.bestStreak());
        e.setUltimoDiaActivo(c.lastActiveDay());
        e.setTieneDependencias(c.hasDependencies());
        e.setAsignaturaId(c.subjectId());
        e.setDificultad(difficultyToDb(c.difficulty()));
        e.setEntidadVinculadaTipo(c.link() == null ? null : linkTypeToDb(c.link().type()));
        e.setEntidadVinculadaId(c.link() == null ? null : c.link().entityId());
        e.setXpOtorgado(c.xpAwarded());
        e.setOrigenId(c.originId());
        e.setOrigenPropietarioId(c.originOwnerId());
        e.setOrigenPropietarioNombre(c.originOwnerName());
        e.setSesionesObjetivo(c.sessionTarget());
        e.setSesionesCompletadas(c.sessionsCompleted());
        e.setProgresoManual(c.manualProgress());
    }

    public static void copyToEntity(UUID challengeId, Milestone m, MilestoneEntity e) {
        e.setId(m.id());
        e.setRetoId(challengeId);
        e.setTitulo(m.title());
        e.setPorcentajePeso(m.weight());
        e.setIndiceOrden(m.order());
        e.setProgresoActual(m.progress());
        e.setEstaCompletado(m.completed());
        e.setEstado(statusToDb(m.status()));
        e.setDependencias(m.dependencies().toArray(UUID[]::new));
        e.setTipoCondicion(m.condition().name());
        e.setCondicionN(m.conditionN());
        e.setAsignaturaId(m.subjectId());
        e.setDificultad(difficultyToDb(m.difficulty()));
        e.setEntidadVinculadaTipo(m.link() == null ? null : linkTypeToDb(m.link().type()));
        e.setEntidadVinculadaId(m.link() == null ? null : m.link().entityId());
        e.setXpOtorgado(m.xpAwarded());
        e.setApunteId(m.noteId());
        e.setArchivoId(m.fileId());
    }

    public static ProgressEntry toDomain(ChallengeProgressEntity e) {
        return new ProgressEntry(e.getId(), e.getRetoId(), e.getHitoId(), e.getUsuarioId(), e.getCantidadCompletada(),
                e.getRegistradoEn(), e.getCreadoEn());
    }

    public static ChallengeProgressEntity toEntity(ProgressEntry p) {
        ChallengeProgressEntity e = new ChallengeProgressEntity();
        e.setId(p.id());
        e.setRetoId(p.challengeId());
        e.setHitoId(p.milestoneId());
        e.setUsuarioId(p.userId());
        e.setCantidadCompletada(p.amount());
        e.setRegistradoEn(p.recordedAt());
        e.setCreadoEn(p.createdAt());
        return e;
    }

    public static String difficultyToDb(Difficulty d) {
        return switch (d) {
            case LOW -> "baja";
            case MEDIUM -> "media";
            case HIGH -> "alta";
        };
    }

    public static Difficulty difficultyToDomain(String value) {
        return switch (value == null ? "media" : value) {
            case "baja" -> Difficulty.LOW;
            case "alta" -> Difficulty.HIGH;
            default -> Difficulty.MEDIUM;
        };
    }

    public static String linkTypeToDb(LinkType t) {
        return switch (t) {
            case EXAM -> "examen";
            case DELIVERY -> "entrega";
            case ROUTINE_DAY -> "dia_rutina";
        };
    }

    private static ChallengeLink linkToDomain(String type, UUID id) {
        if (type == null || id == null) {
            return null;
        }
        // «bloque» ya no es un vínculo (V1012 lo pasó a la tarea del bloque): se ignora si quedara alguno.
        return switch (type) {
            case "examen" -> new ChallengeLink(LinkType.EXAM, id);
            case "entrega" -> new ChallengeLink(LinkType.DELIVERY, id);
            case "dia_rutina" -> new ChallengeLink(LinkType.ROUTINE_DAY, id);
            default -> null;
        };
    }

    private static String statusToDb(MilestoneStatus s) {
        return switch (s) {
            case LOCKED -> "bloqueado";
            case AVAILABLE -> "disponible";
            case IN_PROGRESS -> "en_progreso";
            case COMPLETED -> "completado";
        };
    }

    private static MilestoneStatus statusToDomain(String value) {
        return switch (value == null ? "bloqueado" : value) {
            case "disponible" -> MilestoneStatus.AVAILABLE;
            case "en_progreso" -> MilestoneStatus.IN_PROGRESS;
            case "completado" -> MilestoneStatus.COMPLETED;
            default -> MilestoneStatus.LOCKED;
        };
    }
}
