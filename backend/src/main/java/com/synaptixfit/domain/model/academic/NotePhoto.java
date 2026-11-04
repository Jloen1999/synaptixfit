package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.NoteScanTooLargeException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Foto de una página de apuntes en papel que se quiere convertir en apunte. Las reglas de cuántas
 * fotos y de qué tamaño se aceptan viven aquí ({@link #checkBatch}); las usa el caso de uso de lectura.
 */
public record NotePhoto(byte[] content, String mimeType) {

    /** Una sesión de estudio suele dar para unas pocas páginas; más alarga mucho la lectura. */
    public static final int MAX_PHOTOS = 5;

    /**
     * Plazo total para leer y ordenar un lote: el cliente espera como mucho 3 minutos, así que el
     * servidor corta antes para no seguir trabajando para nadie.
     */
    public static final Duration READ_DEADLINE = Duration.ofSeconds(150);

    /** Una foto de móvil comprimida ocupa 1-4 MB; 10 MB deja margen sin abrir la puerta a vídeos. */
    public static final long MAX_BYTES_PER_PHOTO = 10L * 1024 * 1024;

    /** Por debajo del límite de subida del servidor (25 MB por petición). */
    public static final long MAX_TOTAL_BYTES = 20L * 1024 * 1024;

    /**
     * Una foto de móvil tiene 12-50 megapíxeles; el cliente la reduce a 2400 px de lado (≈ 6 MP).
     * Más de 40 MP no aporta nada al leer texto y, descomprimida, dispara la memoria del lector.
     */
    public static final long MAX_PIXELS = 40_000_000L;

    /** Formatos que el lector de texto (OCR) sabe abrir. HEIC no: el móvil lo convierte a JPEG al elegir. */
    static final Set<String> SUPPORTED_TYPES = Set.of("image/jpeg", "image/jpg", "image/png", "image/webp");

    public NotePhoto {
        content = content == null ? new byte[0] : content;
        mimeType = mimeType == null ? "" : mimeType.toLowerCase(Locale.ROOT).strip();
    }

    /** Tipo declarado con el alias «image/jpg» unificado a «image/jpeg». */
    String normalizedType() {
        return "image/jpg".equals(mimeType) ? "image/jpeg" : mimeType;
    }

    /** Comprueba el lote completo antes de leer nada (todo o nada: así el aviso es claro). */
    public static void checkBatch(List<NotePhoto> photos) {
        if (photos == null || photos.isEmpty() || photos.size() > MAX_PHOTOS) {
            throw new NoteScanUnsupportedFileException();
        }
        long total = 0;
        for (NotePhoto photo : photos) {
            if (photo.content().length == 0 || !SUPPORTED_TYPES.contains(photo.mimeType())) {
                throw new NoteScanUnsupportedFileException();
            }
            if (photo.content().length > MAX_BYTES_PER_PHOTO) {
                throw new NoteScanTooLargeException();
            }
            total += photo.content().length;
        }
        if (total > MAX_TOTAL_BYTES) {
            throw new NoteScanTooLargeException();
        }
        for (NotePhoto photo : photos) {
            // El tipo que declara el cliente no basta: se mira la firma real del archivo, porque el
            // lector de imágenes abriría también otros formatos (TIFF, BMP...) con otros riesgos.
            ImageHeader header = ImageHeader.read(photo.content())
                    .orElseThrow(NoteScanUnsupportedFileException::new);
            if (!header.mimeType().equals(photo.normalizedType())) {
                throw new NoteScanUnsupportedFileException();
            }
            if (header.pixels() > MAX_PIXELS) {
                throw new NoteScanTooLargeException();
            }
        }
    }
}
