package com.synaptixfit.infrastructure.adapter.output.external.image;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Iterator;
import java.util.Optional;
import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageReadParam;
import javax.imageio.ImageReader;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageInputStream;
import javax.imageio.stream.MemoryCacheImageOutputStream;

/**
 * Operaciones de píxeles con la librería de imágenes de Java (sin dependencias nativas; WEBP con el lector
 * TwelveMonkeys, ADR 0051): abrir reduciendo, girar según la orientación EXIF, pasar a gris, recortar al cuadrado
 * y guardar en PNG o JPEG. La usan los lectores de fotos de apuntes (Tesseract, Gemini) y la foto de perfil.
 *
 * <p>Memoria: una foto de 6 MP abierta en color ocupa unos 18 MB; se abre ya reducida (submuestreo al leer, sin
 * pasar por el tamaño completo) y quien llama procesa de una en una.
 */
public final class ImagePixels {

    static {
        // En el jar de Spring Boot los lectores extra (WEBP) van en un jar anidado: se registran con el cargador
        // de clases de la app, que es el de quien carga esta clase.
        ImageIO.scanForPlugins();
        ImageIO.setUseCache(false);
    }

    private ImagePixels() {
    }

    /**
     * Abre la imagen con el lado mayor como mucho {@code maxSide} (submuestreo entero al leer). Vacío si Java no
     * sabe abrirla (formato raro, JPEG en CMYK, archivo roto).
     */
    public static Optional<BufferedImage> decode(byte[] content, int maxSide) {
        try (ImageInputStream in = ImageIO.createImageInputStream(new ByteArrayInputStream(content))) {
            if (in == null) {
                return Optional.empty();
            }
            Iterator<ImageReader> readers = ImageIO.getImageReaders(in);
            if (!readers.hasNext()) {
                return Optional.empty();
            }
            ImageReader reader = readers.next();
            try {
                reader.setInput(in, true, true);
                int longest = Math.max(reader.getWidth(0), reader.getHeight(0));
                ImageReadParam param = reader.getDefaultReadParam();
                int step = (int) Math.ceil(longest / (double) Math.max(1, maxSide));
                if (step > 1) {
                    param.setSourceSubsampling(step, step, 0, 0);
                }
                return Optional.ofNullable(reader.read(0, param));
            } finally {
                reader.dispose();
            }
        } catch (IOException | RuntimeException e) {
            return Optional.empty();
        }
    }

    /**
     * Gira o voltea los píxeles según la orientación EXIF (1-8) para que la imagen quede como se ve en el móvil.
     * Las 8 orientaciones son las del estándar EXIF 2.3 (etiqueta 0x0112): 2 espejo horizontal, 3 media vuelta,
     * 4 espejo vertical, 5 trasponer, 6 girar 90° a la derecha, 7 trasponer al revés y 8 girar 90° a la izquierda.
     */
    public static BufferedImage orient(BufferedImage src, int orientation) {
        if (orientation < 2 || orientation > 8) {
            return src;
        }
        int w = src.getWidth();
        int h = src.getHeight();
        boolean swap = orientation >= 5;
        int dw = swap ? h : w;
        int dh = swap ? w : h;
        if (src.getType() == BufferedImage.TYPE_BYTE_GRAY) {
            byte[] in = ((DataBufferByte) src.getRaster().getDataBuffer()).getData();
            BufferedImage dst = new BufferedImage(dw, dh, BufferedImage.TYPE_BYTE_GRAY);
            byte[] out = ((DataBufferByte) dst.getRaster().getDataBuffer()).getData();
            for (int y = 0; y < dh; y++) {
                for (int x = 0; x < dw; x++) {
                    out[y * dw + x] = in[sourceIndex(orientation, x, y, w, h)];
                }
            }
            return dst;
        }
        int[] in = src.getRGB(0, 0, w, h, null, 0, w);
        int[] out = new int[in.length];
        for (int y = 0; y < dh; y++) {
            for (int x = 0; x < dw; x++) {
                out[y * dw + x] = in[sourceIndex(orientation, x, y, w, h)];
            }
        }
        BufferedImage dst = new BufferedImage(dw, dh,
                src.getColorModel().hasAlpha() ? BufferedImage.TYPE_INT_ARGB : BufferedImage.TYPE_INT_RGB);
        dst.setRGB(0, 0, dw, dh, out, 0, dw);
        return dst;
    }

