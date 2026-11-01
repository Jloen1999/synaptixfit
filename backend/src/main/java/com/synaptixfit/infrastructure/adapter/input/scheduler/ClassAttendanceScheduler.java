package com.synaptixfit.infrastructure.adapter.input.scheduler;

import com.synaptixfit.application.port.input.planner.AttendClassUseCase;
import com.synaptixfit.application.port.input.planner.AttendEndedClassesUseCase;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Adaptador de entrada programado: cada pocos minutos da por asistidas las clases que acaban de terminar
 * (ADR 0029). Busca con {@link AttendEndedClassesUseCase} y completa cada una con {@link AttendClassUseCase} en
 * su propia transacción: si una falla, se registra y las demás siguen. La frecuencia se cambia con
 * {@code synaptixfit.planner.auto-attend-cron}; {@code -} lo desactiva (tests).
 */
@Component
public class ClassAttendanceScheduler {

    private static final Logger LOG = LoggerFactory.getLogger(ClassAttendanceScheduler.class);

    private final AttendEndedClassesUseCase endedClasses;
    private final AttendClassUseCase attendClass;

    public ClassAttendanceScheduler(AttendEndedClassesUseCase endedClasses, AttendClassUseCase attendClass) {
        this.endedClasses = endedClasses;
        this.attendClass = attendClass;
    }

    @Scheduled(cron = "${synaptixfit.planner.auto-attend-cron:0 */10 * * * *}",
            zone = "${synaptixfit.planner.zone:Europe/Madrid}")
    public void attendEndedClasses() {
        int attended = 0;
        int failed = 0;
        for (UUID blockId : endedClasses.endedClassesToAttend()) {
            try {
                if (attendClass.attendClass(blockId)) {
                    attended++;
                }
            } catch (RuntimeException e) {
                failed++;
                LOG.warn("Class {} could not be marked as attended", blockId, e);
            }
        }
        if (attended > 0 || failed > 0) {
            LOG.info("Classes marked as attended: {} (failed: {})", attended, failed);
        }
    }
}
