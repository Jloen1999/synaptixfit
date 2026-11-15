package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.user.ReadAvatarUseCase;
import com.synaptixfit.application.port.input.user.RemoveAvatarUseCase;
import com.synaptixfit.application.port.input.user.UploadAvatarUseCase;
import com.synaptixfit.application.service.user.AvatarService;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.user.AvatarImagePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de la foto de perfil (ADR 0052). Sin transacción a propósito: cada caso de uso hace una sola
 * escritura en la base de datos (atómica por sí misma) y el resto es abrir la imagen y hablar con R2, que
 * retendría una conexión del pool sin necesidad.
 */
@Configuration
public class AvatarBeanConfiguration {

    /** Ruta pública con la que se sirven las fotos ({@code AvatarController}). */
    static final String AVATAR_PATH = "/api/v1/avatars/";

    private final UserRepositoryPort users;
    private final AvatarImagePort images;
    private final FileStoragePort storage;
    private final String publicPrefix;

    /**
     * {@code baseUrl} vacía (variable sin poner o puesta en blanco, como hace Coolify) → la dirección pública de la
     * app: así nunca se guarda una dirección relativa que el móvil no sabría abrir.
     */
    public AvatarBeanConfiguration(UserRepositoryPort users, AvatarImagePort images, FileStoragePort storage,
                                   @Value("${synaptixfit.avatars.base-url:}") String baseUrl,
                                   @Value("${synaptixfit.mail.app-url}") String appUrl) {
        this.users = users;
        this.images = images;
        this.storage = storage;
        this.publicPrefix = publicPrefix(baseUrl, appUrl);
    }

    static String publicPrefix(String baseUrl, String appUrl) {
        String base = baseUrl == null || baseUrl.isBlank() ? appUrl : baseUrl;
        return base.strip().replaceFirst("/+$", "") + AVATAR_PATH;
    }

    @Bean(autowireCandidate = false)
    AvatarService avatarService() {
        return new AvatarService(users, images, storage, publicPrefix);
    }

    // Cada bean expone solo su contrato (como hace TransactionalUseCaseFactory.wrap): si se devolviera el servicio
    // tal cual, los tres beans serían el mismo tipo y Spring no sabría cuál inyectar.
    @Bean
    UploadAvatarUseCase uploadAvatarUseCase() {
        return avatarService()::uploadAvatar;
    }

    @Bean
    RemoveAvatarUseCase removeAvatarUseCase() {
        return avatarService()::removeAvatar;
    }

    @Bean
    ReadAvatarUseCase readAvatarUseCase() {
        return avatarService()::readAvatar;
    }
}
