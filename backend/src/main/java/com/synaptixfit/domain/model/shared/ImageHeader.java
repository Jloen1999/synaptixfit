package com.synaptixfit.domain.model.shared;

import java.util.Optional;

/**
 * Lee de los primeros bytes de una foto su formato real, su tamaño en píxeles y su orientación EXIF, sin
 * descomprimirla. Lo usan las fotos de apuntes ({@code NotePhoto}) y la foto de perfil ({@code ProfilePhoto})
 * para no fiarse del tipo que declara el cliente ni abrir una imagen enorme que, descomprimida, ocuparía gigas
 * (una «bomba de descompresión»).
 *
 * <p>{@code orientation} es la etiqueta EXIF 0x0112 (1-8): el móvil guarda los píxeles como salen del sensor y
 * apunta cómo hay que girarlos. Una foto vertical de Android suele llegar con 6 (girar 90° a la derecha). Ni
 * Tesseract ni Java la aplican solos: sin girarla, el texto se lee tumbado (ADR 0051).
 */
public record ImageHeader(String mimeType, int width, int height, int orientation) {

    /** Sin etiqueta EXIF (o con un valor raro) se toma la foto tal cual está guardada. */
    public static final int UPRIGHT = 1;

    public ImageHeader {
        orientation = orientation >= 1 && orientation <= 8 ? orientation : UPRIGHT;
    }

    public ImageHeader(String mimeType, int width, int height) {
        this(mimeType, width, height, UPRIGHT);
    }

    /** Formato, dimensiones y orientación, o vacío si los bytes no son un JPEG, PNG o WEBP reconocible. */
    public static Optional<ImageHeader> read(byte[] b) {
        if (b == null || b.length < 12) {
            return Optional.empty();
        }
        if (isPng(b)) {
            return png(b);
        }
        if (u8(b, 0) == 0xFF && u8(b, 1) == 0xD8 && u8(b, 2) == 0xFF) {
            return jpeg(b);
        }
        if (ascii(b, 0, "RIFF") && ascii(b, 8, "WEBP")) {
            return webp(b);
        }
        return Optional.empty();
    }

    public long pixels() {
        return (long) width * height;
    }

    /** Orientaciones 5-8: la imagen se gira un cuarto de vuelta y el ancho pasa a ser el alto. */
    public boolean swapsSides() {
        return orientation >= 5;
    }

    private static boolean isPng(byte[] b) {
        int[] sig = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        for (int i = 0; i < sig.length; i++) {
            if (u8(b, i) != sig[i]) {
                return false;
            }
        }
        return true;
    }

    /** PNG: el primer bloque es siempre IHDR; la orientación, si la hay, va en un bloque eXIf. */
    private static Optional<ImageHeader> png(byte[] b) {
        if (b.length < 24 || !ascii(b, 12, "IHDR")) {
            return Optional.empty();
        }
        int orientation = UPRIGHT;
        int i = 8;
        while (i + 8 <= b.length) {
            long length = be32(b, i);
            if (ascii(b, i + 4, "eXIf")) {
                orientation = tiffOrientation(b, i + 8, (int) Math.min(length, b.length - (i + 8L)));
                break;
            }
            if (ascii(b, i + 4, "IDAT") || ascii(b, i + 4, "IEND") || length > b.length) {
                break;
            }
            i += 12 + (int) length;
        }
        return valid("image/png", be32(b, 16), be32(b, 20), orientation);
    }

