package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.ConfirmFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.DeleteSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.GetFileDownloadUrlUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectFilesUseCase;
import com.synaptixfit.application.port.input.academic.RequestFileUploadUseCase;
import com.synaptixfit.domain.model.academic.FileUploadTicket;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.ConfirmFileRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.FileUploadRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.FileUploadResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.SignedUrlResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.SubjectFileResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
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
 * Archivos de asignatura. Flujo de subida: 1) {@code upload-url} (valida y firma), 2) PUT del
 * cliente directamente al almacenamiento, 3) {@code POST .../files} para registrar los metadatos.
 */
@Tag(name = "Academic - Files")
@RestController
@RequestMapping("/api/v1")
public class SubjectFileController {

    private final ListSubjectFilesUseCase listFiles;
    private final GetSubjectFileUseCase getFile;
    private final RequestFileUploadUseCase requestUpload;
    private final ConfirmFileUploadUseCase confirmUpload;
    private final GetFileDownloadUrlUseCase downloadUrl;
    private final DeleteSubjectFileUseCase deleteFile;

    public SubjectFileController(ListSubjectFilesUseCase listFiles, GetSubjectFileUseCase getFile,
                                 RequestFileUploadUseCase requestUpload, ConfirmFileUploadUseCase confirmUpload,
                                 GetFileDownloadUrlUseCase downloadUrl, DeleteSubjectFileUseCase deleteFile) {
        this.listFiles = listFiles;
        this.getFile = getFile;
        this.requestUpload = requestUpload;
        this.confirmUpload = confirmUpload;
        this.downloadUrl = downloadUrl;
        this.deleteFile = deleteFile;
    }

    @GetMapping("/subjects/{subjectId}/files")
    public List<SubjectFileResponse> list(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        return listFiles.listFiles(userId, subjectId).stream().map(SubjectFileResponse::from).toList();
    }

    @PostMapping("/subjects/{subjectId}/files/upload-url")
    public FileUploadResponse uploadUrl(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                        @Valid @RequestBody FileUploadRequest r) {
        FileUploadTicket ticket = requestUpload.requestUpload(new RequestFileUploadUseCase.Command(userId, subjectId,
                r.fileName(), r.mimeType(), r.sizeBytes()));
        return FileUploadResponse.from(ticket.objectKey(), ticket.upload());
    }

    @PostMapping("/subjects/{subjectId}/files")
    @ResponseStatus(HttpStatus.CREATED)
    public SubjectFileResponse confirm(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                       @Valid @RequestBody ConfirmFileRequest r) {
        return SubjectFileResponse.from(confirmUpload.confirmUpload(new ConfirmFileUploadUseCase.Command(userId,
                subjectId, r.objectKey(), r.fileName(), r.mimeType(), r.sizeBytes())));
    }

    @GetMapping("/files/{fileId}")
    public SubjectFileResponse get(@CurrentUserId UUID userId, @PathVariable UUID fileId) {
        return SubjectFileResponse.from(getFile.getFile(userId, fileId));
    }

    @GetMapping("/files/{fileId}/download-url")
    public SignedUrlResponse download(@CurrentUserId UUID userId, @PathVariable UUID fileId) {
        return SignedUrlResponse.from(downloadUrl.downloadUrl(userId, fileId));
    }

    @DeleteMapping("/files/{fileId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID fileId) {
        deleteFile.deleteFile(userId, fileId);
    }
}
