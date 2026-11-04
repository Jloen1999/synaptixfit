package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** Formato real y tamaño en píxeles leídos de la cabecera, sin descomprimir la imagen. */
public class ImageHeaderTest {

    /** PNG mínimo: firma + bloque IHDR con ancho y alto. */
    public static byte[] png(int width, int height) {
        byte[] b = new byte[33];
        int[] sig = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 'I', 'H', 'D', 'R'};
        for (int i = 0; i < sig.length; i++) {
            b[i] = (byte) sig[i];
        }
        be32(b, 16, width);
        be32(b, 20, height);
        return b;
    }

    /** JPEG mínimo: SOI, un segmento APP0 y el SOF0 con alto y ancho. */
    public static byte[] jpeg(int width, int height) {
        byte[] b = new byte[2 + 18 + 19];
        int i = 0;
        b[i++] = (byte) 0xFF;
        b[i++] = (byte) 0xD8;
        b[i++] = (byte) 0xFF;
        b[i++] = (byte) 0xE0;
        b[i++] = 0;
        b[i++] = 16;
        i += 14;
        b[i++] = (byte) 0xFF;
        b[i++] = (byte) 0xC0;
        b[i++] = 0;
        b[i++] = 17;
        b[i++] = 8;
        b[i++] = (byte) (height >> 8);
        b[i++] = (byte) height;
        b[i++] = (byte) (width >> 8);
        b[i] = (byte) width;
        return b;
    }

    /** WEBP extendido (VP8X) con el tamaño del lienzo. */
    static byte[] webp(int width, int height) {
        byte[] b = new byte[30];
        ascii(b, 0, "RIFF");
        ascii(b, 8, "WEBP");
        ascii(b, 12, "VP8X");
        le24(b, 24, width - 1);
        le24(b, 27, height - 1);
        return b;
    }

    @Test
    void readsFormatAndSizeOfTheThreeAcceptedFormats() {
        assertThat(ImageHeader.read(png(800, 600))).contains(new ImageHeader("image/png", 800, 600));
        assertThat(ImageHeader.read(jpeg(2400, 1800))).contains(new ImageHeader("image/jpeg", 2400, 1800));
        assertThat(ImageHeader.read(webp(1024, 768))).contains(new ImageHeader("image/webp", 1024, 768));
    }

    @Test
    void anythingElseIsNotAnImage() {
        assertThat(ImageHeader.read(new byte[] {1, 2, 3})).isEmpty();
        assertThat(ImageHeader.read(new byte[] {0x49, 0x49, 0x2A, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0})).isEmpty();
        assertThat(ImageHeader.read("GIF89a.........".getBytes())).isEmpty();
        assertThat(ImageHeader.read(png(0, 600))).isEmpty();
    }

    @Test
    void aSmallFileCanDeclareAHugeImage() {
        assertThat(ImageHeader.read(png(50_000, 50_000)).orElseThrow().pixels()).isEqualTo(2_500_000_000L);
    }

    private static void be32(byte[] b, int i, int v) {
        b[i] = (byte) (v >>> 24);
        b[i + 1] = (byte) (v >>> 16);
        b[i + 2] = (byte) (v >>> 8);
        b[i + 3] = (byte) v;
    }

    private static void le24(byte[] b, int i, int v) {
        b[i] = (byte) v;
        b[i + 1] = (byte) (v >>> 8);
        b[i + 2] = (byte) (v >>> 16);
    }

    private static void ascii(byte[] b, int offset, String text) {
        for (int k = 0; k < text.length(); k++) {
            b[offset + k] = (byte) text.charAt(k);
        }
    }
}
