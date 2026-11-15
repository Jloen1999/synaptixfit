package com.synaptixfit.domain.port.output.user;

/**
 * Prepara la foto de perfil: la pone derecha según su orientación EXIF, recorta el cuadrado central y la reduce
 * a JPEG sin metadatos (ni GPS). Lo usa el caso de uso de la foto de perfil (ADR 0052).
 */
public interface AvatarImagePort {

    /**
     * @throws com.synaptixfit.domain.exception.user.AvatarInvalidImageException si la imagen no se puede abrir
     */
    byte[] squareJpeg(byte[] content, int orientation, int side);
}
