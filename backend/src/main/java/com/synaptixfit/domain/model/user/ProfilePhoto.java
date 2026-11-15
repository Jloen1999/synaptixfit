package com.synaptixfit.domain.model.user;

import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.exception.user.AvatarTooLargeException;
import com.synaptixfit.domain.model.shared.ImageHeader;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Reglas de la foto de perfil subida desde el móvil (ADR 0052): qué se acepta, cómo se guarda y cómo se
 * reconoce una foto propia en la dirección de la cuenta. La usa el caso de uso de la foto de perfil y el
 * borrado de datos (para borrar también el archivo).
 */
public final class ProfilePhoto {

    /** Lado de la foto guardada: de sobra para el avatar más grande de la app (96 px a 3×) y pesa ~40 KB. */
    public static final int SIDE = 512;

    /** Una foto de móvil comprimida ocupa 1-4 MB; el cliente ya la reduce. 10 MB deja margen. */
    public static final long MAX_BYTES = 10L * 1024 * 1024;

    /** Más de 40 MP no aporta nada a un avatar y, descomprimida, dispara la memoria. */
    public static final long MAX_PIXELS = 40_000_000L;

    /** Carpeta del almacenamiento: {@code avatares/<usuario>/<foto>.jpg}. */
    static final String FOLDER = "avatares/";

    private static final Pattern FILE = Pattern.compile(
            "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\\.jpg");
    private static final Pattern OWN_URL = Pattern.compile(
            "/avatars/([0-9a-f-]{36})/" + FILE.pattern() + "$");

    private ProfilePhoto() {
    }

    /**
     * Comprueba la foto antes de abrirla: formato real por su firma (JPEG, PNG o WEBP, no por el nombre ni el
     * tipo que dice el cliente), peso y píxeles. Devuelve la cabecera, con la orientación EXIF.
     */
    public static ImageHeader check(byte[] content) {
        if (content == null || content.length == 0) {
            throw new AvatarInvalidImageException();
        }
        if (content.length > MAX_BYTES) {
            throw new AvatarTooLargeException();
        }
        ImageHeader header = ImageHeader.read(content).orElseThrow(AvatarInvalidImageException::new);
        if (header.pixels() > MAX_PIXELS) {
            throw new AvatarTooLargeException();
        }
        return header;
    }

    /** Clave nueva en el almacenamiento: un nombre distinto en cada cambio, así nadie ve la foto anterior en caché. */
    public static String objectKey(UUID userId, UUID photoId) {
        return folder(userId) + photoId + ".jpg";
    }

    /**
     * Carpeta con todas las fotos de perfil de una cuenta. Al anonimizarla o eliminarla se vacía entera: así se van
     * también las que quedaron sueltas (un borrado que falló o dos subidas a la vez).
     */
    public static String folder(UUID userId) {
        return FOLDER + userId + "/";
    }

    /** Dirección pública de la foto: {@code <prefijo><usuario>/<foto>.jpg}. */
    public static String url(String publicPrefix, UUID userId, UUID photoId) {
        String prefix = publicPrefix.endsWith("/") ? publicPrefix : publicPrefix + "/";
        return prefix + userId + "/" + photoId + ".jpg";
    }

    /**
     * Clave del archivo si la dirección de la cuenta es una foto subida a la app por esa persona; vacío si es de
     * Google, de otra web o de otra cuenta (nunca se borra lo que no es suyo). No mira el dominio a propósito: así
     * sobrevive a un cambio de dirección de la app, y la clave siempre cae en la carpeta de esa cuenta.
     */
    public static Optional<String> storedKey(String avatarUrl, UUID userId) {
        if (avatarUrl == null || userId == null) {
            return Optional.empty();
        }
        Matcher m = OWN_URL.matcher(avatarUrl);
        if (!m.find() || !m.group(1).equals(userId.toString())) {
            return Optional.empty();
        }
        return Optional.of(FOLDER + userId + "/" + m.group(2) + ".jpg");
    }

    /**
     * Si la dirección es una foto subida a la app por otra cuenta. Una cuenta no puede ponerse como suya la foto de
     * otra persona (suplantación), aunque la dirección sea pública.
     */
    public static boolean belongsToAnother(String avatarUrl, UUID userId) {
        if (avatarUrl == null || userId == null) {
            return false;
        }
        Matcher m = OWN_URL.matcher(avatarUrl);
        return m.find() && !m.group(1).equals(userId.toString());
    }

    /** Clave pedida al servir una foto ({@code <foto>.jpg}); vacío si el nombre no tiene esa forma. */
    public static Optional<String> requestedKey(UUID userId, String fileName) {
        if (fileName == null || !FILE.matcher(fileName).matches()) {
            return Optional.empty();
        }
        return Optional.of(FOLDER + userId + "/" + fileName);
    }
}
