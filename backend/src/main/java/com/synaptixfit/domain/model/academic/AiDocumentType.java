package com.synaptixfit.domain.model.academic;

/** Tipo de documento generado por el asistente de estudio y persistido para no regenerarlo. */
public enum AiDocumentType {
    /** Resumen en Markdown de un apunte o archivo. */
    SUMMARY,
    /** Mapa mental (árbol de profundidad máxima 3). */
    MIND_MAP,
    /** Marca de que la fuente tiene un banco de preguntas de práctica generado. */
    PRACTICE,
    /** Guía docente estructurada de una asignatura. */
    TEACHING_GUIDE
}
