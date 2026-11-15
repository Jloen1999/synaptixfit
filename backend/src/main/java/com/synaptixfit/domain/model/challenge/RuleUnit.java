package com.synaptixfit.domain.model.challenge;

/**
 * Cómo se cuenta un reto automático (ADR 0043): días que cumplen el mínimo, semanas (de lunes a domingo) que lo
 * cumplen, o la suma de todo el periodo.
 */
public enum RuleUnit {
    DAY, WEEK, TOTAL
}
