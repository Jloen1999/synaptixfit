package com.synaptixfit.domain.model.badge;

import com.synaptixfit.domain.model.user.UsageFocus;

/** Categoría de una insignia del catálogo. */
public enum BadgeCategory {
    TRAINING,
    STUDY,
    SOCIAL,
    STREAK,
    SPECIAL;

    /** Las de entrenamiento solo con deporte y las de estudio solo con estudios; el resto, siempre. */
    public boolean visibleFor(UsageFocus focus) {
        return switch (this) {
            case TRAINING -> focus.includesFitness();
            case STUDY -> focus.includesAcademic();
            default -> true;
        };
    }
}
