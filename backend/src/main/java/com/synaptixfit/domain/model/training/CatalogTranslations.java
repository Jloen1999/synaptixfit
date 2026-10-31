package com.synaptixfit.domain.model.training;

import java.util.Map;
import java.util.UUID;

/**
 * Nombres del catálogo de entrenamiento en un idioma: ejercicios (por id) y términos de músculos,
 * material y partes del cuerpo (por su nombre en español, que es el canónico). Lo que no está
 * traducido se muestra en español. Las reglas del dominio siempre usan el nombre en español.
 */
public record CatalogTranslations(Map<UUID, String> exercises, Map<String, String> terms) {

    public static final CatalogTranslations NONE = new CatalogTranslations(Map.of(), Map.of());

    public CatalogTranslations {
        exercises = exercises == null ? Map.of() : Map.copyOf(exercises);
        terms = terms == null ? Map.of() : Map.copyOf(terms);
    }

    public String exercise(UUID id, String spanishName) {
        return id == null ? spanishName : exercises.getOrDefault(id, spanishName);
    }

    public String term(String spanishTerm) {
        return spanishTerm == null ? null : terms.getOrDefault(spanishTerm, spanishTerm);
    }
}
