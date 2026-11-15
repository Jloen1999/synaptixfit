package com.synaptixfit.domain.model.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.exception.user.AvatarTooLargeException;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas de la foto de perfil: qué se acepta y qué archivo es de quién. */
class ProfilePhotoTest {

    private final UUID user = UUID.randomUUID();
    private final UUID photo = UUID.randomUUID();

    @Test
    void theFormatIsCheckedByItsSignatureAndTheOrientationIsKept() {
        byte[] jpeg = ImageHeaderTest.withExifOrientation(ImageHeaderTest.jpeg(1200, 900), 6);
        assertThat(ProfilePhoto.check(jpeg).orientation()).isEqualTo(6);
        assertThat(ProfilePhoto.check(ImageHeaderTest.png(800, 800)).mimeType()).isEqualTo("image/png");
        assertThat(ProfilePhoto.check(ImageHeaderTest.webp(800, 800)).mimeType()).isEqualTo("image/webp");
    }

    @Test
    void anythingElseIsRejected() {
        assertThatThrownBy(() -> ProfilePhoto.check(new byte[0])).isInstanceOf(AvatarInvalidImageException.class);
        assertThatThrownBy(() -> ProfilePhoto.check("GIF89a.........".getBytes()))
                .isInstanceOf(AvatarInvalidImageException.class)
                .extracting("code").isEqualTo("AVATAR_INVALID_IMAGE");
        assertThatThrownBy(() -> ProfilePhoto.check(new byte[(int) ProfilePhoto.MAX_BYTES + 1]))
                .isInstanceOf(AvatarTooLargeException.class)
                .extracting("code").isEqualTo("AVATAR_TOO_LARGE");
        assertThatThrownBy(() -> ProfilePhoto.check(ImageHeaderTest.png(50_000, 50_000)))
                .isInstanceOf(AvatarTooLargeException.class);
    }

    @Test
    void eachPhotoHasItsOwnKeyAndUrl() {
        assertThat(ProfilePhoto.objectKey(user, photo)).isEqualTo("avatares/" + user + "/" + photo + ".jpg");
        assertThat(ProfilePhoto.url("https://app.test/api/v1/avatars/", user, photo))
                .isEqualTo("https://app.test/api/v1/avatars/" + user + "/" + photo + ".jpg");
        assertThat(ProfilePhoto.url("https://app.test/api/v1/avatars", user, photo))
                .isEqualTo("https://app.test/api/v1/avatars/" + user + "/" + photo + ".jpg");
    }

    @Test
    void onlyOurOwnPhotosOfThatAccountAreRecognised() {
        String url = ProfilePhoto.url("https://app.test/api/v1/avatars/", user, photo);
        assertThat(ProfilePhoto.storedKey(url, user)).contains(ProfilePhoto.objectKey(user, photo));
        assertThat(ProfilePhoto.storedKey(url, UUID.randomUUID())).isEmpty();
        assertThat(ProfilePhoto.storedKey("https://lh3.googleusercontent.com/a/xyz", user)).isEmpty();
        assertThat(ProfilePhoto.storedKey(null, user)).isEmpty();
    }

    @Test
    void aRequestedFileMustLookLikeOneOfOurs() {
        assertThat(ProfilePhoto.requestedKey(user, photo + ".jpg")).contains(ProfilePhoto.objectKey(user, photo));
        assertThat(ProfilePhoto.requestedKey(user, "../secreto.pdf")).isEmpty();
        assertThat(ProfilePhoto.requestedKey(user, photo + ".png")).isEmpty();
    }

    @Test
    void reconoceLaFotoDeOtraCuenta() {
        UUID mia = UUID.randomUUID();
        UUID otra = UUID.randomUUID();
        UUID foto = UUID.randomUUID();
        String deOtra = "https://synaptixfit.jloenit.dev/api/v1/avatars/" + otra + "/" + foto + ".jpg";
        String propia = "https://synaptixfit.jloenit.dev/api/v1/avatars/" + mia + "/" + foto + ".jpg";
        assertThat(ProfilePhoto.belongsToAnother(deOtra, mia)).isTrue();
        assertThat(ProfilePhoto.belongsToAnother(propia, mia)).isFalse();
        assertThat(ProfilePhoto.belongsToAnother("https://lh3.googleusercontent.com/a/foto", mia)).isFalse();
        assertThat(ProfilePhoto.belongsToAnother(null, mia)).isFalse();
    }
}
