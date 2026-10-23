package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El apunte o archivo adjunto no existe o no es del usuario. */
public class MilestoneAttachmentNotFoundException extends ResourceNotFoundException {

    public MilestoneAttachmentNotFoundException(UUID id) {
        super("MILESTONE_ATTACHMENT_NOT_FOUND", "Attachment", id);
    }
}
