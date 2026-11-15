package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanNothingFoundException;
import com.synaptixfit.domain.exception.academic.NoteScanTooLargeException;
import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;
import com.synaptixfit.domain.model.academic.ScannedNoteDraft;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

class NotePhotoServiceTest {

    private final UUID user = UUID.randomUUID();
    private final List<String> pages = new ArrayList<>();
    /** Tesseract simulado: lee con buena confianza lo que haya en {@link #pages}. */
    private final ImageTextReaderPort reader = photo -> new PageReading(pages.remove(0), 92);
    private final AtomicReference<String> tidiedInput = new AtomicReference<>();
    private final AtomicInteger visionCalls = new AtomicInteger();

    private final Clock clock = Clock.fixed(Instant.parse("2026-11-04T10:00:00Z"), ZoneOffset.UTC);

    private static NotePhoto jpeg() {
        return new NotePhoto(ImageHeaderTest.jpeg(2400, 1800), "image/jpeg");
    }

    /** Lector con visión desactivado (sin clave), como en un entorno sin GEMINI_API_KEY. */
    private static final ImageTextReaderPort NO_VISION = new ImageTextReaderPort() {
        @Override
        public PageReading read(NotePhoto photo) {
            throw new AssertionError("sin clave no se llama");
        }

        @Override
        public boolean available() {
            return false;
        }
    };

    private ImageTextReaderPort vision(String text) {
        return photo -> {
            visionCalls.incrementAndGet();
            return PageReading.unscored(text);
        };
    }

    private NotePhotoService service(ImageTextReaderPort reader, NoteTidierPort tidier) {
        return new NotePhotoService(reader, NO_VISION, tidier, clock);
    }

    private ReadNotePhotosUseCase.Command command(NotePhoto... photos) {
        return new ReadNotePhotosUseCase.Command(user, List.of(photos));
    }

    @Test
    void twoPagesAreJoinedInOrderAndTidiedByTheAi() {
        pages.addAll(List.of("Tema 1 la celula", "  La mitocondria produce energia  "));
        NotePhotoService service = service(reader, text -> {
            tidiedInput.set(text);
            return new NoteTidierPort.TidiedNote("La célula", "## Tema 1: la célula\n\nLa mitocondria produce energía.");
        });

        ScannedNoteDraft draft = service.read(command(jpeg(), jpeg()));

        assertThat(tidiedInput.get()).isEqualTo("Tema 1 la celula\n\n---\n\nLa mitocondria produce energia");
        assertThat(draft.tidied()).isTrue();
        assertThat(draft.unclear()).isFalse();
        assertThat(draft.title()).isEqualTo("La célula");
        assertThat(draft.pages()).isEqualTo(2);
    }

    @Test
    void anAiAnswerThatDriftsFromThePhotoIsDiscardedAndTheReadTextKept() {
        pages.add("Tema 3 derivadas: la derivada mide el cambio instantaneo de una funcion");
        NotePhotoService service = service(reader, text -> new NoteTidierPort.TidiedNote("Historia",
                "## La Revolución francesa\n\nEn 1789 el pueblo de París tomó la Bastilla y cambió Europa."));

        ScannedNoteDraft draft = service.read(command(jpeg()));

        assertThat(draft.tidied()).isFalse();
        assertThat(draft.unclear()).isFalse();
        assertThat(draft.markdown()).startsWith("Tema 3 derivadas");
    }

    @Test
    void anUnclearReadingIsNotTidiedAndIsFlagged() {
        NotePhotoService service = new NotePhotoService(photo -> new PageReading("Tcma l la ce1ula y sus partcs", 41),
                NO_VISION, text -> {
                    throw new AssertionError("con una lectura dudosa no se ordena");
                }, clock);

        ScannedNoteDraft draft = service.read(command(jpeg()));

        assertThat(draft.tidied()).isFalse();
        assertThat(draft.unclear()).isTrue();
        assertThat(draft.markdown()).isEqualTo("Tcma l la ce1ula y sus partcs");
    }

    @Test
    void whenTesseractDoubtsTheVisionReaderReadsThePageAndItCanBeTidied() {
        NotePhotoService service = new NotePhotoService(photo -> new PageReading("Tcma l la ce1ula", 35),
                vision("Tema 1: la célula y sus partes"), text -> {
                    tidiedInput.set(text);
                    return new NoteTidierPort.TidiedNote("La célula", "## Tema 1\n\nLa célula y sus partes.");
                }, clock);

        ScannedNoteDraft draft = service.read(command(jpeg()));

        assertThat(visionCalls.get()).isEqualTo(1);
        assertThat(tidiedInput.get()).isEqualTo("Tema 1: la célula y sus partes");
        assertThat(draft.tidied()).isTrue();
        assertThat(draft.unclear()).isFalse();
    }

    @Test
    void aClearTesseractReadingNeverCallsTheVisionReader() {
        pages.add("La mitocondria produce energia para la celula");
        NotePhotoService service = new NotePhotoService(reader, vision("no debería usarse"),
                text -> new NoteTidierPort.TidiedNote("x", text), clock);
        service.read(command(jpeg()));
        assertThat(visionCalls.get()).isZero();
    }

