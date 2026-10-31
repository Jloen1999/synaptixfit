package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.model.user.UsageFocus;
import java.util.ArrayList;
import java.util.List;

/**
 * Lo que falta por configurar para que la app funcione bien, según el enfoque de uso. Se muestra
 * como un aviso discreto en Inicio (no bloquea nada): el onboarding corto deja saltar pasos.
 *
 * <p>Orden de importancia: sin asignaturas no hay plan de estudio; sin perfil físico no hay kcal ni
 * carga física; sin rutina activa no hay próximo entreno; sin nada en el calendario de los próximos
 * días no hay agenda ni avisos; la universidad y el grado solo afinan el catálogo.
 *
 * @param pending tareas pendientes en orden de importancia
 * @param total   tareas que aplican a este enfoque (hechas + pendientes)
 */
public record SetupChecklist(List<SetupTask> pending, int total) {

    public SetupChecklist {
        pending = List.copyOf(pending);
    }

    public enum SetupTask {
        SUBJECTS,
        WELLNESS_PROFILE,
        ROUTINE,
        WEEK_PLAN,
        ACADEMIC_PROFILE
    }

    /**
     * @param hasActiveRoutine  hay al menos una rutina activa
     * @param hasUpcomingBlocks hay algo en el calendario de los próximos días
     */
    public static SetupChecklist of(OnboardingStatus status, boolean hasActiveRoutine, boolean hasUpcomingBlocks) {
        UsageFocus focus = status.focus() == null ? UsageFocus.BOTH : status.focus();
        List<SetupTask> pending = new ArrayList<>();
        int total = 0;
        if (focus.includesAcademic()) {
            total++;
            if (!status.subjectsCompleted()) {
                pending.add(SetupTask.SUBJECTS);
            }
        }
        if (focus.includesFitness()) {
            total += 2;
            if (!status.wellnessProfileCompleted()) {
                pending.add(SetupTask.WELLNESS_PROFILE);
            }
            if (!hasActiveRoutine) {
                pending.add(SetupTask.ROUTINE);
            }
        }
        total++;
        if (!hasUpcomingBlocks) {
            pending.add(SetupTask.WEEK_PLAN);
        }
        if (focus.includesAcademic()) {
            total++;
            if (!status.academicProfileCompleted()) {
                pending.add(SetupTask.ACADEMIC_PROFILE);
            }
        }
        return new SetupChecklist(pending, total);
    }
}
