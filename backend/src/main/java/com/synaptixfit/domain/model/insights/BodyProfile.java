package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.neuro.BiologicalSex;
import com.synaptixfit.domain.model.neuro.StudyEnergy;

/** Datos corporales del perfil de bienestar necesarios para la tasa metabólica en reposo. */
public record BodyProfile(double weightKg, double heightCm, int age, BiologicalSex sex) {

    /** RMR (Mifflin-St Jeor) en kcal/día. */
    public double restingMetabolicRate() {
        return StudyEnergy.restingMetabolicRate(weightKg, heightCm, age, sex);
    }
}
