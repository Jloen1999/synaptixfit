package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.model.user.UsageFocus;
import java.util.ArrayList;
import java.util.List;

/**
 * Estado del onboarding: qué pasos están hechos para que el cliente decida a qué pantalla ir.
 *
 * <p>Orden de los pasos: enfoque de uso y, según el enfoque, perfil físico (deporte) y perfil
 * académico más asignaturas (estudios). La contraseña de las cuentas creadas con Google ya no es un
 * paso: se pone cuando se quiera en Ajustes ({@code accountCompleted} solo informa). Sin enfoque elegido se cuentan los pasos de ambos ámbitos. El onboarding
 * está completo cuando el usuario lo ha cerrado explícitamente o cuando no queda ningún paso pendiente.
 *
 * @param focus enfoque elegido, o {@code null} si aún no lo ha elegido
 */
public record OnboardingStatus(boolean accountCompleted, UsageFocus focus, boolean wellnessProfileCompleted,
                               boolean academicProfileCompleted, boolean subjectsCompleted,
                               boolean markedCompleted) {

    /** Pasos pendientes en el orden en que se recorren. */
    public List<OnboardingStep> pendingSteps() {
        UsageFocus effective = focus == null ? UsageFocus.BOTH : focus;
        List<OnboardingStep> pending = new ArrayList<>();
        if (focus == null) {
            pending.add(OnboardingStep.FOCUS);
        }
        if (effective.includesFitness() && !wellnessProfileCompleted) {
            pending.add(OnboardingStep.WELLNESS_PROFILE);
        }
        if (effective.includesAcademic() && !academicProfileCompleted) {
            pending.add(OnboardingStep.ACADEMIC_PROFILE);
        }
        if (effective.includesAcademic() && !subjectsCompleted) {
            pending.add(OnboardingStep.SUBJECTS);
        }
        return List.copyOf(pending);
    }

    /** Siguiente paso a mostrar, o {@code null} si no queda ninguno. */
    public OnboardingStep nextStep() {
        List<OnboardingStep> pending = pendingSteps();
        return pending.isEmpty() ? null : pending.get(0);
    }

    public boolean completed() {
        return markedCompleted || pendingSteps().isEmpty();
    }
}
