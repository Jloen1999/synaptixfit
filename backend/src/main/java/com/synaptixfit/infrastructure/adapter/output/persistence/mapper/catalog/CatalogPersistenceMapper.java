package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.Center;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.EvaluationCriteria;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CatalogSubjectEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CenterEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.DegreeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.EvaluationCriteriaEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.UniversityEntity;

/** Entidades del catálogo → modelo de dominio. */
public final class CatalogPersistenceMapper {

    private CatalogPersistenceMapper() {
    }

    public static University toDomain(UniversityEntity e) {
        return new University(e.getId(), e.getNombre(), e.getTipo(), e.getComunidad());
    }

    public static Center toDomain(CenterEntity e) {
        return new Center(e.getId(), e.getUniversidadId(), e.getNombre());
    }

    /** {@code center} y {@code university} pueden ser nulos si faltan (no debería ocurrir por las FK). */
    public static Degree toDomain(DegreeEntity e, CenterEntity center, UniversityEntity university) {
        return new Degree(e.getId(), e.getNombre(), e.getTotalCreditos(), e.getTotalHoras(), e.getCentroId(),
                center == null ? null : center.getNombre(),
                center == null ? null : center.getUniversidadId(),
                university == null ? null : university.getNombre());
    }

    public static CatalogSubject toDomain(CatalogSubjectEntity e) {
        return new CatalogSubject(e.getId(), e.getCarreraId(), e.getNombre(), e.getCurso(), e.getSemestre(),
                e.getCaracter(), e.getCreditos() == null ? null : e.getCreditos().doubleValue(), e.getHoras(),
                e.getDepartamento(), e.getIdiomaImparticion(), e.getUrlGuiaDocente());
    }

    public static EvaluationCriteria toDomain(EvaluationCriteriaEntity e) {
        return new EvaluationCriteria(orZero(e.getExamenFinalPorcentaje()), orZero(e.getEvaluacionContinuaPorcentaje()),
                orZero(e.getPracticasLaboratorioPorcentaje()));
    }

    private static double orZero(Float value) {
        return value == null ? 0 : value.doubleValue();
    }
}
