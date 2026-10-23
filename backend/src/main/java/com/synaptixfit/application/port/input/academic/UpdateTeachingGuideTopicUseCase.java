package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import java.util.UUID;

/** Marca o desmarca como completado un tema del temario. */
public interface UpdateTeachingGuideTopicUseCase {

    TeachingGuideDocument setTopicCompleted(UUID userId, UUID subjectId, int topicIndex, boolean completed);
}
