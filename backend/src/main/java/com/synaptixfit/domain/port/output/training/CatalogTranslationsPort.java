package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.CatalogTranslations;

/**
 * Traducciones del catálogo de entrenamiento para un idioma (código ISO 639-1: en, fr, pt). Se piden
 * en cada respuesta: la implementación puede tenerlas en memoria, pero debe reflejar los cambios
 * guardados con {@link ExerciseNameTranslationsRepositoryPort}.
 */
public interface CatalogTranslationsPort {

    CatalogTranslations load(String language);
}
