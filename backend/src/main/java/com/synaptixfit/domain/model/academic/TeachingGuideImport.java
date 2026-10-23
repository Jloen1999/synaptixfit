package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.TeachingGuideImportAlreadyAppliedException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotReadyException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Importación de un plan docente en PDF: la IA lo analiza en segundo plano (PENDING → PROCESSING
 * → READY o FAILED) y el estudiante revisa el resultado antes de aplicarlo a una asignatura
 * (APPLIED). {@code targetSubjectId} es la asignatura desde la que se lanzó, si la hay.
 *
 * <p>Un análisis colgado se da por fallido para que el estudiante pueda reintentarlo en vez de
 * esperar para siempre (el servidor se reinició a mitad): {@link #STALE_PROCESSING} desde que
 * empezó a procesarse y {@link #STALE_PENDING} en cola, más holgado porque con 2 hilos y hasta
 * 120 s por análisis la espera en cola puede ser larga.
 *
 * <p>Los cambios de estado se guardan con una transición condicional (solo si el estado guardado
 * sigue siendo el esperado): así dos «aplicar» seguidos no crean dos asignaturas y un análisis que
 * termina tarde no resucita una importación descartada.
 */
public record TeachingGuideImport(UUID id, UUID userId, UUID targetSubjectId, String objectKey, String fileName,
                                  String mimeType, long sizeBytes, Status status, TeachingGuide guide,
                                  String errorCode, UUID appliedSubjectId, Instant createdAt, Instant updatedAt) {

    public static final Duration STALE_PROCESSING = Duration.ofMinutes(5);
    public static final Duration STALE_PENDING = Duration.ofMinutes(15);
    static final String STALE_ERROR = "AI_UNAVAILABLE";

    public enum Status { PENDING, PROCESSING, READY, FAILED, APPLIED }

    public TeachingGuideImport {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        objectKey = Guard.notBlank(objectKey, "objectKey");
        fileName = Guard.length(fileName, "fileName", 1, 255);
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(createdAt, "createdAt");
        Objects.requireNonNull(updatedAt, "updatedAt");
    }

    public static TeachingGuideImport start(UUID userId, UUID targetSubjectId, String objectKey, String fileName,
                                            String mimeType, long sizeBytes, Instant now) {
        return new TeachingGuideImport(UUID.randomUUID(), userId, targetSubjectId, objectKey, fileName, mimeType,
                sizeBytes, Status.PENDING, null, null, null, now, now);
    }

    public TeachingGuideImport processing(Instant now) {
        return with(Status.PROCESSING, guide, null, appliedSubjectId, now);
    }

    public TeachingGuideImport ready(TeachingGuide extracted, Instant now) {
        return with(Status.READY, Objects.requireNonNull(extracted, "guide"), null, appliedSubjectId, now);
    }

    public TeachingGuideImport failed(String code, Instant now) {
        return with(Status.FAILED, null, code == null ? STALE_ERROR : code, appliedSubjectId, now);
    }

    /** Vuelve a la cola tras un fallo; no se puede reintentar algo ya listo o aplicado. */
    public TeachingGuideImport retried(Instant now) {
        Status current = effectiveStatus(now);
        if (current == Status.APPLIED) {
            throw new TeachingGuideImportAlreadyAppliedException(id);
        }
        if (current != Status.FAILED) {
            throw new TeachingGuideImportNotReadyException(id);
        }
        return with(Status.PENDING, null, null, null, now);
    }

    /** Marca la importación como aplicada; la asignatura se anota después con {@link #appliedTo}. */
    public TeachingGuideImport applied(TeachingGuide finalGuide, Instant now) {
        requireReady(now);
        return with(Status.APPLIED, Objects.requireNonNull(finalGuide, "guide"), null, null, now);
    }

    public TeachingGuideImport appliedTo(UUID subjectId, TeachingGuide finalGuide, Instant now) {
        return with(Status.APPLIED, finalGuide, null, Objects.requireNonNull(subjectId, "subjectId"), now);
    }

    public void requireReady(Instant now) {
        Status current = effectiveStatus(now);
        if (current == Status.APPLIED) {
            throw new TeachingGuideImportAlreadyAppliedException(id);
        }
        if (current != Status.READY) {
            throw new TeachingGuideImportNotReadyException(id);
        }
    }

    /** Estado que ve el estudiante: un análisis colgado cuenta como fallido. */
    public Status effectiveStatus(Instant now) {
        Duration limit = switch (status) {
            case PENDING -> STALE_PENDING;
            case PROCESSING -> STALE_PROCESSING;
            default -> null;
        };
        return limit != null && updatedAt.plus(limit).isBefore(now) ? Status.FAILED : status;
    }

    public String effectiveErrorCode(Instant now) {
        return effectiveStatus(now) == Status.FAILED && errorCode == null ? STALE_ERROR : errorCode;
    }

    /** Un PDF que nunca llegó a una asignatura se puede borrar al descartar la importación. */
    public boolean ownsUploadedFile() {
        return status != Status.APPLIED;
    }

    private TeachingGuideImport with(Status newStatus, TeachingGuide newGuide, String newError, UUID applied,
                                     Instant now) {
        return new TeachingGuideImport(id, userId, targetSubjectId, objectKey, fileName, mimeType, sizeBytes, newStatus,
                newGuide, newError, applied, createdAt, now);
    }
}
