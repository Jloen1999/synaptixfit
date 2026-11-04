package com.synaptixfit.domain.model.privacy;

import java.util.Arrays;
import java.util.Locale;
import java.util.Optional;

/**
 * Textos legales públicos de la app (ADR 0034): política de privacidad, condiciones de uso y cómo pedir el
 * borrado de la cuenta. {@code slug} es el nombre en la URL y en el fichero del texto.
 */
public enum LegalDocumentKind {
    PRIVACY("privacy"),
    TERMS("terms"),
    ACCOUNT_DELETION("account-deletion");

    private final String slug;

    LegalDocumentKind(String slug) {
        this.slug = slug;
    }

    public String slug() {
        return slug;
    }

    /** El tipo por su nombre en la URL; vacío si no existe. */
    public static Optional<LegalDocumentKind> fromSlug(String value) {
        if (value == null) {
            return Optional.empty();
        }
        String wanted = value.trim().toLowerCase(Locale.ROOT);
        return Arrays.stream(values()).filter(k -> k.slug.equals(wanted)).findFirst();
    }
}
