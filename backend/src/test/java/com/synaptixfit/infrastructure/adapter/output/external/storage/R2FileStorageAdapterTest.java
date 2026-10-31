package com.synaptixfit.infrastructure.adapter.output.external.storage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class R2FileStorageAdapterTest {

    /** Puerto cerrado en local: firmar no contacta con R2, pero descargar sí (y falla). */
    private static final String LOCAL_ENDPOINT = "http://127.0.0.1:1";

    private static R2FileStorageAdapter adapter(String endpoint, String accessKey, String secretKey) {
        return new R2FileStorageAdapter(new AppProperties(null, null, null, null,
                new AppProperties.Storage(endpoint, "auto", "bucket-secreto", accessKey, secretKey, null), null));
    }

    @Test
    void withoutEndpointOrCredentialsEveryOperationFailsInsteadOfSigningUselessUrls() {
        for (R2FileStorageAdapter storage : new R2FileStorageAdapter[]{
                adapter(null, "key", "secret"), adapter(LOCAL_ENDPOINT, "", "secret"),
                adapter(LOCAL_ENDPOINT, "key", " ")}) {
            assertThat(storage.isConfigured()).isFalse();
            assertThatThrownBy(() -> storage.presignUpload("k", "application/pdf", 10, Duration.ofMinutes(5)))
                    .isInstanceOf(StorageUnavailableException.class)
                    .hasMessage("File storage is not configured");
            assertThatThrownBy(() -> storage.presignDownload("k", Duration.ofMinutes(5)))
                    .isInstanceOf(StorageUnavailableException.class);
            assertThatThrownBy(() -> storage.download("k")).isInstanceOf(StorageUnavailableException.class);
            assertThatThrownBy(() -> storage.delete("k")).isInstanceOf(StorageUnavailableException.class);
            assertThatThrownBy(() -> storage.publicUrl("k")).isInstanceOf(StorageUnavailableException.class);
        }
    }

    @Test
    void configuredStorageSignsUrlsAndHidesSdkMessages() {
        R2FileStorageAdapter storage = adapter(LOCAL_ENDPOINT, "key", "secret");
        assertThat(storage.isConfigured()).isTrue();

        PresignedUrl upload = storage.presignUpload("users/a/file.pdf", "application/pdf", 10, Duration.ofMinutes(5));
        assertThat(upload.url()).startsWith(LOCAL_ENDPOINT + "/bucket-secreto/users/a/file.pdf");
        assertThat(upload.method()).isEqualTo("PUT");

        // El fallo del SDK se registra en el log; el mensaje (que llega al detail) es fijo.
        assertThatThrownBy(() -> storage.download("users/a/file.pdf"))
                .isInstanceOf(StorageUnavailableException.class)
                .hasMessage("Could not download object");
    }
}
