package com.synaptixfit.domain.model.challenge;

/**
 * Condición para desbloquear una tarea a partir de sus dependencias (regla heredada de
 * {@code desbloquear_hitos}).
 */
public enum UnlockCondition {
    /** Todas las dependencias completadas. */
    AND,
    /** Al menos una dependencia completada. */
    OR,
    /** Al menos {@code n} dependencias completadas. */
    X_OF_Y;

    public boolean isSatisfied(int completedDependencies, int totalDependencies, int n) {
        if (totalDependencies == 0) {
            return true;
        }
        return switch (this) {
            case AND -> completedDependencies == totalDependencies;
            case OR -> completedDependencies >= 1;
            case X_OF_Y -> completedDependencies >= n;
        };
    }
}
