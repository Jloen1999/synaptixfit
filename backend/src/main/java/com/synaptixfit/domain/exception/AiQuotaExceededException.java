package com.synaptixfit.domain.exception;

/** El proveedor de IA ha rechazado la petición por cuota agotada. */
public class AiQuotaExceededException extends ExternalServiceException {

    public AiQuotaExceededException() {
        super("AI_QUOTA_EXCEEDED", "AI provider quota exceeded");
    }
}
