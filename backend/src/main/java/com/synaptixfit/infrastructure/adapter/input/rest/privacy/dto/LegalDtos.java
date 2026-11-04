package com.synaptixfit.infrastructure.adapter.input.rest.privacy.dto;

import com.synaptixfit.application.port.input.privacy.GetLegalAcceptanceUseCase;
import com.synaptixfit.domain.model.privacy.LegalBlock;
import com.synaptixfit.domain.model.privacy.LegalDocument;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

/** DTOs de los textos legales y su aceptación (ADR 0034). */
public final class LegalDtos {

    private LegalDtos() {
    }

    /**
     * Texto legal listo para pintar.
     *
     * @param contactConfigured el servidor tiene responsable y correo; si no, el texto dice «pendiente»
     */
    @Schema(name = "LegalDocumentResponse")
    public record DocumentResponse(String kind, String language, String version, String title,
                                   List<BlockResponse> blocks, boolean contactConfigured) {

        public static DocumentResponse from(LegalDocument d) {
            return new DocumentResponse(d.kind().slug(), d.language(), d.version(), d.title(),
                    d.blocks().stream().map(BlockResponse::from).toList(), d.contactConfigured());
        }
    }

    /** Un bloque: {@code HEADING}, {@code PARAGRAPH} o {@code BULLET}. */
    @Schema(name = "LegalBlockResponse")
    public record BlockResponse(LegalBlock.Type type, String text) {

        static BlockResponse from(LegalBlock b) {
            return new BlockResponse(b.type(), b.text());
        }
    }

    /** Si hay que aceptar la versión vigente y cuál se aceptó por última vez. */
    @Schema(name = "LegalAcceptanceResponse")
    public record AcceptanceResponse(String currentVersion, String acceptedVersion, Instant acceptedAt,
                                     boolean required) {

        public static AcceptanceResponse from(GetLegalAcceptanceUseCase.Status s) {
            return new AcceptanceResponse(s.currentVersion(), s.acceptedVersion(), s.acceptedAt(), s.required());
        }
    }

    /** La versión que la persona ha leído y acepta. */
    @Schema(name = "AcceptLegalTermsRequest")
    public record AcceptRequest(@NotBlank @Size(max = 20) String version) {
    }
}
