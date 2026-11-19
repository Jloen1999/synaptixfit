package com.synaptixfit.domain.model.academic;

/**
 * Qué pasa con las preguntas que ya tiene el banco al crear otras (ADR 0058): {@link #ADD} las conserva y
 * añade las nuevas sin repetir enunciados; {@link #REPLACE} las sustituye (y con ellas su historial).
 */
public enum BankUpdateMode {
    ADD,
    REPLACE
}
