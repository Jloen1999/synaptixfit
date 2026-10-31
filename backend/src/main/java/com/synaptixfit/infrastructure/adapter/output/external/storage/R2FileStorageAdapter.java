package com.synaptixfit.infrastructure.adapter.output.external.storage;

import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.net.URI;
import java.time.Duration;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

/**
 * Almacenamiento en Cloudflare R2 mediante su API compatible con S3. Sustituye al Worker proxy:
 * el cliente sube con una URL prefirmada y nunca ve las credenciales.
 *
 * <p>Sin endpoint o sin credenciales todas las operaciones fallan con
 * {@link StorageUnavailableException}: firmar una URL no contacta con R2, así que sin esta
 * comprobación se devolverían URLs que nunca funcionan.
 */
@Component
public class R2FileStorageAdapter implements FileStoragePort {

    private static final Logger log = LoggerFactory.getLogger(R2FileStorageAdapter.class);

    /** Dominio reservado (.invalid nunca resuelve): marca que R2 no está configurado. */
    static final String UNCONFIGURED_ENDPOINT = "https://r2-no-configurado.invalid";

    private final AppProperties.Storage config;
    private final boolean configured;
    private final S3Client s3;
    private final S3Presigner presigner;

    public R2FileStorageAdapter(AppProperties properties) {
        this.config = properties.storage();
        this.configured = present(config.endpoint()) && present(config.accessKey()) && present(config.secretKey());
        StaticCredentialsProvider credentials = StaticCredentialsProvider.create(
                AwsBasicCredentials.create(blankToDummy(config.accessKey()), blankToDummy(config.secretKey())));
        S3Configuration pathStyle = S3Configuration.builder().pathStyleAccessEnabled(true).build();
        // Sin R2 configurado la app debe arrancar igual: el endpoint de relleno no resuelve, así que
        // solo fallan las operaciones de archivos (StorageUnavailableException), no todo el backend.
        URI endpoint = URI.create(config.endpoint() == null || config.endpoint().isBlank()
                ? UNCONFIGURED_ENDPOINT : config.endpoint());
        Region region = Region.of(config.region());
        this.s3 = S3Client.builder().endpointOverride(endpoint).region(region)
                .credentialsProvider(credentials).serviceConfiguration(pathStyle).build();
        this.presigner = S3Presigner.builder().endpointOverride(endpoint).region(region)
                .credentialsProvider(credentials).serviceConfiguration(pathStyle).build();
    }

    @Override
    public PresignedUrl presignUpload(String objectKey, String contentType, long sizeBytes, Duration validity) {
        requireConfigured();
        try {
            PutObjectRequest put = PutObjectRequest.builder().bucket(config.bucket()).key(objectKey)
                    .contentType(contentType).contentLength(sizeBytes).build();
            var signed = presigner.presignPutObject(r -> r.signatureDuration(validity).putObjectRequest(put));
            return new PresignedUrl(viaProxy(signed.url().toString()), "PUT", Map.of("Content-Type", contentType),
                    signed.expiration());
        } catch (SdkException e) {
            throw unavailable("Could not presign upload", e);
        }
    }

    @Override
    public PresignedUrl presignDownload(String objectKey, Duration validity) {
        requireConfigured();
        try {
            GetObjectRequest get = GetObjectRequest.builder().bucket(config.bucket()).key(objectKey).build();
            var signed = presigner.presignGetObject(r -> r.signatureDuration(validity).getObjectRequest(get));
            return new PresignedUrl(viaProxy(signed.url().toString()), "GET", Map.of(), signed.expiration());
        } catch (SdkException e) {
            throw unavailable("Could not presign download", e);
        }
    }

    @Override
    public byte[] download(String objectKey) {
        requireConfigured();
        try {
            return s3.getObjectAsBytes(GetObjectRequest.builder().bucket(config.bucket()).key(objectKey).build())
                    .asByteArray();
        } catch (SdkException e) {
            throw unavailable("Could not download object", e);
        }
    }

    @Override
    public void delete(String objectKey) {
        requireConfigured();
        try {
            s3.deleteObject(DeleteObjectRequest.builder().bucket(config.bucket()).key(objectKey).build());
        } catch (SdkException e) {
            throw unavailable("Could not delete object", e);
        }
    }

    @Override
    public String publicUrl(String objectKey) {
        requireConfigured();
        String base = config.publicBaseUrl();
        if (base == null || base.isBlank()) {
            return null;
        }
        return (base.endsWith("/") ? base : base + "/") + objectKey;
    }

    /**
     * Cambia el origen de R2 por el proxy de la app ({@code R2_PROXY_BASE_URL}), conservando ruta y firma: nginx
     * reenvía a R2 con su mismo Host, así que la firma sigue valiendo. En España algunos operadores bloquean
     * las IP de R2 durante los partidos de fútbol y el móvil no podía subir ni descargar archivos; el dominio
     * de la app no se ve afectado. Sin proxy configurado, la URL sale tal cual.
     */
    String viaProxy(String url) {
        String proxy = config.proxyBaseUrl();
        String endpoint = config.endpoint();
        if (!present(proxy) || !present(endpoint)) {
            return url;
        }
        String origin = endpoint.replaceFirst("/+$", "");
        return url.startsWith(origin + "/") ? proxy.replaceFirst("/+$", "") + url.substring(origin.length()) : url;
    }

    /** ¿Hay endpoint y credenciales? Sin ellos, ninguna operación puede funcionar. */
    boolean isConfigured() {
        return configured;
    }

    private void requireConfigured() {
        if (!configured) {
            throw new StorageUnavailableException("File storage is not configured");
        }
    }

    /**
     * El mensaje del SDK puede incluir el bucket, el endpoint o la clave del objeto y la excepción
     * acaba en el {@code detail} de la respuesta: se registra en el log y se devuelve un texto fijo.
     */
    private static StorageUnavailableException unavailable(String message, SdkException cause) {
        log.warn("{}: {}", message, cause.toString());
        return new StorageUnavailableException(message);
    }

    private static boolean present(String value) {
        return value != null && !value.isBlank();
    }

    private static String blankToDummy(String value) {
        return value == null || value.isBlank() ? "unset" : value;
    }
}
