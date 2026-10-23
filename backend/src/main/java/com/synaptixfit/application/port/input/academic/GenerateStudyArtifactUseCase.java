package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.ArtifactKind;
import com.synaptixfit.domain.model.academic.GeneratedStudyArtifact;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import java.util.List;
import java.util.UUID;

/** Centro de generación: resumen, mapa mental, tarjetas o test a partir de varias fuentes. Resultado efímero. */
public interface GenerateStudyArtifactUseCase {

    record Command(UUID userId, ArtifactKind kind, List<StudySourceRef> sources) {}

    GeneratedStudyArtifact generate(Command command);
}
