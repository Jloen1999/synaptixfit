package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.domain.model.academic.QuestionType;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;

/**
 * Cabecera {@code X-Question-Types} con los tipos de pregunta que sabe pintar la app («MULTIPLE_CHOICE,
 * FILL_IN_BLANK,MULTIPLE_ANSWER»). Las apps anteriores a ADR 0058 no la mandan: reciben solo
 * {@link QuestionType#LEGACY}, así nunca ven «Varias correctas» como si fuera «Elegir una».
 */
final class QuestionTypesHeader {

    static final String NAME = "X-Question-Types";

    private QuestionTypesHeader() {
    }

    static Set<QuestionType> parse(String header) {
        if (header == null || header.isBlank()) {
            return QuestionType.LEGACY;
        }
        Set<QuestionType> types = EnumSet.noneOf(QuestionType.class);
        Arrays.stream(header.split(",")).map(String::strip).forEach(v -> Arrays.stream(QuestionType.values())
                .filter(t -> t.name().equals(v)).forEach(types::add));
        types.addAll(QuestionType.LEGACY);
        return Set.copyOf(types);
    }
}
