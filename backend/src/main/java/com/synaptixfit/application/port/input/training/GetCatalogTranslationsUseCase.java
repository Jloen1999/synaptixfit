package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.CatalogTranslations;

/** Nombres de ejercicios y términos del catálogo en el idioma de quien pide (vacío en español). */
public interface GetCatalogTranslationsUseCase {

    CatalogTranslations translationsFor(String language);
}
