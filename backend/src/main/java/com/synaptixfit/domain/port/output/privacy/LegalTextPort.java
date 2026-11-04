package com.synaptixfit.domain.port.output.privacy;

import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import java.util.Optional;

/** Lee el texto fuente de un documento legal en un idioma (con sus marcadores sin rellenar). */
public interface LegalTextPort {

    /** Texto fuente; vacío si no existe en ese idioma. */
    Optional<String> load(LegalDocumentKind kind, String language);
}
