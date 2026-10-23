package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import java.util.UUID;

/** Codifica como texto (JSON) los documentos estructurados que se guardan en {@code documentos_ia}. */
public interface StudyDocumentCodecPort {

    /** Marca de práctica: qué banco de preguntas se generó para la fuente. */
    record PracticeMarker(UUID materialId, UUID bankId, int questionCount) {
    }

    String encodeMindMap(MindMap mindMap);

    MindMap decodeMindMap(String content);

    String encodeTeachingGuide(TeachingGuide guide);

    TeachingGuide decodeTeachingGuide(String content);

    String encodePractice(PracticeMarker marker);

    PracticeMarker decodePractice(String content);
}
