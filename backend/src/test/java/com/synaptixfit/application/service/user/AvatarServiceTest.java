package com.synaptixfit.application.service.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.user.UploadAvatarUseCase;
import com.synaptixfit.application.service.admin.AdminTestFixtures;
import com.synaptixfit.application.service.admin.AdminTestFixtures.FakeStorage;
import com.synaptixfit.application.service.admin.AdminTestFixtures.InMemoryUsers;
import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.exception.user.AvatarNotFoundException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import com.synaptixfit.domain.model.user.ProfilePhoto;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.domain.port.output.user.AvatarImagePort;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Foto de perfil: se prepara, se guarda, se apunta en la cuenta y la anterior se borra. */
class AvatarServiceTest {

    private static final String PREFIX = "https://app.test/api/v1/avatars/";
    private static final byte[] PREPARED = {9, 9, 9};

    private final InMemoryUsers users = new InMemoryUsers();
    private final FakeStorage storage = new FakeStorage();
    private final List<Integer> orientations = new ArrayList<>();
    private final AvatarImagePort images = (content, orientation, side) -> {
        orientations.add(orientation);
        assertThat(side).isEqualTo(ProfilePhoto.SIDE);
        return PREPARED;
    };
    private final AvatarService service = new AvatarService(users, images, storage, PREFIX);

    private User user() {
        return users.add(AdminTestFixtures.user("ana@example.com", Role.USER));
    }

    private static byte[] verticalPhoto() {
        return ImageHeaderTest.withExifOrientation(ImageHeaderTest.jpeg(4000, 3000), 6);
    }

    @Test
    void anUploadedPhotoIsStoredPreparedAndSetOnTheAccount() {
        User user = user();

        User saved = service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto()));

        assertThat(orientations).containsExactly(6);
        assertThat(saved.avatarUrl()).startsWith(PREFIX + user.id() + "/").endsWith(".jpg");
        String key = ProfilePhoto.storedKey(saved.avatarUrl(), user.id()).orElseThrow();
        assertThat(storage.stored).containsOnlyKeys(key);
        assertThat(storage.stored.get(key)).isEqualTo(PREPARED);
        assertThat(service.readAvatar(user.id(), key.substring(key.lastIndexOf('/') + 1))).isEqualTo(PREPARED);
    }

    @Test
    void changingThePhotoDeletesThePreviousOneAndItIsNoLongerServed() {
        User user = user();
        String first = service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto())).avatarUrl();
        String firstFile = first.substring(first.lastIndexOf('/') + 1);

        service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), ImageHeaderTest.png(600, 600)));

        assertThat(storage.deleted).containsExactly(ProfilePhoto.storedKey(first, user.id()).orElseThrow());
        assertThatThrownBy(() -> service.readAvatar(user.id(), firstFile))
                .isInstanceOf(AvatarNotFoundException.class);
    }

    @Test
    void aGooglePhotoIsReplacedButNeverDeleted() {
        User user = user();
        user.changeAvatar("https://lh3.googleusercontent.com/a/foto");

        service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto()));

        assertThat(storage.deleted).isEmpty();
    }

    @Test
    void removingThePhotoClearsTheAccountAndDeletesTheFile() {
        User user = user();
        String url = service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto())).avatarUrl();

        User saved = service.removeAvatar(user.id());

        assertThat(saved.avatarUrl()).isNull();
        assertThat(storage.deleted).containsExactly(ProfilePhoto.storedKey(url, user.id()).orElseThrow());
        assertThat(service.removeAvatar(user.id()).avatarUrl()).isNull();
    }

    @Test
    void aFailedDeletionOfTheOldFileDoesNotUndoTheChange() {
        User user = user();
        String first = service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto())).avatarUrl();
        storage.failing.add(ProfilePhoto.storedKey(first, user.id()).orElseThrow());

        User saved = service.removeAvatar(user.id());

        assertThat(saved.avatarUrl()).isNull();
    }

    @Test
    void anInvalidImageIsRejectedBeforeStoringAnything() {
        User user = user();
        assertThatThrownBy(() -> service.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), new byte[] {1, 2, 3})))
                .isInstanceOf(AvatarInvalidImageException.class);
        assertThat(storage.stored).isEmpty();
        assertThat(users.saves).isZero();
    }

    @Test
    void withoutStorageTheAccountIsNotTouched() {
        User user = user();
        FileStoragePort down = new FileStoragePort() {
            @Override public PresignedUrl presignUpload(String k, String c, long s, Duration v) { throw unavailable(); }
            @Override public PresignedUrl presignDownload(String k, Duration v) { throw unavailable(); }
            @Override public byte[] download(String k) { throw unavailable(); }
            @Override public void put(String k, byte[] content, String contentType) { throw unavailable(); }
            @Override public void delete(String k) { throw unavailable(); }
            @Override public void deleteFolder(String prefix) { throw unavailable(); }
            @Override public String publicUrl(String k) { throw unavailable(); }
        };
        AvatarService noStorage = new AvatarService(users, images, down, PREFIX);

        assertThatThrownBy(() -> noStorage.uploadAvatar(new UploadAvatarUseCase.Command(user.id(), verticalPhoto())))
                .isInstanceOf(StorageUnavailableException.class)
                .extracting("code").isEqualTo("STORAGE_UNAVAILABLE");
        assertThat(user.avatarUrl()).isNull();
    }

    @Test
    void unknownAccountsAndOddFileNamesAreNotFound() {
        assertThatThrownBy(() -> service.uploadAvatar(new UploadAvatarUseCase.Command(UUID.randomUUID(), verticalPhoto())))
                .isInstanceOf(UserNotFoundException.class);
        User user = user();
        assertThatThrownBy(() -> service.readAvatar(user.id(), "../../secreto.pdf"))
                .isInstanceOf(AvatarNotFoundException.class);
        assertThatThrownBy(() -> service.readAvatar(user.id(), UUID.randomUUID() + ".jpg"))
                .isInstanceOf(AvatarNotFoundException.class);
    }

    private static StorageUnavailableException unavailable() {
        return new StorageUnavailableException("File storage is not configured");
    }
}
