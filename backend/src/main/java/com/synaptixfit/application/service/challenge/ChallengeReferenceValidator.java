package com.synaptixfit.application.service.challenge;

import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkNotFoundException;
import com.synaptixfit.domain.exception.challenge.ChallengeRoutineDayNotLinkableException;
import com.synaptixfit.domain.exception.challenge.ChallengeSubjectNotFoundException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentConflictException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentNotFoundException;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Comprueba que asignaturas, vínculos (entregas, exámenes y días de rutina) y adjuntos referenciados pertenecen
 * al usuario.
 * Que la entrega venza dentro del periodo del reto lo comprueba el propio reto al guardarse.
 */
public class ChallengeReferenceValidator {

    private final ChallengeReferencePort references;

    public ChallengeReferenceValidator(ChallengeReferencePort references) {
        this.references = references;
    }

    public void checkSubject(UUID userId, UUID subjectId) {
        if (subjectId != null && !references.subjectBelongsTo(userId, subjectId)) {
            throw new ChallengeSubjectNotFoundException(subjectId);
        }
    }

    public void checkLink(UUID userId, ChallengeLink link) {
        if (link == null) {
            return;
        }
        boolean owned = link.type() == LinkType.ROUTINE_DAY
                ? references.routineDayBelongsTo(userId, link.entityId())
                : references.deadlineBelongsTo(userId, link.entityId());
        if (!owned) {
            throw new ChallengeLinkNotFoundException(link.entityId());
        }
        // Mismo criterio que la lista que ofrece el cliente: solo días de la rutina en curso que aún se pueden hacer.
        if (link.type() == LinkType.ROUTINE_DAY && references.routineDayTargets(userId).stream()
                .noneMatch(t -> t.dayId().equals(link.entityId()) && t.linkable())) {
            throw new ChallengeRoutineDayNotLinkableException(link.entityId());
        }
    }

    /**
     * @param keptLinks entregas que ya estaban vinculadas al reto: no se vuelven a validar (si se borraron, la
     *                  tarea simplemente deja de completarse por ellas y no debe impedir editar el reto)
     */
    public void checkDrafts(UUID userId, List<MilestoneDraft> drafts, Set<UUID> keptLinks) {
        for (MilestoneDraft d : drafts) {
            if (d.noteId() != null && d.fileId() != null) {
                throw new MilestoneAttachmentConflictException();
            }
            checkSubject(userId, d.subjectId());
            if (d.link() != null && !keptLinks.contains(d.link().entityId())) {
                checkLink(userId, d.link());
            }
            if (d.noteId() != null && !references.noteBelongsTo(userId, d.noteId())) {
                throw new MilestoneAttachmentNotFoundException(d.noteId());
            }
            if (d.fileId() != null && !references.fileBelongsTo(userId, d.fileId())) {
                throw new MilestoneAttachmentNotFoundException(d.fileId());
            }
        }
    }
}
