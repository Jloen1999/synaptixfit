package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** No se puede reportar contenido propio. */
public class SocialCannotReportOwnContentException extends BusinessRuleException {

    public SocialCannotReportOwnContentException(UUID contentId) {
        super("SOCIAL_CANNOT_REPORT_OWN_CONTENT", "Cannot report own content " + contentId);
    }
}
