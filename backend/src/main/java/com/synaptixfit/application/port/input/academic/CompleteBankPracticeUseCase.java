package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.PracticeResult;
import com.synaptixfit.domain.model.academic.QuestionType;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Corrige una práctica libre de todo el banco y concede su XP una sola vez por banco. Solo cuentan los tipos
 * que la app pudo enseñar (ADR 0058). {@code dontKnow}: preguntas contestadas con «No lo sé» (ADR 0063), que
 * cuentan como respondidas y falladas.
 */
public interface CompleteBankPracticeUseCase {

    PracticeResult completePractice(UUID userId, UUID bankId, Map<UUID, String> answers, Set<UUID> dontKnow,
                                    Set<QuestionType> visibleTypes);

    default PracticeResult completePractice(UUID userId, UUID bankId, Map<UUID, String> answers) {
        return completePractice(userId, bankId, answers, Set.of(), QuestionType.ALL);
    }
}
