package com.synaptixfit.application.service.academic;

import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.exception.academic.StudyMaterialNotFoundException;
import com.synaptixfit.domain.exception.academic.StudySourceNotSupportedException;
import com.synaptixfit.domain.exception.academic.StudySourceWithoutSubjectException;
import com.synaptixfit.domain.exception.academic.SubjectFileNotFoundException;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import java.time.Clock;
import java.util.UUID;

/**
 * Búsquedas con comprobación de propiedad compartidas por los servicios académicos: un recurso
 * de otro usuario se trata como inexistente. También resuelve fuentes de estudio para la IA y
 * crea materiales de estudio bajo demanda.
 */
final class AcademicLookups {

    /** Límite de texto por apunte enviado a la IA (como el sistema antiguo). */
    static final int MAX_SOURCE_CHARS = 18_000;

    /** Fuente resuelta: identidad, título, asignatura (puede ser nula) y contenido para la IA. */
    record ResolvedSource(StudySourceRef ref, String title, UUID subjectId, StudyAssistantPort.Source source) {
    }

    /** Datos básicos del origen de un material, sin descargar nada. */
    record Origin(String title, UUID subjectId) {
    }

    private final SubjectRepositoryPort subjects;
    private final NoteRepositoryPort notes;
    private final SubjectFileRepositoryPort files;
    private final StudyMaterialRepositoryPort materials;
    private final FileStoragePort storage;
    private final Clock clock;

    AcademicLookups(SubjectRepositoryPort subjects, NoteRepositoryPort notes, SubjectFileRepositoryPort files,
                    StudyMaterialRepositoryPort materials, FileStoragePort storage, Clock clock) {
        this.subjects = subjects;
        this.notes = notes;
        this.files = files;
        this.materials = materials;
        this.storage = storage;
        this.clock = clock;
    }

    Subject subject(UUID userId, UUID subjectId) {
        return subjects.findByIdAndUser(subjectId, userId)
                .orElseThrow(() -> new SubjectNotFoundException(subjectId));
    }

    Note note(UUID userId, UUID noteId) {
        return notes.findByIdAndUser(noteId, userId).orElseThrow(() -> new NoteNotFoundException(noteId));
    }

    SubjectFile file(UUID userId, UUID fileId) {
        return files.findByIdAndUser(fileId, userId).orElseThrow(() -> new SubjectFileNotFoundException(fileId));
    }

    StudyMaterial material(UUID userId, UUID materialId) {
        return materials.findByIdAndUser(materialId, userId)
                .orElseThrow(() -> new StudyMaterialNotFoundException(materialId));
    }

    Origin origin(UUID userId, StudySourceType type, UUID id) {
        if (type == StudySourceType.NOTE) {
            Note n = note(userId, id);
            return new Origin(n.title(), n.subjectId());
        }
        SubjectFile f = file(userId, id);
        return new Origin(f.fileName(), f.subjectId());
    }

    /** Carga la fuente comprobando la propiedad; los archivos deben ser PDF o imagen y se descargan. */
    ResolvedSource resolve(UUID userId, StudySourceRef ref) {
        if (ref.type() == StudySourceType.NOTE) {
            Note n = note(userId, ref.id());
            String text = n.content().length() > MAX_SOURCE_CHARS
                    ? n.content().substring(0, MAX_SOURCE_CHARS) : n.content();
            return new ResolvedSource(ref, n.title(), n.subjectId(), StudyAssistantPort.Source.text(n.title(), text));
        }
        SubjectFile f = file(userId, ref.id());
        if (!f.isAiReadable()) {
            throw new StudySourceNotSupportedException(f.mimeType());
        }
        byte[] data = storage.download(f.objectKey());
        return new ResolvedSource(ref, f.fileName(), f.subjectId(),
                StudyAssistantPort.Source.binary(f.fileName(), f.mimeType(), data));
    }

    /** Devuelve el material del origen o lo crea (el origen debe tener asignatura). */
    StudyMaterial ensureMaterial(UUID userId, StudySourceType type, UUID originId) {
        return materials.findByOrigin(userId, type, originId).orElseGet(() -> {
            Origin origin = origin(userId, type, originId);
            if (origin.subjectId() == null) {
                throw new StudySourceWithoutSubjectException(originId);
            }
            return materials.save(StudyMaterial.create(userId, origin.subjectId(), type, originId, origin.title(),
                    clock.instant()));
        });
    }
}
