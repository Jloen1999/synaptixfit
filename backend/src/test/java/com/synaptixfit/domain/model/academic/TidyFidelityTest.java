package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Freno a la IA que ordena apuntes: corregir y dar formato sí; escribir otra cosa, no. */
class TidyFidelityTest {

    private static final String READ = """
            Tema 2 La fotosintesls
            Las plantas transforman la luz del sol en energia quimica.
            Ocurre en los cloroplastos gracias a la clorofila.""";

    @Test
    void fixingMisreadLettersAndAddingMarkdownKeepsToTheText() {
        String tidied = """
                ## Tema 2: la fotosíntesis

                - Las plantas transforman la **luz del sol** en energía química.
                - Ocurre en los cloroplastos gracias a la clorofila.""";
        assertThat(TidyFidelity.keepsTo(READ, tidied)).isTrue();
    }

    @Test
    void anInventedNoteDoesNotKeepToTheText() {
        String invented = """
                ## La respiración celular

                La mitocondria degrada la glucosa y obtiene ATP mediante el ciclo de Krebs y la cadena de electrones.""";
        assertThat(TidyFidelity.keepsTo(READ, invented)).isFalse();
    }

    @Test
    void addingAWholeExplanationOnTopIsTooMuch() {
        String longer = READ + "\n" + "Las plantas transforman la luz del sol en energia quimica. ".repeat(6);
        assertThat(TidyFidelity.keepsTo(READ, longer)).isFalse();
    }

    @Test
    void anEmptyAnswerDoesNotKeepToTheText() {
        assertThat(TidyFidelity.keepsTo(READ, "  ")).isFalse();
    }

    @Test
    void wordsAreComparedWithoutAccentsCaseOrShortWords() {
        assertThat(TidyFidelity.words("¡La FOTOSÍNTESIS, en 2 días!")).isEqualTo(List.of("fotosintesis", "dias"));
    }

    @Test
    void oneLetterOffIsTheSameWordInMediumWordsAndTwoInLongOnes() {
        assertThat(TidyFidelity.near("clorofila", "c1orofi1a", TidyFidelity.allowedEdits(9))).isTrue();
        assertThat(TidyFidelity.near("energia", "energla", TidyFidelity.allowedEdits(7))).isTrue();
        assertThat(TidyFidelity.near("energia", "enorme", TidyFidelity.allowedEdits(7))).isFalse();
        assertThat(TidyFidelity.allowedEdits(3)).isZero();
    }
}
