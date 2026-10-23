package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.FlashcardsOutcome;
import java.util.UUID;

/** Registra una ronda de flashcards (dominadas, dudosas, falladas): alimenta el SM-2 y da XP una vez por material. */
public interface ReviewFlashcardsUseCase {

    record Command(UUID userId, UUID materialId, int mastered, int doubtful, int failed) {}

    FlashcardsOutcome reviewFlashcards(Command command);
}
