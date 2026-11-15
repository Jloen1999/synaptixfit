package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import com.synaptixfit.domain.model.academic.TidyFidelity;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Implementa {@link ReadNotePhotosUseCase}: lee cada foto con el lector propio ({@link ImageTextReaderPort},
 * Tesseract) y, si duda, con el lector con visión (otro {@link ImageTextReaderPort}, Gemini, solo si está
 * configurado). Después pide a {@link NoteTidierPort} que ordene el resultado (ADR 0040 y 0051):
 * <ul>
 *   <li>con una lectura dudosa no se ordena: la IA «adivinaría» un apunte que no se parece a la foto;</li>
 *   <li>si el texto ordenado se aleja del leído ({@link TidyFidelity}), se devuelve el leído;</li>
 *   <li>si la IA falla, se devuelve el texto leído: sigue siendo útil y la persona lo corrige antes de guardar.</li>
 * </ul>
 *
 * <p>Cada persona lee un lote cada vez: la lectura ocupa uno de los pocos huecos del lector y así nadie los
 * acapara repitiendo la petición.
 */
public class NotePhotoService implements ReadNotePhotosUseCase {

    private final ImageTextReaderPort reader;
    private final ImageTextReaderPort visionReader;
    private final NoteTidierPort tidier;
    private final Clock clock;
    private final Set<UUID> reading = ConcurrentHashMap.newKeySet();

    public NotePhotoService(ImageTextReaderPort reader, ImageTextReaderPort visionReader, NoteTidierPort tidier,
                            Clock clock) {
        this.reader = reader;
        this.visionReader = visionReader;
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
        boolean unclear = false;
        for (NotePhoto photo : photos) {
            if (clock.instant().isAfter(deadline)) {
                throw new NoteScanUnavailableException("Reading the photos took too long");
            }
            PageReading page = readPage(photo, deadline);
            unclear |= page.unclear();
            pages.add(page.text());
        }
        String text = ScannedNoteDraft.joinPages(pages);
        if (unclear || text.length() > ScannedNoteDraft.MAX_TIDY_CHARS || clock.instant().isAfter(deadline)) {
            return ScannedNoteDraft.untidied(text, photos.size(), unclear);
        }
        try {
            NoteTidierPort.TidiedNote tidied = tidier.tidy(text);
            if (tidied.markdown() == null || tidied.markdown().isBlank()
                    || !TidyFidelity.keepsTo(text, tidied.markdown())) {
                return ScannedNoteDraft.untidied(text, photos.size(), false);
            }
            return ScannedNoteDraft.tidied(tidied.title(), tidied.markdown(), photos.size());
        } catch (AiUnavailableException | AiQuotaExceededException e) {
            return ScannedNoteDraft.untidied(text, photos.size(), false);
        }
    }

    /**
     * El lector propio primero. El de visión solo si el propio duda (o no está) y aún queda tiempo; si el de
     * visión falla o no encuentra texto, vale lo que leyó el propio.
     */
    private PageReading readPage(NotePhoto photo, Instant deadline) {
        PageReading own;
        try {
            own = reader.read(photo);
        } catch (NoteScanUnavailableException e) {
            // Sin Tesseract (o muy ocupado) aún se puede leer con visión; si tampoco, el error original.
            return readWithVision(photo, deadline).orElseThrow(() -> e);
        }
        if (!own.unclear() && own.hasText()) {
            return own;
        }
        return readWithVision(photo, deadline).orElse(own);
    }

    private Optional<PageReading> readWithVision(NotePhoto photo, Instant deadline) {
        if (!visionReader.available() || clock.instant().isAfter(deadline)) {
            return Optional.empty();
        }
        try {
            PageReading vision = visionReader.read(photo);
            return vision.hasText() ? Optional.of(vision) : Optional.empty();
        } catch (DomainException e) {
            return Optional.empty();
        }
    }
}
