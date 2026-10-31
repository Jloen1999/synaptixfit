package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetCatalogTranslationsUseCase;
import com.synaptixfit.domain.model.training.CatalogTranslations;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.port.output.training.CatalogTranslationsPort;

/**
 * Implementa {@link GetCatalogTranslationsUseCase} con {@link CatalogTranslationsPort}, que las tiene
 * en memoria y las renueva cuando la administración cambia un nombre. El español es el canónico: no
 * tiene traducciones.
 */
public class CatalogTranslationService implements GetCatalogTranslationsUseCase {

    private final CatalogTranslationsPort port;

    public CatalogTranslationService(CatalogTranslationsPort port) {
        this.port = port;
    }

    @Override
    public CatalogTranslations translationsFor(String language) {
        if (language == null || !ExerciseNameTranslations.LANGUAGES.contains(language)) {
            return CatalogTranslations.NONE;
        }
        return port.load(language);
    }
}
