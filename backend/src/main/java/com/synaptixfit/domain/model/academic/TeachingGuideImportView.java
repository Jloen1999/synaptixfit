package com.synaptixfit.domain.model.academic;

import java.util.UUID;

/**
 * Lo que ve el estudiante de una importación de plan docente: estado efectivo (un análisis colgado
 * cuenta como fallido) y la asignatura suya a la que conviene aplicarlo, si la hay.
 */
public record TeachingGuideImportView(TeachingGuideImport guideImport, TeachingGuideImport.Status status,
                                      String errorCode, UUID suggestedSubjectId, String suggestedSubjectName) {
}
