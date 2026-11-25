package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ExportNotePdfUseCase;
import com.synaptixfit.application.port.input.academic.GetNoteUseCase;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.NotePdf;
import com.synaptixfit.domain.port.output.academic.NotePdfRendererPort;
import java.util.UUID;

/**
 * Implementa {@link ExportNotePdfUseCase} (ADR 0064): lee el apunte propio con {@link GetNoteUseCase} (su propia
 * transacción, corta) y lo dibuja con {@link NotePdfRendererPort} fuera de ella, para no tener una conexión a la base
 * de datos ocupada mientras se genera el PDF. Por eso este caso de uso no se envuelve en una transacción.
 */
public class NotePdfExportService implements ExportNotePdfUseCase {

    private final GetNoteUseCase getNote;
    private final NotePdfRendererPort pdf;

    public NotePdfExportService(GetNoteUseCase getNote, NotePdfRendererPort pdf) {
        this.getNote = getNote;
        this.pdf = pdf;
    }

    @Override
    public NotePdf exportPdf(UUID userId, UUID noteId) {
        Note note = getNote.getNote(userId, noteId);
        return new NotePdf(NotePdf.fileNameFor(note.title()), pdf.render(note.title(), note.content()));
    }
}
