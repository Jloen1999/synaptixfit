package com.synaptixfit.domain.model.user;

/**
 * Resultado de sumar o restar experiencia.
 *
 * @param level    nivel tras el cambio
 * @param levelXp  experiencia acumulada dentro del nivel actual
 * @param levelUps niveles ganados (positivo) o perdidos (negativo)
 * @param xpDelta  experiencia aplicada (negativa al restar)
 */
public record ExperienceChange(int level, int levelXp, int levelUps, int xpDelta) {

    public boolean leveledUp() {
        return levelUps > 0;
    }
}
