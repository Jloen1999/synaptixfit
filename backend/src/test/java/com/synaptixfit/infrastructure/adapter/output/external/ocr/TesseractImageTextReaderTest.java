package com.synaptixfit.infrastructure.adapter.output.external.ocr;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import org.junit.jupiter.api.Test;

class TesseractImageTextReaderTest {

    @Test
    void dictionariesFollowTheAppLanguageWithEnglishAsBackup() {
        assertThat(TesseractImageTextReader.languages("es")).isEqualTo("spa+eng");
        assertThat(TesseractImageTextReader.languages("en")).isEqualTo("eng");
        assertThat(TesseractImageTextReader.languages("fr")).isEqualTo("fra+eng");
        assertThat(TesseractImageTextReader.languages("pt")).isEqualTo("por+eng");
        assertThat(TesseractImageTextReader.languages(null)).isEqualTo("spa+eng");
    }

    @Test
    void anImageTheLibraryCannotOpenIsAFileProblemNotAnOutage() {
        assertThat(TesseractImageTextReader.unreadableImage("Error in pixReadMem: Unknown format")).isTrue();
        assertThat(TesseractImageTextReader.unreadableImage("Failed loading language 'spa'")).isFalse();
    }

    @Test
    void withoutTheProgramInstalledTheServiceSaysItIsUnavailable() {
        TesseractImageTextReader reader = new TesseractImageTextReader("programa-que-no-existe-ocr", 5, 1);
        assertThatThrownBy(() -> reader.read(new NotePhoto(new byte[] {1}, "image/png")))
                .isInstanceOf(NoteScanUnavailableException.class);
    }
}
