package com.synaptixfit.infrastructure.adapter.input.rest.support;

import com.synaptixfit.application.port.input.training.GetCatalogTranslationsUseCase;
import com.synaptixfit.domain.model.training.CatalogTranslations;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Nombres del catálogo de entrenamiento en el idioma de la petición, para los DTO de respuesta (que
 * se construyen con métodos estáticos {@code from}). Spring crea una instancia al arrancar y queda
 * accesible de forma estática; sin ella (tests de DTO), se devuelve el nombre en español. Solo vale
 * en el hilo de la petición. Lo que edita la administración usa siempre el español
 * ({@code ExerciseResponse.canonical}).
 */
@Component
public class LocalizedNames {

    private static volatile GetCatalogTranslationsUseCase translations;

    public LocalizedNames(GetCatalogTranslationsUseCase translations) {
        LocalizedNames.translations = translations;
    }

    public static String exercise(UUID id, String spanishName) {
        return current().exercise(id, spanishName);
    }

    /** Músculo, material o parte del cuerpo (por su nombre en español). */
    public static String term(String spanishTerm) {
        return current().term(spanishTerm);
    }

    /** Traducciones del idioma de la petición (en español si no hay petición ni traducciones). */
    public static CatalogTranslations current() {
        GetCatalogTranslationsUseCase source = translations;
        return source == null ? CatalogTranslations.NONE : source.translationsFor(RequestLanguage.code());
    }
}
