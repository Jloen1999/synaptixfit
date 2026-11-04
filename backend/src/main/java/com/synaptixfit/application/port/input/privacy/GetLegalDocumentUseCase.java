package com.synaptixfit.application.port.input.privacy;

import com.synaptixfit.domain.model.privacy.LegalDocument;

/** Devuelve un texto legal público (privacidad, condiciones o borrado de cuenta) en el idioma pedido. */
public interface GetLegalDocumentUseCase {

    /**
     * @param slug     nombre del documento en la URL ({@code privacy}, {@code terms}, {@code account-deletion})
     * @param language idioma pedido; si no existe, se usa el español
     */
    LegalDocument getLegalDocument(String slug, String language);
}
