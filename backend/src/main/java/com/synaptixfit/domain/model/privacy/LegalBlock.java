package com.synaptixfit.domain.model.privacy;

import com.synaptixfit.domain.model.shared.Guard;

/** Un trozo de un texto legal: título de sección, párrafo o punto de una lista. La web y la app lo pintan igual. */
public record LegalBlock(Type type, String text) {

    public enum Type { HEADING, PARAGRAPH, BULLET }

    public LegalBlock {
        Guard.notNull(type, "type");
        text = Guard.notBlank(text, "text");
    }
}
