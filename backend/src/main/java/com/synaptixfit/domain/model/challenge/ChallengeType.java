package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.user.UsageFocus;

/** Ámbito del reto. */
public enum ChallengeType {
    FITNESS,
    ACADEMIC;

    /** Si una persona con ese enfoque puede tener retos de este ámbito. */
    public boolean allowedFor(UsageFocus focus) {
        return this == ACADEMIC ? focus.includesAcademic() : focus.includesFitness();
    }

    /** Único ámbito permitido por el enfoque, o {@code null} si se permiten los dos. */
    public static ChallengeType onlyFor(UsageFocus focus) {
        return switch (focus) {
            case ACADEMIC -> ACADEMIC;
            case FITNESS -> FITNESS;
            case BOTH -> null;
        };
    }
}