    /** Píxel de origen (imagen guardada, {@code w}×{@code h}) que acaba en (x, y) de la imagen girada. */
    static int sourceIndex(int orientation, int x, int y, int w, int h) {
        int sx;
        int sy;
        switch (orientation) {
            case 2 -> { sx = w - 1 - x; sy = y; }
            case 3 -> { sx = w - 1 - x; sy = h - 1 - y; }
            case 4 -> { sx = x; sy = h - 1 - y; }
            case 5 -> { sx = y; sy = x; }
            case 6 -> { sx = y; sy = h - 1 - x; }
            case 7 -> { sx = w - 1 - y; sy = h - 1 - x; }
            case 8 -> { sx = w - 1 - y; sy = x; }
            default -> { sx = x; sy = y; }
        }
        return sy * w + sx;
    }

    /** Escala de grises de 8 bits; lo transparente se pinta blanco (como el papel), no negro. */
    public static BufferedImage gray(BufferedImage src) {
        if (src.getType() == BufferedImage.TYPE_BYTE_GRAY) {
            return src;
        }
        BufferedImage gray = new BufferedImage(src.getWidth(), src.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        Graphics2D g = gray.createGraphics();
        try {
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, src.getWidth(), src.getHeight());
            g.drawImage(src, 0, 0, null);
        } finally {
            g.dispose();
        }
        return gray;
    }

    /**
     * Recorta el cuadrado central (el mismo que enseña la vista previa del móvil) y lo reduce a {@code side} px
     * de lado como mucho (no amplía). Reduce a mitades sucesivas para que no salga dentado.
     */
    public static BufferedImage centerSquare(BufferedImage src, int side) {
        int square = Math.min(src.getWidth(), src.getHeight());
        BufferedImage current = src.getSubimage((src.getWidth() - square) / 2, (src.getHeight() - square) / 2,
                square, square);
        int target = Math.min(side, square);
        int size = square;
        do {
            size = Math.max(target, size / 2);
            current = resize(current, size);
        } while (size > target);
        return current;
    }

    private static BufferedImage resize(BufferedImage src, int size) {
        BufferedImage out = new BufferedImage(size, size, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, size, size);
            g.drawImage(src, 0, 0, size, size, null);
        } finally {
            g.dispose();
        }
        return out;
    }

    public static byte[] png(BufferedImage image) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            if (!ImageIO.write(image, "png", out)) {
                throw new IllegalStateException("No PNG writer");
            }
        } catch (IOException e) {
            throw new IllegalStateException("Could not encode PNG", e);
        }
        return out.toByteArray();
    }

    /** JPEG sin metadatos (ni EXIF ni GPS: la imagen ya va girada). Lo transparente pasa a blanco. */
    public static byte[] jpeg(BufferedImage image, float quality) {
        BufferedImage rgb = image;
        if (image.getType() != BufferedImage.TYPE_INT_RGB && image.getType() != BufferedImage.TYPE_BYTE_GRAY) {
            rgb = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
            Graphics2D g = rgb.createGraphics();
            try {
                g.setColor(Color.WHITE);
                g.fillRect(0, 0, image.getWidth(), image.getHeight());
                g.drawImage(image, 0, 0, null);
            } finally {
                g.dispose();
            }
        }
        ImageWriter writer = ImageIO.getImageWritersByFormatName("jpeg").next();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (MemoryCacheImageOutputStream stream = new MemoryCacheImageOutputStream(out)) {
            writer.setOutput(stream);
            ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(quality);
            writer.write(null, new IIOImage(rgb, null, null), param);
        } catch (IOException e) {
            throw new IllegalStateException("Could not encode JPEG", e);
        } finally {
            writer.dispose();
        }
        return out.toByteArray();
    }
}
