package com.synaptixfit.domain.model.user;

/**
 * Para qué usa la persona SynaptixFit: solo estudios, solo deporte o ambos. Decide qué pasos pide el
 * onboarding y qué contenido de cada ámbito recibe (avisos, retos, insignias, panel de inicio).
 */
public enum UsageFocus {
    ACADEMIC,
    FITNESS,
    BOTH;

    public boolean includesAcademic() {
        return this != FITNESS;
    }

    public boolean includesFitness() {
        return this != ACADEMIC;
    }
}
