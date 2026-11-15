package com.synaptixfit.infrastructure.adapter.output.external.image;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import com.synaptixfit.domain.model.shared.ImageHeader;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;

/** Foto de perfil: cuadrada, como mucho del lado pedido, derecha y en JPEG sin EXIF. */
class AvatarImageAdapterTest {

    private final AvatarImageAdapter adapter = new AvatarImageAdapter();

    @Test
    void aVerticalPhoneSelfieBecomesAnUprightSquareJpeg() throws Exception {
        // Guardada tumbada (800×600) con EXIF 6: en el móvil se ve vertical. La mitad izquierda guardada (negra)
        // es, una vez girada, la mitad de arriba.
        BufferedImage stored = new BufferedImage(800, 600, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = stored.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, 800, 600);
        g.setColor(Color.BLACK);
        g.fillRect(0, 0, 400, 600);
        g.dispose();
        byte[] photo = ImageHeaderTest.withExifOrientation(ImagePixels.jpeg(stored, 0.95f), 6);

        byte[] out = adapter.squareJpeg(photo, 6, 256);

        ImageHeader header = ImageHeader.read(out).orElseThrow();
        assertThat(header.mimeType()).isEqualTo("image/jpeg");
        assertThat(header.width()).isEqualTo(256);
        assertThat(header.height()).isEqualTo(256);
        assertThat(header.orientation()).isEqualTo(ImageHeader.UPRIGHT);
        BufferedImage image = ImageIO.read(new ByteArrayInputStream(out));
        assertThat(new Color(image.getRGB(128, 20)).getRed()).isLessThan(60);
        assertThat(new Color(image.getRGB(128, 236)).getRed()).isGreaterThan(200);
    }

    @Test
    void aTransparentPngGetsAWhiteBackground() throws Exception {
        BufferedImage clear = new BufferedImage(100, 100, BufferedImage.TYPE_INT_ARGB);
        java.io.ByteArrayOutputStream png = new java.io.ByteArrayOutputStream();
        ImageIO.write(clear, "png", png);

        BufferedImage out = ImageIO.read(new ByteArrayInputStream(adapter.squareJpeg(png.toByteArray(), 1, 512)));

        assertThat(out.getWidth()).isEqualTo(100);
        assertThat(new Color(out.getRGB(50, 50)).getRed()).isGreaterThan(240);
    }

    @Test
    void whatCannotBeOpenedIsAnInvalidImage() {
        assertThatThrownBy(() -> adapter.squareJpeg(ImageHeaderTest.jpeg(10, 10), 1, 512))
                .isInstanceOf(AvatarInvalidImageException.class);
    }
}