    @Test
    void ifTheVisionReaderFailsTesseractsReadingIsKept() {
        ImageTextReaderPort failing = photo -> {
            throw new NoteScanUnavailableException("Google caído");
        };
        NotePhotoService service = new NotePhotoService(photo -> new PageReading("Tcma l la ce1ula y sus partcs", 40),
                failing, text -> new NoteTidierPort.TidiedNote("x", "y"), clock);

        ScannedNoteDraft draft = service.read(command(jpeg()));

        assertThat(draft.markdown()).isEqualTo("Tcma l la ce1ula y sus partcs");
        assertThat(draft.unclear()).isTrue();
        assertThat(draft.tidied()).isFalse();
    }

    @Test
    void withoutTesseractTheVisionReaderStillReadsAndWithoutBothItIsUnavailable() {
        ImageTextReaderPort missing = photo -> {
            throw new NoteScanUnavailableException("OCR program not available");
        };
        NotePhotoService withVision = new NotePhotoService(missing, vision("Integrales por partes y sustitución"),
                text -> new NoteTidierPort.TidiedNote("Integrales", "Integrales por partes y sustitución."), clock);
        assertThat(withVision.read(command(jpeg())).tidied()).isTrue();

        NotePhotoService without = new NotePhotoService(missing, NO_VISION,
                text -> new NoteTidierPort.TidiedNote("x", "y"), clock);
        assertThatThrownBy(() -> without.read(command(jpeg()))).isInstanceOf(NoteScanUnavailableException.class);
    }

    @Test
    void withoutAiTheReadTextIsKeptAndTitledWithItsFirstLine() {
        pages.add("# Derivadas\nLa derivada mide el cambio");
        NotePhotoService unavailable = service(reader, text -> {
            throw new AiUnavailableException("caída");
        });
        ScannedNoteDraft draft = unavailable.read(command(jpeg()));
        assertThat(draft.tidied()).isFalse();
        assertThat(draft.markdown()).isEqualTo("# Derivadas\nLa derivada mide el cambio");
        assertThat(draft.title()).isEqualTo("Derivadas");

        pages.add("Integrales por partes y sustitución");
        NotePhotoService quota = service(reader, text -> {
            throw new AiQuotaExceededException();
        });
        assertThat(quota.read(command(jpeg())).tidied()).isFalse();
    }

    @Test
    void blurryPhotosWithoutReadableTextAreReportedInsteadOfAnEmptyNote() {
        pages.add(" ~ - . | ");
        NotePhotoService service = service(reader, text -> new NoteTidierPort.TidiedNote("x", "y"));
        assertThatThrownBy(() -> service.read(command(jpeg())))
                .isInstanceOf(NoteScanNothingFoundException.class);
    }

    @Test
    void theRealFormatMustMatchTheDeclaredOneAndHugeImagesAreRejected() {
        NotePhotoService svc = service(photo -> {
            throw new AssertionError("no debería leer");
        }, text -> new NoteTidierPort.TidiedNote("x", "y"));
        // Un PNG que se hace pasar por JPEG (o un TIFF con cualquier nombre) no llega al lector.
        assertThatThrownBy(() -> svc.read(command(new NotePhoto(ImageHeaderTest.png(800, 600), "image/jpeg"))))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        byte[] tiff = {0x49, 0x49, 0x2A, 0x00, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        assertThatThrownBy(() -> svc.read(command(new NotePhoto(tiff, "image/png"))))
                .isInstanceOf(NoteScanUnsupportedFileException.class);
        // «Bomba de descompresión»: pocos bytes, pero 50 000 × 50 000 píxeles al abrirla.
        assertThatThrownBy(() -> svc.read(command(new NotePhoto(ImageHeaderTest.png(50_000, 50_000), "image/png"))))
                .isInstanceOf(NoteScanTooLargeException.class);
    }

    @Test
    void aVeryLongTextIsReturnedAsReadWithoutSendingItToTheAi() {
        pages.add("a".repeat(ScannedNoteDraft.MAX_TIDY_CHARS + 1));
        NotePhotoService svc = service(reader, text -> {
            throw new AssertionError("no debería llamar a la IA");
        });
        assertThat(svc.read(command(jpeg())).tidied()).isFalse();
    }

    @Test
    void onePersonReadsOneBatchAtATime() throws Exception {
        CountDownLatch reading = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        AtomicInteger calls = new AtomicInteger();
        NotePhotoService svc = service(photo -> {
            if (calls.getAndIncrement() == 0) {
                reading.countDown();
                try {
                    release.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
            return new PageReading("Tema 1 la celula y sus partes", 90);
        }, text -> new NoteTidierPort.TidiedNote("x", text));
        Thread first = new Thread(() -> svc.read(command(jpeg())));
        first.start();
        reading.await();
        assertThatThrownBy(() -> svc.read(command(jpeg()))).isInstanceOf(NoteScanUnavailableException.class);
        assertThat(svc.read(new ReadNotePhotosUseCase.Command(UUID.randomUUID(), List.of(jpeg()))).tidied()).isTrue();
        release.countDown();
        first.join();
    }

    @Test
    void batchRulesAreCheckedBeforeReading() {
        NotePhotoService service = service(photo -> {
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
