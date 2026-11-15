package com.synaptixfit.application.port.input.challenge;

import java.util.UUID;

/**
 * Recuenta desde cero los retos con regla automática del usuario (ADR 0043), completándolos o descompletándolos con
 * su XP. Idempotente: lo invocan los oyentes de repasos, Pomodoros, tests, entrenos, registro diario y semanas
 * planificadas.
 */
public interface SyncRuleChallengesUseCase {

    void syncRuleChallenges(UUID userId);
}
