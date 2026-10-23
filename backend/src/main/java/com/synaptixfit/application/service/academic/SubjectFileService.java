package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ConfirmFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.DeleteSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.GetFileDownloadUrlUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectFilesUseCase;
import com.synaptixfit.application.port.input.academic.RequestFileUploadUseCase;
import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.exception.academic.FileAlreadyRegisteredException;
import com.synaptixfit.domain.exception.academic.InvalidFileUploadException;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.FileUploadPolicy;
import com.synaptixfit.domain.model.academic.FileUploadTicket;
import com.synaptixfit.domain.model.academic.SignedUrl;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import java.time.Clock;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

/**
 * Archivos de asignatura en el almacenamiento de objetos. El cliente sube y descarga con URLs
 * prefirmadas; el backend valida, reserva la clave, registra los metadatos y borra.
 */
public class SubjectFileService implements ListSubjectFilesUseCase, GetSubjectFileUseCase, RequestFileUploadUseCase,
        ConfirmFileUploadUseCase, GetFileDownloadUrlUseCase, DeleteSubjectFileUseCase {

    static final Duration UPLOAD_VALIDITY = Duration.ofMinutes(15);
    static final Duration DOWNLOAD_VALIDITY = Duration.ofMinutes(15);

    private final SubjectFileRepositoryPort files;
    private final StudyMaterialRepositoryPort materials;
    private final AiDocumentRepositoryPort aiDocuments;
    private final FileStoragePort storage;
    private final Clock clock;
    private final AcademicLookups lookups;

    public SubjectFileService(SubjectFileRepositoryPort files, SubjectRepositoryPort subjects,
                              StudyMaterialRepositoryPort materials, AiDocumentRepositoryPort aiDocuments,
                              FileStoragePort storage, Clock clock) {
        this.files = files;
        this.materials = materials;
        this.aiDocuments = aiDocuments;
        this.storage = storage;
        this.clock = clock;
        this.lookups = new AcademicLookups(subjects, null, files, materials, storage, clock);
    }

    @Override
    public List<SubjectFile> listFiles(UUID userId, UUID subjectId) {
        Subject s = lookups.subject(userId, subjectId);
        return files.findBySubject(userId, s.id());
    }

    @Override
    public SubjectFile getFile(UUID userId, UUID fileId) {
        return lookups.file(userId, fileId);
    }

    @Override
    public FileUploadTicket requestUpload(RequestFileUploadUseCase.Command c) {
        Subject s = lookups.subject(c.userId(), c.subjectId());
        String mime = FileUploadPolicy.validate(c.mimeType(), c.sizeBytes());
        String key = FileUploadPolicy.objectKey(c.userId(), s.id(), c.fileName(), clock.instant());
        PresignedUrl url = storage.presignUpload(key, mime, c.sizeBytes(), UPLOAD_VALIDITY);
        return new FileUploadTicket(key, toSigned(url));
    }

    @Override
    public SubjectFile confirmUpload(ConfirmFileUploadUseCase.Command c) {
        Subject s = lookups.subject(c.userId(), c.subjectId());
        String mime = FileUploadPolicy.validate(c.mimeType(), c.sizeBytes());
        if (!FileUploadPolicy.isKeyOf(c.objectKey(), c.userId(), s.id())) {
            throw new InvalidFileUploadException(c.objectKey());
        }
        if (files.existsByObjectKey(c.objectKey())) {
            throw new FileAlreadyRegisteredException(c.objectKey());
        }
        String publicUrl = storage.publicUrl(c.objectKey());
        return files.save(new SubjectFile(UUID.randomUUID(), c.userId(), s.id(), c.fileName(), c.objectKey(),
                publicUrl == null ? c.objectKey() : publicUrl, c.sizeBytes(), mime, clock.instant()));
    }

    @Override
    public SignedUrl downloadUrl(UUID userId, UUID fileId) {
        SubjectFile f = lookups.file(userId, fileId);
        return toSigned(storage.presignDownload(f.objectKey(), DOWNLOAD_VALIDITY));
    }

    @Override
    public void deleteFile(UUID userId, UUID fileId) {
        SubjectFile f = lookups.file(userId, fileId);
        try {
            storage.delete(f.objectKey());
        } catch (StorageUnavailableException ignored) {
            // Best-effort como en el sistema antiguo: los metadatos se eliminan igualmente.
        }
        materials.findByOrigin(userId, StudySourceType.FILE, f.id()).ifPresent(m -> materials.delete(m.id()));
        aiDocuments.deleteBySource(userId, AiDocumentSource.FILE, f.id().toString());
        files.delete(f.id());
    }

    private static SignedUrl toSigned(PresignedUrl url) {
        return new SignedUrl(url.url(), url.method(), url.headers(), url.expiresAt());
    }
}
