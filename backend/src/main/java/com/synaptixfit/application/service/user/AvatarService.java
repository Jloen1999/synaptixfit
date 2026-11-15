package com.synaptixfit.application.service.user;

import com.synaptixfit.application.port.input.user.ReadAvatarUseCase;
import com.synaptixfit.application.port.input.user.RemoveAvatarUseCase;
import com.synaptixfit.application.port.input.user.UploadAvatarUseCase;
import com.synaptixfit.domain.exception.user.AvatarNotFoundException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.shared.ImageHeader;
import com.synaptixfit.domain.model.user.ProfilePhoto;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.user.AvatarImagePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.lang.System.Logger.Level;
import java.util.Optional;
import java.util.UUID;

/**
 * Implementa {@link UploadAvatarUseCase}, {@link RemoveAvatarUseCase} y {@link ReadAvatarUseCase}: la foto de
 * perfil subida desde el móvil (ADR 0052). Comprueba la foto con {@link ProfilePhoto}, la prepara con
 * {@link AvatarImagePort} (derecha, cuadrada, 512 px, sin metadatos), la guarda con {@link FileStoragePort} y
 * apunta su dirección en la cuenta ({@link UserRepositoryPort}).
 *
 * <p>Orden: primero se guarda el archivo nuevo, después la cuenta y, por último, se borra el anterior con mejor
 * esfuerzo (si falla, queda un archivo huérfano, nunca una cuenta sin foto válida). Los huérfanos se van al
 * anonimizar o eliminar la cuenta: {@code UserDataEraser} vacía la carpeta entera de la persona.
 */
public class AvatarService implements UploadAvatarUseCase, RemoveAvatarUseCase, ReadAvatarUseCase {

    private static final System.Logger LOG = System.getLogger(AvatarService.class.getName());

    private final UserRepositoryPort users;
    private final AvatarImagePort images;
    private final FileStoragePort storage;
    private final String publicPrefix;

    /** {@code publicPrefix}: dirección pública bajo la que se sirven las fotos ({@code …/api/v1/avatars/}). */
    public AvatarService(UserRepositoryPort users, AvatarImagePort images, FileStoragePort storage,
                         String publicPrefix) {
        this.users = users;
        this.images = images;
        this.storage = storage;
        this.publicPrefix = publicPrefix;
    }

    @Override
    public User uploadAvatar(Command command) {
        activeUser(command.userId());
        ImageHeader header = ProfilePhoto.check(command.content());
        byte[] jpeg = images.squareJpeg(command.content(), header.orientation(), ProfilePhoto.SIDE);
        UUID photoId = UUID.randomUUID();
        storage.put(ProfilePhoto.objectKey(command.userId(), photoId), jpeg, "image/jpeg");
        // La cuenta se vuelve a leer justo antes de guardar: abrir la foto y subirla tarda segundos y, sin
        // transacción, guardar la copia leída al principio pisaría lo que cambiara entretanto (XP, racha, baja…).
        User user = activeUser(command.userId());
        Optional<String> previous = ProfilePhoto.storedKey(user.avatarUrl(), user.id());
        user.changeAvatar(ProfilePhoto.url(publicPrefix, user.id(), photoId));
        User saved = users.save(user);
        previous.ifPresent(key -> deleteQuietly(key, user.id()));
        return saved;
    }

    @Override
    public User removeAvatar(UUID userId) {
        User user = activeUser(userId);
        if (user.avatarUrl() == null) {
            return user;
        }
        Optional<String> previous = ProfilePhoto.storedKey(user.avatarUrl(), user.id());
        user.changeAvatar(null);
        User saved = users.save(user);
        previous.ifPresent(key -> deleteQuietly(key, userId));
        return saved;
    }

    @Override
    public byte[] readAvatar(UUID userId, String fileName) {
        String requested = ProfilePhoto.requestedKey(userId, fileName).orElseThrow(AvatarNotFoundException::new);
        String current = users.findById(userId)
                .filter(User::isActive)
                .flatMap(u -> ProfilePhoto.storedKey(u.avatarUrl(), u.id()))
                .orElseThrow(AvatarNotFoundException::new);
        if (!current.equals(requested)) {
            throw new AvatarNotFoundException();
        }
        return storage.download(current);
    }

    private User activeUser(UUID userId) {
        return users.findById(userId).filter(User::isActive).orElseThrow(() -> new UserNotFoundException(userId));
    }

    private void deleteQuietly(String key, UUID userId) {
        try {
            storage.delete(key);
        } catch (RuntimeException e) {
            LOG.log(Level.WARNING, "Could not delete previous profile photo of user {0}: {1}", userId, e.getMessage());
        }
    }
}
