package com.synaptixfit.domain.model.academic;

import java.util.EnumSet;
import java.util.Set;

/**
 * Tipo de pregunta de práctica. {@link #MULTIPLE_ANSWER} (varias correctas, ADR 0058) solo se manda a las
 * apps que lo declaran: las anteriores no lo conocen y lo pintarían como «elegir una».
 */
public enum QuestionType {
    MULTIPLE_CHOICE,
    FILL_IN_BLANK,
    MULTIPLE_ANSWER;

    /** Tipos que entiende una app que no declara cuáles sabe pintar (las anteriores a ADR 0058). */
    public static final Set<QuestionType> LEGACY = Set.copyOf(EnumSet.of(MULTIPLE_CHOICE, FILL_IN_BLANK));

    /** Todos los tipos: lo que ve el propio servidor y una app al día. */
    public static final Set<QuestionType> ALL = Set.copyOf(EnumSet.allOf(QuestionType.class));

    /** Si la pregunta se contesta eligiendo entre opciones. */
    public boolean hasOptions() {
        return this != FILL_IN_BLANK;
    }
}
