package com.synaptixfit.infrastructure.adapter.input.event.planner;

import com.synaptixfit.application.port.input.planner.SyncDeadlineFromChallengeUseCase;
import com.synaptixfit.domain.event.challenge.ChallengeLinkCompletionChanged;
import java.util.Locale;
import java.util.Set;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Un reto o tarea vinculados a una entrega/examen cambian de estado: la entrega se sincroniza. El caso
 * de uso solo actúa si el estado cambia, lo que corta el ida y vuelta con DeadlineCompletionChanged.
 */
@Component
public class ChallengeLinkCompletionListener {

    /** Tipos de vínculo que apuntan a una entrega (se acepta el vocabulario de BD y el de la API). */
    private static final Set<String> DEADLINE_LINKS = Set.of("examen", "entrega", "exam", "delivery", "deadline");

    private final SyncDeadlineFromChallengeUseCase syncDeadline;

    public ChallengeLinkCompletionListener(SyncDeadlineFromChallengeUseCase syncDeadline) {
        this.syncDeadline = syncDeadline;
    }

    @EventListener
    public void on(ChallengeLinkCompletionChanged event) {
        if (event.linkedEntityType() == null || event.linkedEntityId() == null
                || !DEADLINE_LINKS.contains(event.linkedEntityType().toLowerCase(Locale.ROOT))) {
            return;
        }
        syncDeadline.syncFromChallenge(event.userId(), event.linkedEntityId(), event.completed());
    }
}
