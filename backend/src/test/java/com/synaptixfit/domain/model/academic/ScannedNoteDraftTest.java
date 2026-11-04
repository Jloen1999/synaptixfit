package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ScannedNoteDraftTest {

    @Test
    void titleIsTheFirstLineWithLettersWithoutMarkdownAndShortened() {
        assertThat(ScannedNoteDraft.firstLineTitle("\n---\n## 1. Tema de la célula\ntexto"))
                .isEqualTo("Tema de la célula");
        assertThat(ScannedNoteDraft.firstLineTitle("123\n- * \n")).isNull();
        String longLine = "a".repeat(200);
        assertThat(ScannedNoteDraft.firstLineTitle(longLine)).hasSize(ScannedNoteDraft.TITLE_MAX).endsWith("…");
    }

    @Test
    void anAiTitleIsKeptAndABlankOneFallsBackToTheText() {
        assertThat(ScannedNoteDraft.tidied("  Derivadas ", "## Otra cosa", 1).title()).isEqualTo("Derivadas");
        assertThat(ScannedNoteDraft.tidied(" ", "## Límites\ncontenido", 1).title()).isEqualTo("Límites");
    }
}
