package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.privacy;

import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import com.synaptixfit.domain.port.output.privacy.LegalTextPort;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link LegalTextPort} con los textos de {@code resources/legal/<documento>.<idioma>.md} (ADR 0034).
 * Viajan con la imagen: cambiar un texto es un despliegue, como cambiar el código.
 */
@Component
public class ClasspathLegalTextAdapter implements LegalTextPort {

    /** Solo idiomas de dos letras: nada del usuario llega a la ruta del recurso. */
    private static final Pattern LANGUAGE = Pattern.compile("[a-z]{2}");

    @Override
    public Optional<String> load(LegalDocumentKind kind, String language) {
        if (language == null || !LANGUAGE.matcher(language).matches()) {
            return Optional.empty();
        }
        String path = "legal/" + kind.slug() + "." + language + ".md";
        try (InputStream in = getClass().getClassLoader().getResourceAsStream(path)) {
            return in == null ? Optional.empty() : Optional.of(new String(in.readAllBytes(), StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
