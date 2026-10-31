package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import com.synaptixfit.application.port.input.profile.ApplyEnrollmentUseCase;
import com.synaptixfit.application.port.input.profile.ReadEnrollmentUseCase;
import com.synaptixfit.domain.exception.profile.EnrollmentFileInvalidException;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.ApplyEnrollmentRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.ApplyEnrollmentResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.EnrollmentProposalResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Importar la matrícula desde la carta de pago o el resguardo (PDF): leer propone, aplicar añade lo
 * elegido. Leer exige {@code consent=true}; el archivo no se guarda.
 */
@Tag(name = "Profile")
@RestController
@RequestMapping("/api/v1/profile/enrollment")
public class EnrollmentController {

    private final ReadEnrollmentUseCase read;
    private final ApplyEnrollmentUseCase apply;

    public EnrollmentController(ReadEnrollmentUseCase read, ApplyEnrollmentUseCase apply) {
        this.read = read;
        this.apply = apply;
    }

    @PostMapping(value = "/read", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public EnrollmentProposalResponse read(@CurrentUserId UUID userId, @RequestPart("file") MultipartFile file,
                                           @RequestParam(defaultValue = "false") boolean consent) {
        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new EnrollmentFileInvalidException();
        }
        return EnrollmentProposalResponse.from(read.readEnrollment(
                new ReadEnrollmentUseCase.Command(userId, content, file.getContentType(), consent)));
    }

    @PostMapping("/apply")
    public ApplyEnrollmentResponse apply(@CurrentUserId UUID userId, @Valid @RequestBody ApplyEnrollmentRequest body) {
        List<ApplyEnrollmentUseCase.CustomSubject> custom = body.customSubjects() == null ? List.of()
                : body.customSubjects().stream()
                        .map(c -> new ApplyEnrollmentUseCase.CustomSubject(c.name().strip(), c.code(), c.credits()))
                        .toList();
        ApplyEnrollmentUseCase.Result result = apply.applyEnrollment(
                new ApplyEnrollmentUseCase.Command(userId, body.degreeId(), body.catalogSubjectIds(), custom));
        return new ApplyEnrollmentResponse(result.subjectsAdded(), result.degreeLinked());
    }
}
