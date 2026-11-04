package com.synaptixfit.infrastructure.adapter.input.rest.privacy;

import com.synaptixfit.domain.exception.privacy.LegalDocumentNotFoundException;
import com.synaptixfit.application.port.input.privacy.AcceptLegalTermsUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalAcceptanceUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalDocumentUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.privacy.dto.LegalDtos;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Duration;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Textos legales (ADR 0034). Los documentos son públicos (sin sesión): la app los lee en JSON y la web pública
 * ({@code /privacidad}, {@code /condiciones}, {@code /eliminar-cuenta}, que nginx reenvía aquí) en HTML.
 * Aceptar la política sí requiere sesión.
 */
@Tag(name = "Legal")
@RestController
public class LegalController {

    private final GetLegalDocumentUseCase getDocument;
    private final GetLegalAcceptanceUseCase getAcceptance;
    private final AcceptLegalTermsUseCase accept;

    public LegalController(GetLegalDocumentUseCase getDocument, GetLegalAcceptanceUseCase getAcceptance,
                           AcceptLegalTermsUseCase accept) {
        this.getDocument = getDocument;
        this.getAcceptance = getAcceptance;
        this.accept = accept;
    }

    @GetMapping("/api/v1/legal/{document}")
    public LegalDtos.DocumentResponse document(@PathVariable String document,
                                               @RequestParam(name = "lang", required = false) String language) {
        return LegalDtos.DocumentResponse.from(getDocument.getLegalDocument(document, language));
    }

    @GetMapping(value = "/api/v1/legal/{document}/page", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> page(@PathVariable String document,
                                       @RequestParam(name = "lang", required = false) String language) {
        try {
            String html = LegalHtmlPage.render(getDocument.getLegalDocument(document, language));
            return html(HttpStatus.OK, html)
                    .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePublic())
                    .body(html);
        } catch (LegalDocumentNotFoundException missing) {
            // Esta ruta solo produce HTML: un documento que no existe responde con una página 404 sencilla,
            // no con problem+json (que el navegador no sabría mostrar).
            String html = LegalHtmlPage.notFound(language);
            return html(HttpStatus.NOT_FOUND, html).body(html);
        }
    }

    private static ResponseEntity.BodyBuilder html(HttpStatus status, String body) {
        return ResponseEntity.status(status)
                .contentType(new MediaType(MediaType.TEXT_HTML, java.nio.charset.StandardCharsets.UTF_8))
                // Página estática: ni scripts ni recursos de fuera, solo su propio estilo, y no se puede incrustar
                // en otra web.
                .header("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none';"
                        + " form-action 'none'; frame-ancestors 'none'");
    }

    @GetMapping("/api/v1/me/legal-acceptance")
    public LegalDtos.AcceptanceResponse acceptance(@CurrentUserId UUID userId) {
        return LegalDtos.AcceptanceResponse.from(getAcceptance.getLegalAcceptance(userId));
    }

    @PutMapping("/api/v1/me/legal-acceptance")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void accept(@CurrentUserId UUID userId, @Valid @RequestBody LegalDtos.AcceptRequest request) {
        accept.acceptLegalTerms(userId, request.version());
    }
}
