package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Una tarea solo puede adjuntar un apunte o un archivo, no ambos. */
public class MilestoneAttachmentConflictException extends InvalidInputException {

    public MilestoneAttachmentConflictException() {
        super("MILESTONE_ATTACHMENT_CONFLICT", "a milestone can attach a note or a file, not both");
    }
}
