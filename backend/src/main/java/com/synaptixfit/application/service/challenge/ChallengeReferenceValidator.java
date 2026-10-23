package com.synaptixfit.application.service.challenge;

import com.synaptixfit.domain.exception.challenge.ChallengeLinkNotFoundException;
import com.synaptixfit.domain.exception.challenge.ChallengeSubjectNotFoundException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentConflictException;
import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentNotFoundException;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.util.List;
import java.util.UUID;

/** Comprueba que asignaturas, vínculos y adjuntos referenciados pertenecen al usuario. */
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
        boolean owned = link.type().isDeadline()
                ? references.deadlineBelongsTo(userId, link.entityId())
                : references.studyBlockBelongsTo(userId, link.entityId());
        if (!owned) {
            throw new ChallengeLinkNotFoundException(link.entityId());
        }
    }

    public void checkDrafts(UUID userId, List<MilestoneDraft> drafts) {
        for (MilestoneDraft d : drafts) {
            if (d.noteId() != null && d.fileId() != null) {
                throw new MilestoneAttachmentConflictException();
            }
            checkSubject(userId, d.subjectId());
            checkLink(userId, d.link());
            if (d.noteId() != null && !references.noteBelongsTo(userId, d.noteId())) {
                throw new MilestoneAttachmentNotFoundException(d.noteId());
            }
            if (d.fileId() != null && !references.fileBelongsTo(userId, d.fileId())) {
                throw new MilestoneAttachmentNotFoundException(d.fileId());
            }
        }
    }
}
