package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Confianza de una lectura: media de sus palabras ponderada por su longitud y umbral de «dudosa». */
class PageReadingTest {

    @Test
    void longWordsWeighMoreThanStrayMarks() {
        PageReading reading = PageReading.of("Mitocondria ,", List.of(
                new PageReading.Word("Mitocondria", 90), new PageReading.Word(",", 10)));
        // (90 × 11 + 10 × 1) / 12 = 83
        assertThat(reading.confidence()).isEqualTo(83);
        assertThat(reading.unclear()).isFalse();
    }

    @Test
    void belowTheThresholdTheReadingIsUnclear() {
        PageReading reading = PageReading.of("Tcma ce1ula", List.of(
                new PageReading.Word("Tcma", 40), new PageReading.Word("ce1ula", 55)));
        assertThat(reading.confidence()).isLessThan(PageReading.LOW_CONFIDENCE);
        assertThat(reading.unclear()).isTrue();
    }

    @Test
    void wordsWithoutScoreAreIgnoredAndNoWordsMeansNothingRead() {
        PageReading none = PageReading.of("", List.of(new PageReading.Word("", -1)));
        assertThat(none.confidence()).isZero();
        assertThat(none.unclear()).isTrue();
        assertThat(none.hasText()).isFalse();
    }

    @Test
    void aReaderThatDoesNotScoreIsNeverUnclear() {
        PageReading vision = PageReading.unscored("Tema 1");
        assertThat(vision.confidence()).isEqualTo(PageReading.UNKNOWN);
        assertThat(vision.unclear()).isFalse();
        assertThat(vision.hasText()).isTrue();
    }
}
