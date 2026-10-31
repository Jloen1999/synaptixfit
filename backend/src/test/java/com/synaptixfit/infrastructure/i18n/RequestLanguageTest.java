package com.synaptixfit.infrastructure.i18n;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import org.junit.jupiter.api.Test;

class RequestLanguageTest {

    @Test
    void onlySupportedLanguagesOtherwiseSpanish() {
        assertThat(RequestLanguage.codeOf(Locale.forLanguageTag("pt-PT"))).isEqualTo("pt");
        assertThat(RequestLanguage.codeOf(Locale.ENGLISH)).isEqualTo("en");
        assertThat(RequestLanguage.codeOf(Locale.GERMAN)).isEqualTo("es");
        assertThat(RequestLanguage.code()).isEqualTo("es");
    }
}
