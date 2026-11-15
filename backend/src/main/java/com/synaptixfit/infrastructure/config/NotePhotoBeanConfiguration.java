package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.application.service.academic.NotePhotoService;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import com.synaptixfit.infrastructure.adapter.output.external.gemini.GeminiImageTextReader;
import com.synaptixfit.infrastructure.adapter.output.external.ocr.TesseractImageTextReader;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de «Fotografiar apuntes». Hay dos lectores del mismo puerto: Tesseract (el propio, siempre) y
 * Gemini (con visión, solo de respaldo; ADR 0051), así que aquí se dice cuál es cuál. Sin transacción a
 * propósito: no toca la base de datos y la lectura (OCR + IA) tarda segundos, así que envolverla solo
 * retendría una conexión del pool.
 */
@Configuration
public class NotePhotoBeanConfiguration {

    @Bean
    ReadNotePhotosUseCase readNotePhotosUseCase(TesseractImageTextReader reader, GeminiImageTextReader visionReader,
                                                NoteTidierPort tidier, Clock clock) {
        return new NotePhotoService(reader, visionReader, tidier, clock);
    }
}
