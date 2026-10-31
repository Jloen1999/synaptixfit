package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.CatalogTranslations;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class CatalogTranslationServiceTest {

    @Test
    void spanishIsCanonicalAndOnlyAppLanguagesAreRead() {
        UUID press = UUID.randomUUID();
        List<String> loaded = new ArrayList<>();
        CatalogTranslationService service = new CatalogTranslationService(language -> {
            loaded.add(language);
            return new CatalogTranslations(Map.of(press, "Barbell bench press"), Map.of("Pectorales", "Chest"));
        });

        assertThat(service.translationsFor("es")).isSameAs(CatalogTranslations.NONE);
        assertThat(service.translationsFor("de")).isSameAs(CatalogTranslations.NONE);
        assertThat(service.translationsFor(null)).isSameAs(CatalogTranslations.NONE);
        CatalogTranslations en = service.translationsFor("en");
        assertThat(loaded).containsExactly("en");
        assertThat(en.exercise(press, "Press de banca con barra")).isEqualTo("Barbell bench press");
        assertThat(en.exercise(UUID.randomUUID(), "Sentadilla")).isEqualTo("Sentadilla");
        assertThat(en.term("Pectorales")).isEqualTo("Chest");
        assertThat(en.term("Bíceps")).isEqualTo("Bíceps");
    }
}
