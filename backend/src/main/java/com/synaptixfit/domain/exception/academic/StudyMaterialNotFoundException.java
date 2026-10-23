package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El material de estudio no existe o no es del usuario. */
public class StudyMaterialNotFoundException extends ResourceNotFoundException {

    public StudyMaterialNotFoundException(Object id) {
        super("STUDY_MATERIAL_NOT_FOUND", "Study material", id);
    }
}
