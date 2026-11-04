package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import java.util.List;

/**
 * Implementa {@link ReadNotePhotosUseCase}: lee cada foto con {@link ImageTextReaderPort} (OCR) y
 * pide a {@link NoteTidierPort} que ordene el resultado. Si la IA falla, devuelve el texto leído tal
 * cual: sigue siendo útil y la persona lo corrige antes de guardar (ADR 0040).
 */
public class NotePhotoService implements ReadNotePhotosUseCase {

    private final ImageTextReaderPort reader;
    private final NoteTidierPort tidier;

    public NotePhotoService(ImageTextReaderPort reader, NoteTidierPort tidier) {
        this.reader = reader;
        this.tidier = tidier;
    }

    @Override
    public ScannedNoteDraft read(Command command) {
        List<NotePhoto> photos = command.photos();
        NotePhoto.checkBatch(photos);
        String text = ScannedNoteDraft.joinPages(photos.stream().map(reader::read).toList());
        try {
            NoteTidierPort.TidiedNote tidied = tidier.tidy(text);
            if (tidied.markdown() == null || tidied.markdown().isBlank()) {
                return ScannedNoteDraft.untidied(text, photos.size());
            }
            return ScannedNoteDraft.tidied(tidied.title(), tidied.markdown(), photos.size());
        } catch (AiUnavailableException | AiQuotaExceededException e) {
            return ScannedNoteDraft.untidied(text, photos.size());
        }
    }
}