    /**
     * JPEG: se recorren los segmentos hasta el marcador SOFn, que lleva alto y ancho. El segmento APP1 «Exif»
     * va siempre antes y trae la orientación.
     */
    private static Optional<ImageHeader> jpeg(byte[] b) {
        int orientation = UPRIGHT;
        int i = 2;
        while (i + 9 < b.length) {
            if (u8(b, i) != 0xFF) {
                return Optional.empty();
            }
            int marker = u8(b, i + 1);
            if (marker == 0xFF) {
                i++;
                continue;
            }
            if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
                i += 2;
                continue;
            }
            int length = be16(b, i + 2);
            boolean sof = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
            if (sof) {
                return valid("image/jpeg", be16(b, i + 7), be16(b, i + 5), orientation);
            }
            if (length < 2) {
                return Optional.empty();
            }
            if (marker == 0xE1 && ascii(b, i + 4, "Exif\0\0")) {
                int start = i + 10;
                orientation = tiffOrientation(b, start, Math.min(length - 8, b.length - start));
            }
            i += 2 + length;
        }
        return Optional.empty();
    }

    /** WEBP: tres variantes (con pérdida, sin pérdida y extendida); solo la extendida puede llevar EXIF. */
    private static Optional<ImageHeader> webp(byte[] b) {
        if (b.length < 30) {
            return Optional.empty();
        }
        if (ascii(b, 12, "VP8 ")) {
            return valid("image/webp", le16(b, 26) & 0x3FFF, le16(b, 28) & 0x3FFF, UPRIGHT);
        }
        if (ascii(b, 12, "VP8L")) {
            int bits = u8(b, 21) | (u8(b, 22) << 8) | (u8(b, 23) << 16) | (u8(b, 24) << 24);
            return valid("image/webp", (bits & 0x3FFF) + 1, ((bits >>> 14) & 0x3FFF) + 1, UPRIGHT);
        }
        if (ascii(b, 12, "VP8X")) {
            return valid("image/webp", le24(b, 24) + 1, le24(b, 27) + 1, webpOrientation(b));
        }
        return Optional.empty();
    }

    /** Recorre los bloques RIFF tras la cabecera VP8X buscando el bloque «EXIF». */
    private static int webpOrientation(byte[] b) {
        int i = 12;
        while (i + 8 <= b.length) {
            long size = le32(b, i + 4);
            if (ascii(b, i, "EXIF")) {
                int start = i + 8;
                // Algunos programas anteponen «Exif\0\0» como en JPEG.
                if (ascii(b, start, "Exif\0\0")) {
                    start += 6;
                    size -= 6;
                }
                return tiffOrientation(b, start, (int) Math.min(size, b.length - (long) start));
            }
            if (size > b.length) {
                return UPRIGHT;
            }
            i += 8 + (int) size + (int) (size & 1);
        }
        return UPRIGHT;
    }

    /**
     * Orientación del primer directorio (IFD0) de un bloque TIFF/EXIF: cabecera «II» (little-endian) o «MM»
     * (big-endian), el número 42 y la posición del directorio; cada entrada mide 12 bytes.
     */
    static int tiffOrientation(byte[] b, int start, int length) {
        int end = start + Math.max(0, length);
        if (start < 0 || end > b.length || length < 8) {
            return UPRIGHT;
        }
        boolean little;
        if (u8(b, start) == 'I' && u8(b, start + 1) == 'I') {
            little = true;
        } else if (u8(b, start) == 'M' && u8(b, start + 1) == 'M') {
            little = false;
        } else {
            return UPRIGHT;
        }
        if (u16(b, start + 2, little) != 42) {
            return UPRIGHT;
        }
        long ifd = u32(b, start + 4, little);
        if (ifd < 8 || start + ifd + 2 > end) {
            return UPRIGHT;
        }
        int dir = start + (int) ifd;
        int entries = u16(b, dir, little);
        for (int k = 0; k < entries; k++) {
            int entry = dir + 2 + k * 12;
            if (entry + 12 > end) {
                return UPRIGHT;
            }
            if (u16(b, entry, little) == 0x0112) {
                int value = u16(b, entry + 8, little);
                return value >= 1 && value <= 8 ? value : UPRIGHT;
            }
        }
        return UPRIGHT;
    }

    private static Optional<ImageHeader> valid(String type, long width, long height, int orientation) {
        if (width <= 0 || height <= 0 || width > Integer.MAX_VALUE || height > Integer.MAX_VALUE) {
            return Optional.empty();
        }
        return Optional.of(new ImageHeader(type, (int) width, (int) height, orientation));
    }

    private static int u8(byte[] b, int i) {
        return i >= 0 && i < b.length ? b[i] & 0xFF : 0;
    }

    private static int be16(byte[] b, int i) {
        return (u8(b, i) << 8) | u8(b, i + 1);
    }

    private static long be32(byte[] b, int i) {
        return ((long) u8(b, i) << 24) | ((long) u8(b, i + 1) << 16) | ((long) u8(b, i + 2) << 8) | u8(b, i + 3);
    }

    private static int le16(byte[] b, int i) {
        return u8(b, i) | (u8(b, i + 1) << 8);
    }

    private static int le24(byte[] b, int i) {
        return u8(b, i) | (u8(b, i + 1) << 8) | (u8(b, i + 2) << 16);
    }

    private static long le32(byte[] b, int i) {
        return u8(b, i) | ((long) u8(b, i + 1) << 8) | ((long) u8(b, i + 2) << 16) | ((long) u8(b, i + 3) << 24);
    }

    private static int u16(byte[] b, int i, boolean little) {
        return little ? le16(b, i) : be16(b, i);
    }

    private static long u32(byte[] b, int i, boolean little) {
        return little ? le32(b, i) : be32(b, i);
    }

    private static boolean ascii(byte[] b, int offset, String text) {
        if (offset < 0 || offset + text.length() > b.length) {
            return false;
        }
        for (int k = 0; k < text.length(); k++) {
            if (b[offset + k] != (byte) text.charAt(k)) {
                return false;
            }
        }
        return true;
    }
}
