package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.NoteScanTooLargeException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
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

    /** Una foto de móvil comprimida ocupa 1-4 MB; 10 MB deja margen sin abrir la puerta a vídeos. */
    public static final long MAX_BYTES_PER_PHOTO = 10L * 1024 * 1024;

    /** Por debajo del límite de subida del servidor (25 MB por petición). */
    public static final long MAX_TOTAL_BYTES = 20L * 1024 * 1024;

    /** Formatos que el lector de texto (OCR) sabe abrir. HEIC no: el móvil lo convierte a JPEG al elegir. */
    static final Set<String> SUPPORTED_TYPES = Set.of("image/jpeg", "image/jpg", "image/png", "image/webp");

    public NotePhoto {
        content = content == null ? new byte[0] : content;
        mimeType = mimeType == null ? "" : mimeType.toLowerCase(Locale.ROOT).strip();
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
    }
}
