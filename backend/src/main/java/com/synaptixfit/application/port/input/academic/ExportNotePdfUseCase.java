package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.NotePdf;
import java.util.UUID;

/** Un apunte propio en PDF, para «Descargar» y «Compartir › Fuera de la app» (ADR 0064). */
public interface ExportNotePdfUseCase {

    NotePdf exportPdf(UUID userId, UUID noteId);
}
