package com.synaptixfit.infrastructure.adapter.output.external.ai;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import org.junit.jupiter.api.Test;

class AiLanguageTest {

    @Test
    void supportedLanguagesAndSpanishOtherwise() {
        assertThat(AiLanguage.nameOf(Locale.forLanguageTag("en-GB"))).isEqualTo("inglés");
        assertThat(AiLanguage.nameOf(Locale.FRENCH)).isEqualTo("francés");
        assertThat(AiLanguage.nameOf(Locale.forLanguageTag("pt-BR"))).isEqualTo("portugués");
        assertThat(AiLanguage.nameOf(Locale.GERMAN)).isEqualTo("español");
    }

    @Test
    void outsideARequestTheAiWritesInSpanish() {
        assertThat(AiLanguage.rule()).isEqualTo("Escribe en español.");
    }
}
