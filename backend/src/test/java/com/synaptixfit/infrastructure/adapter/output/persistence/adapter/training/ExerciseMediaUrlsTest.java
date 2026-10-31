package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ExerciseMediaUrlsTest {

    private static final String DEV = "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/a.mp4";

    @Test
    void withAPublicDomainTheDevBucketAddressIsReplaced() {
        ExerciseMediaUrls media = new ExerciseMediaUrls("https://synaptixfit.jloenit.dev/media");

        assertThat(media.resolve(DEV)).isEqualTo("https://synaptixfit.jloenit.dev/media/ejercicios/demic/a.mp4");
        assertThat(media.resolve("https://otro.example.com/a.webp")).isEqualTo("https://otro.example.com/a.webp");
        assertThat(media.resolve(null)).isNull();
    }

    @Test
    void withoutAPublicDomainTheUrlIsKept() {
        assertThat(new ExerciseMediaUrls("").resolve(DEV)).isEqualTo(DEV);
        assertThat(new ExerciseMediaUrls((String) null).resolve(DEV)).isEqualTo(DEV);
    }
}
