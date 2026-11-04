package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanNothingFoundException;
import com.synaptixfit.domain.exception.academic.NoteScanTooLargeException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

class NotePhotoServiceTest {

    private final UUID user = UUID.randomUUID();
    private final List<String> pages = new ArrayList<>();
    private final ImageTextReaderPort reader = photo -> pages.remove(0);
    private final AtomicReference<String> tidiedInput = new AtomicReference<>();

    private static NotePhoto jpeg() {
        return new NotePhoto(new byte[] {1, 2, 3}, "image/jpeg");
    }

    private ReadNotePhotosUseCase.Command command(NotePhoto... photos) {
        return new ReadNotePhotosUseCase.Command(user, List.of(photos));
    }

    @Test
    void twoPagesAreJoinedInOrderAndTidiedByTheAi() {
        pages.addAll(List.of("Tema 1 la celula", "  La mitocondria produce energia  "));
        NotePhotoService service = new NotePhotoService(reader, text -> {
            tidiedInput.set(text);
            return new NoteTidierPort.TidiedNote("La célula", "## La célula\n\nLa mitocondria produce energía.");
        });

        ScannedNoteDraft draft = service.read(command(jpeg(), jpeg()));

        assertThat(tidiedInput.get()).isEqualTo("Tema 1 la celula\n\n---\n\nLa mitocondria produce energia");
        assertThat(draft.tidied()).isTrue();
        assertThat(draft.title()).isEqualTo("La célula");
        assertThat(draft.pages()).isEqualTo(2);
    }

    @Test
    void withoutAiTheReadTextIsKeptAndTitledWithItsFirstLine() {
        pages.add("# Derivadas\nLa derivada mide el cambio");
        NotePhotoService unavailable = new NotePhotoService(reader, text -> {
            throw new AiUnavailableException("caída");
        });
        ScannedNoteDraft draft = unavailable.read(command(jpeg()));
        assertThat(draft.tidied()).isFalse();
        assertThat(draft.markdown()).isEqualTo("# Derivadas\nLa derivada mide el cambio");
        assertThat(draft.title()).isEqualTo("Derivadas");

        pages.add("Integrales por partes y sustitución");
        NotePhotoService quota = new NotePhotoService(reader, text -> {
            throw new AiQuotaExceededException();
        });
        assertThat(quota.read(command(jpeg())).tidied()).isFalse();
    }

    @Test
    void blurryPhotosWithoutReadableTextAreReportedInsteadOfAnEmptyNote() {
        pages.add(" ~ - . | ");
        NotePhotoService service = new NotePhotoService(reader, text -> new NoteTidierPort.TidiedNote("x", "y"));
        assertThatThrownBy(() -> service.read(command(jpeg())))
                .isInstanceOf(NoteScanNothingFoundException.class);
    }

    @Test
    void batchRulesAreCheckedBeforeReading() {
        NotePhotoService service = new NotePhotoService(photo -> {
            throw new AssertionError("no debería leer");
        }, text -> new NoteTidierPort.TidiedNote("x", "y"));

        assertThatThrownBy(() -> service.read(new ReadNotePhotosUseCase.Command(user, List.of())))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        assertThatThrownBy(() -> service.read(new ReadNotePhotosUseCase.Command(user,
                Collections.nCopies(NotePhoto.MAX_PHOTOS + 1, jpeg()))))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        assertThatThrownBy(() -> service.read(command(new NotePhoto(new byte[] {1}, "image/heic"))))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        assertThatThrownBy(() -> service.read(command(new NotePhoto(new byte[0], "image/png"))))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        byte[] big = new byte[(int) NotePhoto.MAX_BYTES_PER_PHOTO + 1];
        assertThatThrownBy(() -> service.read(command(new NotePhoto(big, "image/png"))))
                .isInstanceOf(NoteScanTooLargeException.class);
        byte[] nine = new byte[9 * 1024 * 1024];
        assertThatThrownBy(() -> service.read(command(new NotePhoto(nine, "image/png"),
                new NotePhoto(nine, "image/png"), new NotePhoto(nine, "image/png"))))
                .isInstanceOf(NoteScanTooLargeException.class);
    }
}
