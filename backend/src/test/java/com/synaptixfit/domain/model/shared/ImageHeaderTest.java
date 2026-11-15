package com.synaptixfit.domain.model.shared;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Formato real, tamaño en píxeles y orientación EXIF leídos de la cabecera, sin descomprimir la imagen. */
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
    public static byte[] webp(int width, int height) {
        byte[] b = new byte[30];
        ascii(b, 0, "RIFF");
        ascii(b, 8, "WEBP");
        ascii(b, 12, "VP8X");
        le24(b, 24, width - 1);
        le24(b, 27, height - 1);
        return b;
    }

    /** Bloque TIFF mínimo con la etiqueta Orientation (0x0112) en el primer directorio. */
    public static byte[] exifTiff(int orientation, boolean littleEndian) {
        byte[] t = new byte[8 + 2 + 2 * 12 + 4];
        t[0] = t[1] = (byte) (littleEndian ? 'I' : 'M');
        put16(t, 2, 42, littleEndian);
        put32(t, 4, 8, littleEndian);
        put16(t, 8, 2, littleEndian);
        // Una entrada cualquiera antes (ImageWidth) para comprobar que se recorre el directorio.
        put16(t, 10, 0x0100, littleEndian);
        put16(t, 12, 3, littleEndian);
        put32(t, 14, 1, littleEndian);
        put16(t, 18, 640, littleEndian);
        put16(t, 22, 0x0112, littleEndian);
        put16(t, 24, 3, littleEndian);
        put32(t, 26, 1, littleEndian);
        put16(t, 30, orientation, littleEndian);
        return t;
    }

    /** Inserta un segmento APP1 «Exif» con la orientación justo después del SOI de un JPEG. */
    public static byte[] withExifOrientation(byte[] jpeg, int orientation) {
        byte[] tiff = exifTiff(orientation, orientation % 2 == 0);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(jpeg, 0, 2);
        int length = 2 + 6 + tiff.length;
        out.write(0xFF);
        out.write(0xE1);
        out.write(length >> 8);
        out.write(length & 0xFF);
        out.writeBytes("Exif\0\0".getBytes(java.nio.charset.StandardCharsets.ISO_8859_1));
        out.writeBytes(tiff);
        out.write(jpeg, 2, jpeg.length - 2);
        return out.toByteArray();
    }

    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5, 6, 7, 8})
    void readsTheExifOrientationOfAJpeg(int orientation) {
        ImageHeader header = ImageHeader.read(withExifOrientation(jpeg(2400, 1800), orientation)).orElseThrow();
        assertThat(header).isEqualTo(new ImageHeader("image/jpeg", 2400, 1800, orientation));
        assertThat(header.swapsSides()).isEqualTo(orientation >= 5);
    }

    @Test
    void readsTheExifOrientationOfWebpAndPng() {
        byte[] tiff = exifTiff(6, true);
        byte[] base = webp(1024, 768);
        byte[] webp = new byte[base.length + 8 + tiff.length];
        System.arraycopy(base, 0, webp, 0, base.length);
        // El bloque VP8X mide 10 bytes de datos: el siguiente empieza en 12 + 8 + 10 = 30.
        webp[16] = 10;
        ascii(webp, 30, "EXIF");
        le24(webp, 34, tiff.length);
        System.arraycopy(tiff, 0, webp, 38, tiff.length);
        assertThat(ImageHeader.read(webp).orElseThrow().orientation()).isEqualTo(6);

        byte[] png = png(800, 600);
        byte[] withExif = new byte[png.length + 12 + tiff.length];
        System.arraycopy(png, 0, withExif, 0, png.length);
        be32(withExif, 33, tiff.length);
        ascii(withExif, 37, "eXIf");
        System.arraycopy(tiff, 0, withExif, 41, tiff.length);
        assertThat(ImageHeader.read(withExif).orElseThrow().orientation()).isEqualTo(6);
    }

    @Test
    void withoutExifOrWithARareValueThePhotoIsUpright() {
        assertThat(ImageHeader.read(jpeg(10, 10)).orElseThrow().orientation()).isEqualTo(ImageHeader.UPRIGHT);
        assertThat(ImageHeader.read(withExifOrientation(jpeg(10, 10), 9)).orElseThrow().orientation())
                .isEqualTo(ImageHeader.UPRIGHT);
        byte[] broken = withExifOrientation(jpeg(10, 10), 6);
        broken[10] = 'X';
        assertThat(ImageHeader.read(broken).orElseThrow().orientation()).isEqualTo(ImageHeader.UPRIGHT);
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

    private static void put16(byte[] b, int i, int v, boolean little) {
        b[i] = (byte) (little ? v : v >>> 8);
        b[i + 1] = (byte) (little ? v >>> 8 : v);
    }

    private static void put32(byte[] b, int i, int v, boolean little) {
        for (int k = 0; k < 4; k++) {
            b[i + k] = (byte) (v >>> (little ? 8 * k : 8 * (3 - k)));
        }
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
