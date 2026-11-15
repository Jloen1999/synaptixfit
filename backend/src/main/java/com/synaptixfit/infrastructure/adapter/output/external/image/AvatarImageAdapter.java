package com.synaptixfit.infrastructure.adapter.output.external.image;

import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.port.output.user.AvatarImagePort;
import java.util.concurrent.Semaphore;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link AvatarImagePort} con {@link ImagePixels}: abre la foto ya reducida, recorta el cuadrado central
 * (el mismo que enseña la vista previa del móvil), la reduce y la gira según su orientación EXIF. Recortar antes de
 * girar da el mismo cuadrado y mueve muchos menos píxeles. Como mucho dos a la vez, por la memoria.
 */
@Component
public class AvatarImageAdapter implements AvatarImagePort {

    /** Para recortar un avatar de 512 px no hace falta abrir la foto a más de 2048 px. */
    static final int OPEN_SIDE = 2048;

    private final Semaphore slots = new Semaphore(2);

    @Override
    public byte[] squareJpeg(byte[] content, int orientation, int side) {
        slots.acquireUninterruptibly();
        try {
            return ImagePixels.decode(content, OPEN_SIDE)
                    .map(image -> ImagePixels.jpeg(
                            ImagePixels.orient(ImagePixels.centerSquare(image, side), orientation), 0.85f))
                    .orElseThrow(AvatarInvalidImageException::new);
        } finally {
            slots.release();
        }
    }
}
