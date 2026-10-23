package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Hace falta el perfil de bienestar para generar una rutina. */
public class TrainingProfileRequiredException extends BusinessRuleException {

    public TrainingProfileRequiredException() {
        super("TRAINING_PROFILE_REQUIRED", "A wellness profile is required to generate a routine");
    }
}
