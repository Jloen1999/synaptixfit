package com.synaptixfit.domain.model.profile.enrollment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class EnrollmentDocumentTest {

    @Test
    void onlyRealPdfsUpToFiveMegabytes() {
        byte[] pdf = "%PDF-1.7 contenido".getBytes(StandardCharsets.US_ASCII);
        assertThat(EnrollmentDocument.of(pdf, "application/pdf").content()).isEqualTo(pdf);
        assertThatThrownBy(() -> EnrollmentDocument.of(pdf, "image/png"))
                .extracting("code").isEqualTo("ENROLLMENT_FILE_INVALID");
        assertThatThrownBy(() -> EnrollmentDocument.of("no soy un pdf".getBytes(StandardCharsets.UTF_8),
                "application/pdf")).extracting("code").isEqualTo("ENROLLMENT_FILE_INVALID");
        byte[] huge = new byte[EnrollmentDocument.MAX_BYTES + 1];
        System.arraycopy(pdf, 0, huge, 0, 5);
        assertThatThrownBy(() -> EnrollmentDocument.of(huge, "application/pdf"))
                .extracting("code").isEqualTo("ENROLLMENT_FILE_INVALID");
    }
}
