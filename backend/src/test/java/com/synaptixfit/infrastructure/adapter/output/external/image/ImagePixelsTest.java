package com.synaptixfit.infrastructure.adapter.output.external.image;

import static org.assertj.core.api.Assertions.assertThat;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Giro según la orientación EXIF, paso a gris, recorte cuadrado y formatos de salida. */
class ImagePixelsTest {

    /**
     * Imagen guardada de 3×2 en gris (a b c / d e f) y cómo debe verse con cada orientación EXIF 2.3:
     * espejo, media vuelta, trasponer y los dos cuartos de vuelta.
     */
    private static final Map<Integer, int[][]> EXPECTED = Map.of(
            1, new int[][] {{10, 20, 30}, {40, 50, 60}},
            2, new int[][] {{30, 20, 10}, {60, 50, 40}},
            3, new int[][] {{60, 50, 40}, {30, 20, 10}},
            4, new int[][] {{40, 50, 60}, {10, 20, 30}},
            5, new int[][] {{10, 40}, {20, 50}, {30, 60}},
            6, new int[][] {{40, 10}, {50, 20}, {60, 30}},
            7, new int[][] {{60, 30}, {50, 20}, {40, 10}},
            8, new int[][] {{30, 60}, {20, 50}, {10, 40}});

    private static BufferedImage abcdef() {
        BufferedImage img = new BufferedImage(3, 2, BufferedImage.TYPE_BYTE_GRAY);
        byte[] data = ((DataBufferByte) img.getRaster().getDataBuffer()).getData();
        for (int i = 0; i < 6; i++) {
            data[i] = (byte) (10 * (i + 1));
        }
        return img;
    }

    private static int[][] grayRows(BufferedImage img) {
        int[][] rows = new int[img.getHeight()][img.getWidth()];
        for (int y = 0; y < img.getHeight(); y++) {
            for (int x = 0; x < img.getWidth(); x++) {
                rows[y][x] = img.getRaster().getSample(x, y, 0);
            }
        }
        return rows;
    }

    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5, 6, 7, 8})
    void eachExifOrientationMovesThePixelsWhereThePhoneShowsThem(int orientation) {
        assertThat(grayRows(ImagePixels.orient(abcdef(), orientation))).isDeepEqualTo(EXPECTED.get(orientation));
    }

    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5, 6, 7, 8})
    void colourImagesTurnTheSameWayAsGrayOnes(int orientation) {
        BufferedImage rgb = new BufferedImage(3, 2, BufferedImage.TYPE_INT_RGB);
        for (int i = 0; i < 6; i++) {
            int v = 10 * (i + 1);
            rgb.setRGB(i % 3, i / 3, new Color(v, v, v).getRGB());
        }
        BufferedImage turned = ImagePixels.orient(rgb, orientation);
        int[][] expected = EXPECTED.get(orientation);
        for (int y = 0; y < expected.length; y++) {
            for (int x = 0; x < expected[y].length; x++) {
                assertThat(turned.getRGB(x, y) & 0xFF).isEqualTo(expected[y][x]);
            }
        }
    }

    @Test
    void bigPhotosAreOpenedAlreadyReduced() {
        BufferedImage big = new BufferedImage(1200, 600, BufferedImage.TYPE_INT_RGB);
        BufferedImage opened = ImagePixels.decode(ImagePixels.jpeg(big, 0.8f), 500).orElseThrow();
        assertThat(Math.max(opened.getWidth(), opened.getHeight())).isLessThanOrEqualTo(500);
        assertThat(ImagePixels.decode(new byte[] {1, 2, 3, 4}, 500)).isEmpty();
    }

    @Test
    void theCentreSquareIsKeptAndReducedWithoutEnlarging() {
        BufferedImage wide = new BufferedImage(900, 300, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = wide.createGraphics();
        g.setColor(Color.RED);
        g.fillRect(300, 0, 300, 300);
        g.dispose();
        BufferedImage square = ImagePixels.centerSquare(wide, 128);
        assertThat(square.getWidth()).isEqualTo(128);
        assertThat(square.getHeight()).isEqualTo(128);
        assertThat(new Color(square.getRGB(64, 64)).getRed()).isGreaterThan(200);
        assertThat(ImagePixels.centerSquare(new BufferedImage(100, 60, BufferedImage.TYPE_INT_RGB), 512).getWidth())
                .isEqualTo(60);
    }
}
