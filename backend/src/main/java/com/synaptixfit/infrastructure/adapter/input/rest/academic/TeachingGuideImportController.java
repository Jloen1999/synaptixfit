package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.ApplyTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.DiscardTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.RequestTeachingGuideUploadUseCase;
import com.synaptixfit.application.port.input.academic.RetryTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.StartTeachingGuideImportUseCase;
import com.synaptixfit.domain.model.academic.FileUploadTicket;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.FileUploadResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.TeachingGuideDtos.ApplyImportRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.TeachingGuideDtos.ApplyImportResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.TeachingGuideDtos.ImportResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.TeachingGuideDtos.ImportUploadRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.TeachingGuideDtos.StartImportRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Importar un plan docente en PDF. Flujo: 1) {@code upload-url}, 2) PUT del cliente al
 * almacenamiento, 3) {@code POST} (202: la IA lo analiza en segundo plano), 4) {@code GET} hasta
 * que el estado sea {@code READY} o {@code FAILED}, 5) {@code apply} con lo revisado.
 */
@Tag(name = "Academic - Teaching guide import")
@RestController
@RequestMapping("/api/v1/teaching-guide-imports")
public class TeachingGuideImportController {

    private final RequestTeachingGuideUploadUseCase requestUpload;
    private final StartTeachingGuideImportUseCase start;
    private final GetTeachingGuideImportUseCase get;
    private final RetryTeachingGuideImportUseCase retry;
    private final ApplyTeachingGuideImportUseCase apply;
    private final DiscardTeachingGuideImportUseCase discard;

    public TeachingGuideImportController(RequestTeachingGuideUploadUseCase requestUpload,
                                         StartTeachingGuideImportUseCase start, GetTeachingGuideImportUseCase get,
                                         RetryTeachingGuideImportUseCase retry, ApplyTeachingGuideImportUseCase apply,
                                         DiscardTeachingGuideImportUseCase discard) {
        this.requestUpload = requestUpload;
        this.start = start;
        this.get = get;
        this.retry = retry;
        this.apply = apply;
        this.discard = discard;
    }

    @PostMapping("/upload-url")
    public FileUploadResponse uploadUrl(@CurrentUserId UUID userId, @Valid @RequestBody ImportUploadRequest r) {
        FileUploadTicket ticket = requestUpload.requestUpload(userId, r.fileName(), r.mimeType(), r.sizeBytes());
        return FileUploadResponse.from(ticket.objectKey(), ticket.upload());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ImportResponse start(@CurrentUserId UUID userId, @Valid @RequestBody StartImportRequest r) {
        return ImportResponse.from(start.start(new StartTeachingGuideImportUseCase.Command(userId, r.objectKey(),
                r.fileName(), r.mimeType(), r.sizeBytes(), r.targetSubjectId())));
    }

    @GetMapping("/{importId}")
    public ImportResponse get(@CurrentUserId UUID userId, @PathVariable UUID importId) {
        return ImportResponse.from(get.getImport(userId, importId));
    }

    @PostMapping("/{importId}/retry")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ImportResponse retry(@CurrentUserId UUID userId, @PathVariable UUID importId) {
        return ImportResponse.from(retry.retry(userId, importId));
    }

    @PostMapping("/{importId}/apply")
    public ApplyImportResponse apply(@CurrentUserId UUID userId, @PathVariable UUID importId,
                                     @Valid @RequestBody ApplyImportRequest r) {
        return ApplyImportResponse.from(apply.apply(new ApplyTeachingGuideImportUseCase.Command(userId, importId,
                r.subjectId(), r.guide() == null ? null : r.guide().toDomain(), r.createDeadlines())));
    }

    @DeleteMapping("/{importId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void discard(@CurrentUserId UUID userId, @PathVariable UUID importId) {
        discard.discard(userId, importId);
    }
}
