package com.synaptixfit.domain.model.academic;

import java.util.Optional;

/**
 * Lee de los primeros bytes de una foto su formato real y su tamaño en píxeles, sin descomprimirla.
 * Lo usa {@link NotePhoto} para no fiarse del tipo que declara el cliente ni pasar al lector de texto
 * (OCR) una imagen enorme que, descomprimida, ocuparía gigas (una «bomba de descompresión»).
 */
public record ImageHeader(String mimeType, int width, int height) {

    /** Formato y dimensiones de la imagen, o vacío si los bytes no son un JPEG, PNG o WEBP reconocible. */
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

    private static boolean isPng(byte[] b) {
        int[] sig = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        for (int i = 0; i < sig.length; i++) {
            if (u8(b, i) != sig[i]) {
                return false;
            }
        }
        return true;
    }

    /** PNG: el primer bloque es siempre IHDR, con ancho y alto en 4 bytes cada uno. */
    private static Optional<ImageHeader> png(byte[] b) {
        if (b.length < 24 || !ascii(b, 12, "IHDR")) {
            return Optional.empty();
        }
        return valid("image/png", be32(b, 16), be32(b, 20));
    }

    /** JPEG: se recorren los segmentos hasta el marcador SOFn, que lleva alto y ancho. */
    private static Optional<ImageHeader> jpeg(byte[] b) {
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
                return valid("image/jpeg", be16(b, i + 7), be16(b, i + 5));
            }
            if (length < 2) {
                return Optional.empty();
            }
            i += 2 + length;
        }
        return Optional.empty();
    }

    /** WEBP: tres variantes (con pérdida, sin pérdida y extendida), cada una con su cabecera. */
    private static Optional<ImageHeader> webp(byte[] b) {
        if (b.length < 30) {
            return Optional.empty();
        }
        if (ascii(b, 12, "VP8 ")) {
            return valid("image/webp", le16(b, 26) & 0x3FFF, le16(b, 28) & 0x3FFF);
        }
        if (ascii(b, 12, "VP8L")) {
            int bits = u8(b, 21) | (u8(b, 22) << 8) | (u8(b, 23) << 16) | (u8(b, 24) << 24);
            return valid("image/webp", (bits & 0x3FFF) + 1, ((bits >>> 14) & 0x3FFF) + 1);
        }
        if (ascii(b, 12, "VP8X")) {
            return valid("image/webp", le24(b, 24) + 1, le24(b, 27) + 1);
        }
        return Optional.empty();
    }

    private static Optional<ImageHeader> valid(String type, long width, long height) {
        if (width <= 0 || height <= 0 || width > Integer.MAX_VALUE || height > Integer.MAX_VALUE) {
            return Optional.empty();
        }
        return Optional.of(new ImageHeader(type, (int) width, (int) height));
    }

    private static int u8(byte[] b, int i) {
        return b[i] & 0xFF;
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

    private static boolean ascii(byte[] b, int offset, String text) {
        if (offset + text.length() > b.length) {
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
