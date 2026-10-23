package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import com.synaptixfit.application.port.input.profile.GetAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.UpdateAcademicProfileUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.AcademicProfileRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.AcademicProfileResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Perfil académico (incluye las fechas del semestre que usa el escaneo de horarios). */
@Tag(name = "Academic profile")
@RestController
@RequestMapping("/api/v1/profile/academic")
public class AcademicProfileController {

    private final GetAcademicProfileUseCase getProfile;
    private final SaveAcademicProfileUseCase saveProfile;
    private final UpdateAcademicProfileUseCase updateProfile;

    public AcademicProfileController(GetAcademicProfileUseCase getProfile, SaveAcademicProfileUseCase saveProfile,
                                     UpdateAcademicProfileUseCase updateProfile) {
        this.getProfile = getProfile;
        this.saveProfile = saveProfile;
        this.updateProfile = updateProfile;
    }

    @GetMapping
    public AcademicProfileResponse get(@CurrentUserId UUID userId) {
        return AcademicProfileResponse.from(getProfile.getAcademicProfile(userId));
    }

    /** Crea o reemplaza el perfil completo (idempotente). */
    @PutMapping
    public AcademicProfileResponse save(@CurrentUserId UUID userId, @Valid @RequestBody AcademicProfileRequest r) {
        return AcademicProfileResponse.from(saveProfile.saveAcademicProfile(new SaveAcademicProfileUseCase.Command(
                userId, r.university(), r.degree(), r.degreeId(), r.semester(), r.modality(), r.semesterCredits(),
                r.weeklyStudyHoursGoal(), r.targetGpa(), r.classesStartDate(), r.classesEndDate())));
    }

    /** Edición parcial; crea el perfil con valores por defecto si no existía. */
    @PatchMapping
    public AcademicProfileResponse update(@CurrentUserId UUID userId, @Valid @RequestBody AcademicProfileRequest r) {
        return AcademicProfileResponse.from(updateProfile.updateAcademicProfile(
                new UpdateAcademicProfileUseCase.Command(userId, r.university(), r.degree(), r.degreeId(),
                        r.semester(), r.modality(), r.semesterCredits(), r.weeklyStudyHoursGoal(), r.targetGpa(),
                        r.classesStartDate(), r.classesEndDate())));
    }
}
