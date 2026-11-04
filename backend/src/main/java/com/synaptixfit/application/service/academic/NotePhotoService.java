package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Implementa {@link ReadNotePhotosUseCase}: lee cada foto con {@link ImageTextReaderPort} (OCR) y
 * pide a {@link NoteTidierPort} que ordene el resultado. Si la IA falla, devuelve el texto leído tal
 * cual: sigue siendo útil y la persona lo corrige antes de guardar (ADR 0040).
 *
 * <p>Cada persona lee un lote cada vez: la lectura ocupa uno de los pocos huecos del lector y así
 * nadie los acapara repitiendo la petición.
 */
public class NotePhotoService implements ReadNotePhotosUseCase {

    private final ImageTextReaderPort reader;
    private final NoteTidierPort tidier;
    private final Clock clock;
    private final Set<UUID> reading = ConcurrentHashMap.newKeySet();

    public NotePhotoService(ImageTextReaderPort reader, NoteTidierPort tidier, Clock clock) {
        this.reader = reader;
        this.tidier = tidier;
        this.clock = clock;
    }

    @Override
    public ScannedNoteDraft read(Command command) {
        List<NotePhoto> photos = command.photos();
        NotePhoto.checkBatch(photos);
        if (!reading.add(command.userId())) {
            throw new NoteScanUnavailableException("A batch is already being read for this user");
        }
        try {
            return readBatch(photos);
        } finally {
            reading.remove(command.userId());
        }
    }

    private ScannedNoteDraft readBatch(List<NotePhoto> photos) {
        Instant deadline = clock.instant().plus(NotePhoto.READ_DEADLINE);
        List<String> pages = new ArrayList<>();
        for (NotePhoto photo : photos) {
            if (clock.instant().isAfter(deadline)) {
                throw new NoteScanUnavailableException("Reading the photos took too long");
            }
            pages.add(reader.read(photo));
        }
        String text = ScannedNoteDraft.joinPages(pages);
        if (text.length() > ScannedNoteDraft.MAX_TIDY_CHARS || clock.instant().isAfter(deadline)) {
            return ScannedNoteDraft.untidied(text, photos.size());
        }
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
