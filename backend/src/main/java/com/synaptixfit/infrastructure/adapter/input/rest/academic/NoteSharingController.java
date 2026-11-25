package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.ExportNotePdfUseCase;
import com.synaptixfit.application.port.input.academic.SendNoteToFriendUseCase;
import com.synaptixfit.application.port.input.academic.ShareNoteOnWallUseCase;
import com.synaptixfit.domain.model.academic.NotePdf;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteSharingDtos.SendNoteRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteSharingDtos.SentNoteResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteSharingDtos.ShareNoteOnWallRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteSharingDtos.WallShareResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** «Compartir» y «Descargar» un apunte propio (ADR 0064): con un amigo, en el muro y en PDF. */
@Tag(name = "Academic - Notes")
@RestController
@RequestMapping("/api/v1/notes/{noteId}")
public class NoteSharingController {

    private final SendNoteToFriendUseCase sendToFriend;
    private final ShareNoteOnWallUseCase shareOnWall;
    private final ExportNotePdfUseCase exportPdf;

    public NoteSharingController(SendNoteToFriendUseCase sendToFriend, ShareNoteOnWallUseCase shareOnWall,
                                 ExportNotePdfUseCase exportPdf) {
        this.sendToFriend = sendToFriend;
        this.shareOnWall = shareOnWall;
        this.exportPdf = exportPdf;
    }

    @PostMapping("/recipients")
    public SentNoteResponse send(@CurrentUserId UUID userId, @PathVariable UUID noteId,
                                 @Valid @RequestBody SendNoteRequest request) {
        return SentNoteResponse.from(sendToFriend.sendToFriend(userId, noteId, request.friendId()));
    }

    @PostMapping("/wall")
    public WallShareResponse wall(@CurrentUserId UUID userId, @PathVariable UUID noteId,
                                  @Valid @RequestBody(required = false) ShareNoteOnWallRequest request) {
        String comment = request == null ? null : request.comment();
        return WallShareResponse.from(shareOnWall.shareOnWall(new ShareNoteOnWallUseCase.Command(userId, noteId,
                comment)));
    }

    /** Sin {@code produces}: un error tiene que poder salir como ProblemDetail aunque se pida el PDF. */
    @GetMapping("/pdf")
    @ApiResponse(responseCode = "200", description = "El apunte en PDF",
            content = @Content(mediaType = MediaType.APPLICATION_PDF_VALUE,
                    schema = @Schema(type = "string", format = "binary")))
    public ResponseEntity<byte[]> pdf(@CurrentUserId UUID userId, @PathVariable UUID noteId) {
        NotePdf pdf = exportPdf.exportPdf(userId, noteId);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(pdf.fileName(), StandardCharsets.UTF_8).build().toString())
                .body(pdf.content());
    }
}
