package com.synaptixfit.infrastructure.adapter.input.rest.error;

import com.synaptixfit.domain.exception.AuthenticationException;
import com.synaptixfit.domain.exception.BusinessRuleException;
import com.synaptixfit.domain.exception.ConflictException;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.exception.ExternalServiceException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.ForbiddenOperationException;
import com.synaptixfit.domain.exception.InvalidInputException;
import com.synaptixfit.domain.exception.NotFoundException;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/**
 * Traduce excepciones a ProblemDetail (RFC 9457) con el campo {@code code}.
 *
 * <p>El estado HTTP sale de la categoría de la excepción de dominio. {@link #STATUS_BY_CODE}
 * permite excepciones puntuales a esa regla. Nunca se filtran detalles internos.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger LOG = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Excepciones a la regla «categoría → estado». Vacío salvo casos justificados. */
    private static final Map<String, HttpStatus> STATUS_BY_CODE = Map.of(
            "AI_QUOTA_EXCEEDED", HttpStatus.TOO_MANY_REQUESTS
    );

    @ExceptionHandler(DomainException.class)
    public ProblemDetail handleDomain(DomainException ex) {
        HttpStatus status = STATUS_BY_CODE.getOrDefault(ex.code(), statusFor(ex));
        if (status.is5xxServerError()) {
            LOG.warn("Domain error {}: {}", ex.code(), ex.getMessage());
        }
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, ex.getMessage());
        problem.setProperty("code", ex.code());
        if (ex instanceof FieldValidationException fve) {
            problem.setProperty("fields", List.of(Map.of("field", fve.field(), "code", fve.fieldCode())));
        }
        return problem;
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleAccessDenied(AccessDeniedException ex) {
        return problem(HttpStatus.FORBIDDEN, "FORBIDDEN", "Access denied");
    }

    @ExceptionHandler(AuthenticationCredentialsNotFoundException.class)
    public ProblemDetail handleUnauthenticated(AuthenticationCredentialsNotFoundException ex) {
        return problem(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Authentication required");
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ProblemDetail handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        ProblemDetail problem = problem(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Invalid parameter");
        problem.setProperty("fields", List.of(Map.of("field", ex.getName(), "code", "INVALID_FORMAT")));
        return problem;
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ProblemDetail handleIntegrity(DataIntegrityViolationException ex) {
        LOG.warn("Data integrity violation", ex);
        return problem(HttpStatus.CONFLICT, "CONFLICT", "The operation conflicts with existing data");
    }

    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ProblemDetail handleOptimisticLock(OptimisticLockingFailureException ex) {
        return problem(HttpStatus.CONFLICT, "CONFLICT", "The resource was modified concurrently");
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex) {
        LOG.error("Unexpected error", ex);
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Unexpected error");
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
                                                                  HttpHeaders headers, HttpStatusCode status,
                                                                  WebRequest request) {
        ProblemDetail problem = problem(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Validation failed");
        problem.setProperty("fields", ex.getBindingResult().getFieldErrors().stream()
                .map(e -> Map.of("field", e.getField(), "code", fieldCode(e.getCode())))
                .toList());
        return ResponseEntity.badRequest().body(problem);
    }

    /** Errores propios de Spring MVC: se les añade un code transversal. */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, @Nullable Object body,
                                                             HttpHeaders headers, HttpStatusCode statusCode,
                                                             WebRequest request) {
        ResponseEntity<Object> response = super.handleExceptionInternal(ex, body, headers, statusCode, request);
        if (response != null && response.getBody() instanceof ProblemDetail problem
                && (problem.getProperties() == null || !problem.getProperties().containsKey("code"))) {
            problem.setProperty("code", tooManyPhotoBytes(ex, request) ? "NOTE_SCAN_TOO_LARGE"
                    : frameworkCode(statusCode));
        }
        return response;
    }

    /**
     * Las fotos de apuntes que superan el límite de subida no llegan al caso de uso: se les da el
     * mismo code que a una foto demasiado grande para que la app muestre su aviso concreto.
     */
    private static boolean tooManyPhotoBytes(Exception ex, WebRequest request) {
        return ex instanceof MaxUploadSizeExceededException
                && request instanceof ServletWebRequest servlet
                && servlet.getRequest().getRequestURI().endsWith("/notes/scan-drafts");
    }

    private static HttpStatus statusFor(DomainException ex) {
        if (ex instanceof NotFoundException) {
            return HttpStatus.NOT_FOUND;
        }
        if (ex instanceof ConflictException) {
            return HttpStatus.CONFLICT;
        }
        if (ex instanceof InvalidInputException) {
            return HttpStatus.BAD_REQUEST;
        }
        if (ex instanceof AuthenticationException) {
            return HttpStatus.UNAUTHORIZED;
        }
        if (ex instanceof ForbiddenOperationException) {
            return HttpStatus.FORBIDDEN;
        }
        if (ex instanceof ExternalServiceException) {
            return HttpStatus.SERVICE_UNAVAILABLE;
        }
        if (ex instanceof BusinessRuleException) {
            return HttpStatus.UNPROCESSABLE_ENTITY;
        }
        return HttpStatus.UNPROCESSABLE_ENTITY;
    }

    private static String frameworkCode(HttpStatusCode status) {
        return switch (status.value()) {
            case 400, 415, 422 -> "VALIDATION_ERROR";
            case 401 -> "UNAUTHORIZED";
            case 403 -> "FORBIDDEN";
            case 404 -> "NOT_FOUND";
            case 405 -> "METHOD_NOT_ALLOWED";
            default -> status.is5xxServerError() ? "INTERNAL_ERROR" : "BAD_REQUEST";
        };
    }

    private static String fieldCode(String constraint) {
        if (constraint == null) {
            return "INVALID";
        }
        return switch (constraint) {
            case "NotNull", "NotBlank", "NotEmpty" -> "REQUIRED";
            case "Size", "Length" -> "INVALID_LENGTH";
            case "Min", "Max", "Range", "DecimalMin", "DecimalMax", "Positive", "PositiveOrZero" -> "OUT_OF_RANGE";
            case "Email", "Pattern" -> "INVALID_FORMAT";
            default -> "INVALID";
        };
    }

    private static ProblemDetail problem(HttpStatus status, String code, String detail) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
        problem.setProperty("code", code);
        return problem;
    }
}
