package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.insights;

import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.CognitiveStateEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.CrossRegulationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.PhysicalLoadEntity;
import java.math.BigDecimal;
import java.math.RoundingMode;

/** Traducción entre modelos de indicadores y entidades JPA (redondeo a la escala de cada columna numeric). */
public final class InsightsPersistenceMapper {

    private InsightsPersistenceMapper() {
    }

    public static PhysicalLoadRecord toDomain(PhysicalLoadEntity e) {
        return new PhysicalLoadRecord(e.getId(), e.getUsuarioId(), e.getSesionId(), e.getBloqueId(), e.getFechaRegistro(),
                e.getRpeSesion(), e.getDuracionMinutos(), e.getCreadoEn());
    }

    public static PhysicalLoadHistory.Entry toEntry(PhysicalLoadEntity e) {
        return new PhysicalLoadHistory.Entry(e.getFechaRegistro(), e.getRpeSesion(), e.getDuracionMinutos());
    }

    public static void copyToEntity(PhysicalLoadRecord r, PhysicalLoadEntity e) {
        e.setId(r.id());
        e.setUsuarioId(r.userId());
        e.setSesionId(r.sessionId());
        e.setBloqueId(r.blockId());
        e.setFechaRegistro(r.date());
        e.setRpeSesion((short) r.rpe());
        e.setDuracionMinutos(r.durationMinutes());
        e.setCreadoEn(r.createdAt());
    }

    public static CrossRegulationState toDomain(CrossRegulationEntity e) {
        return new CrossRegulationState(e.getUsuarioId(), toDouble(e.getCargaAguda7d()),
                toDouble(e.getCargaCronica28d()), e.getMinEstudioMaxRecomendado(), e.getDiasProximoExamen(),
                e.getActualizadoEn());
    }

    public static void copyToEntity(CrossRegulationState s, CrossRegulationEntity e) {
        e.setUsuarioId(s.userId());
        e.setCargaAguda7d(scale(s.acuteDailyLoad(), 2));
        e.setCargaCronica28d(scale(s.chronicDailyLoad(), 2));
        e.setMinEstudioMaxRecomendado(s.maxStudyMinutes());
        e.setDiasProximoExamen(s.daysUntilExam());
        e.setActualizadoEn(s.updatedAt());
        if (e.getCreadoEn() == null) {
            e.setCreadoEn(s.updatedAt());
        }
    }

    public static CognitiveState toDomain(CognitiveStateEntity e) {
        return new CognitiveState(e.getUsuarioId(), toDouble(e.getCargaCognitivaActual()),
                toDouble(e.getCapacidadAtencionActual()), e.getDuracionUltimoBloqueMin(), e.getFechaUltimoDescanso(),
                e.getRmrBase() == null ? null : e.getRmrBase().doubleValue(), e.getCreadoEn(), e.getActualizadoEn());
    }

    public static void copyToEntity(CognitiveState s, CognitiveStateEntity e) {
        e.setUsuarioId(s.userId());
        e.setCargaCognitivaActual(scale(s.cognitiveLoad(), 4));
        e.setCapacidadAtencionActual(scale(s.attentionCapacity(), 3));
        e.setDuracionUltimoBloqueMin(s.lastBlockMinutes());
        e.setFechaUltimoDescanso(s.lastRestAt());
        e.setRmrBase(s.rmrBase() == null ? null : scale(s.rmrBase(), 2));
        e.setCreadoEn(s.createdAt());
        e.setActualizadoEn(s.updatedAt());
    }

    private static BigDecimal scale(double v, int scale) {
        return BigDecimal.valueOf(v).setScale(scale, RoundingMode.HALF_UP);
    }

    private static double toDouble(BigDecimal v) {
        return v == null ? 0 : v.doubleValue();
    }
}
