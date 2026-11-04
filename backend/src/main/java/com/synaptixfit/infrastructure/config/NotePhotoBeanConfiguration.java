package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.ReadNotePhotosUseCase;
import com.synaptixfit.application.service.academic.NotePhotoService;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de «Fotografiar apuntes». Sin transacción a propósito: no toca la base de datos y la
 * lectura (OCR + IA) tarda segundos, así que envolverla solo retendría una conexión del pool.
 */
@Configuration
public class NotePhotoBeanConfiguration {

    @Bean
    ReadNotePhotosUseCase readNotePhotosUseCase(ImageTextReaderPort reader, NoteTidierPort tidier) {
        return new NotePhotoService(reader, tidier);
    }
}
