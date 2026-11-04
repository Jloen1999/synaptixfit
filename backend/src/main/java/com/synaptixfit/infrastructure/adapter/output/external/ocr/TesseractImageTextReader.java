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
import java.util.ArrayList;
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
 * limitan las lecturas a la vez, cada una usa un solo hilo ({@code OMP_THREAD_LIMIT=1}) y, si se
 * configura, se lanza con un tope de memoria ({@code prlimit --as}): si una imagen rara se escapa a las
 * comprobaciones, el sistema corta solo a Tesseract y no a la JVM, que comparte el contenedor.
 */
@Component
public class TesseractImageTextReader implements ImageTextReaderPort {

    private final String command;
    private final long timeoutSeconds;
    private final long queueWaitSeconds;
    private final long memoryLimitMb;
    private final Semaphore slots;

    public TesseractImageTextReader(@Value("${synaptixfit.ocr.command:tesseract}") String command,
                                    @Value("${synaptixfit.ocr.timeout-seconds:60}") long timeoutSeconds,
                                    @Value("${synaptixfit.ocr.max-concurrent:2}") int maxConcurrent,
                                    @Value("${synaptixfit.ocr.queue-wait-seconds:10}") long queueWaitSeconds,
                                    @Value("${synaptixfit.ocr.memory-limit-mb:0}") long memoryLimitMb) {
        this.command = command;
        this.timeoutSeconds = timeoutSeconds;
        this.queueWaitSeconds = queueWaitSeconds;
        this.memoryLimitMb = memoryLimitMb;
        this.slots = new Semaphore(Math.max(1, maxConcurrent));
    }

    @Override
    public String read(NotePhoto photo) {
        boolean acquired;
        try {
            // Espera corta: si el lector está ocupado, es mejor decirlo pronto que dejar a la persona
            // mirando una barra hasta que el cliente se canse.
            acquired = slots.tryAcquire(queueWaitSeconds, TimeUnit.SECONDS);
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
        List<String> args = commandLine(command, memoryLimitMb, languages(RequestLanguage.code()));
        Process process;
        try {
            ProcessBuilder builder = new ProcessBuilder(args);
            builder.environment().put("OMP_THREAD_LIMIT", "1");
            process = builder.start();
        } catch (IOException e) {
            // El programa no está instalado (p. ej. en un equipo de desarrollo sin Tesseract).
            throw new NoteScanUnavailableException("OCR program not available");
        }
        CompletableFuture<byte[]> out = CompletableFuture.supplyAsync(() -> drain(process.getInputStream()));
        CompletableFuture<byte[]> err = CompletableFuture.supplyAsync(() -> drain(process.getErrorStream()));
        // La foto se escribe en otro hilo: si Tesseract se cuelga sin leerla, el tiempo límite de abajo
        // sigue mandando y este hilo no se queda bloqueado para siempre.
        CompletableFuture<Boolean> written =
                CompletableFuture.supplyAsync(() -> write(process.getOutputStream(), image));
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
            if (!written.get(5, TimeUnit.SECONDS)) {
                throw new NoteScanUnsupportedFileException();
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

    /**
     * Orden a ejecutar, sin shell y con argumentos fijos. {@code --psm 3}: página con columnas y
     * párrafos (lo normal en unos apuntes). Con tope de memoria, se antepone {@code prlimit}.
     */
    static List<String> commandLine(String command, long memoryLimitMb, String languages) {
        List<String> args = new ArrayList<>();
        if (memoryLimitMb > 0) {
            args.addAll(List.of("prlimit", "--as=" + memoryLimitMb * 1024 * 1024, "--"));
        }
        args.addAll(List.of(command, "stdin", "stdout", "-l", languages, "--psm", "3"));
        return args;
    }

    private static boolean write(OutputStream stream, byte[] image) {
        try (stream) {
            stream.write(image);
            return true;
        } catch (IOException e) {
            return false;
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
