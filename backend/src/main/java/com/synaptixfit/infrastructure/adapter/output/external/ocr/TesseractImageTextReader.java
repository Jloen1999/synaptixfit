package com.synaptixfit.infrastructure.adapter.output.external.ocr;

import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ImageTextReaderPort} con el programa Tesseract (OCR libre, instalado en la imagen
 * Docker del backend; ADR 0040). La foto entra por la entrada estándar y el texto sale por la salida
 * estándar: no se escribe nada en disco.
 *
 * <p>Cada lectura es un proceso aparte (100-200 MB de memoria y unos segundos de CPU), así que se
 * limitan las lecturas a la vez para no asfixiar al servidor.
 */
@Component
public class TesseractImageTextReader implements ImageTextReaderPort {

    private final String command;
    private final long timeoutSeconds;
    private final Semaphore slots;

    public TesseractImageTextReader(@Value("${synaptixfit.ocr.command:tesseract}") String command,
                                    @Value("${synaptixfit.ocr.timeout-seconds:60}") long timeoutSeconds,
                                    @Value("${synaptixfit.ocr.max-concurrent:2}") int maxConcurrent) {
        this.command = command;
        this.timeoutSeconds = timeoutSeconds;
        this.slots = new Semaphore(Math.max(1, maxConcurrent));
    }

    @Override
    public String read(NotePhoto photo) {
        boolean acquired;
        try {
            acquired = slots.tryAcquire(timeoutSeconds, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new NoteScanUnavailableException("Interrupted while waiting for OCR");
        }
        if (!acquired) {
            throw new NoteScanUnavailableException("OCR is busy");
        }
        try {
            return run(photo.content());
        } finally {
            slots.release();
        }
    }

    private String run(byte[] image) {
        // --psm 3: página con columnas y párrafos (lo normal en unos apuntes).
        List<String> args = List.of(command, "stdin", "stdout", "-l", languages(RequestLanguage.code()),
                "--psm", "3");
        Process process;
        try {
            process = new ProcessBuilder(args).start();
        } catch (IOException e) {
            // El programa no está instalado (p. ej. en un equipo de desarrollo sin Tesseract).
            throw new NoteScanUnavailableException("OCR program not available");
        }
        CompletableFuture<byte[]> out = CompletableFuture.supplyAsync(() -> drain(process.getInputStream()));
        CompletableFuture<byte[]> err = CompletableFuture.supplyAsync(() -> drain(process.getErrorStream()));
        try (OutputStream in = process.getOutputStream()) {
            in.write(image);
        } catch (IOException e) {
            process.destroyForcibly();
            throw new NoteScanUnsupportedFileException();
        }
        try {
            if (!process.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
                process.destroyForcibly();
                throw new NoteScanUnavailableException("OCR timed out");
            }
            String text = new String(out.get(5, TimeUnit.SECONDS), StandardCharsets.UTF_8);
            if (process.exitValue() != 0) {
                String error = new String(err.get(5, TimeUnit.SECONDS), StandardCharsets.UTF_8);
                throw unreadableImage(error) ? new NoteScanUnsupportedFileException()
                        : new NoteScanUnavailableException("OCR failed with exit code " + process.exitValue());
            }
            return text;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            process.destroyForcibly();
            throw new NoteScanUnavailableException("Interrupted while reading");
        } catch (java.util.concurrent.ExecutionException | java.util.concurrent.TimeoutException e) {
            throw new NoteScanUnavailableException("Could not read OCR output");
        }
    }

    /** Leptonica (la librería de imágenes de Tesseract) no pudo abrir la foto: el archivo no es una imagen válida. */
    static boolean unreadableImage(String stderr) {
        String s = stderr == null ? "" : stderr.toLowerCase(Locale.ROOT);
        return s.contains("pixread") || s.contains("image file") || s.contains("unsupported image")
                || s.contains("read error");
    }

    /**
     * Diccionarios de Tesseract según el idioma de la app, con el inglés de apoyo (muchos apuntes
     * técnicos mezclan términos en inglés). Más idiomas a la vez lo harían más lento y menos preciso.
     */
    static String languages(String appLanguage) {
        return switch (appLanguage == null ? "" : appLanguage) {
            case "en" -> "eng";
            case "fr" -> "fra+eng";
            case "pt" -> "por+eng";
            default -> "spa+eng";
        };
    }

    private static byte[] drain(InputStream stream) {
        try (stream; ByteArrayOutputStream buffer = new ByteArrayOutputStream()) {
            stream.transferTo(buffer);
            return buffer.toByteArray();
        } catch (IOException e) {
            return new byte[0];
        }
    }
}
