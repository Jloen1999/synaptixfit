package com.synaptixfit.infrastructure.adapter.input.scheduler;

import com.synaptixfit.application.port.input.together.CreditStudyRoomRoundsUseCase;
import com.synaptixfit.application.port.input.together.FindStudyRoomsToCreditUseCase;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Adaptador de entrada programado de «Estudiamos juntos» (ADR 0045): cada minuto apunta como Pomodoro las rondas de
 * sala recién terminadas, aunque nadie tenga la pantalla abierta. Cada sala va en su propia transacción
 * ({@link CreditStudyRoomRoundsUseCase}); si una falla, se registra y las demás siguen. La frecuencia se cambia con
 * {@code synaptixfit.together.study-room-cron}; {@code -} lo desactiva (tests).
 */
@Component
public class StudyRoomScheduler {

    private static final Logger LOG = LoggerFactory.getLogger(StudyRoomScheduler.class);

    private final FindStudyRoomsToCreditUseCase rooms;
    private final CreditStudyRoomRoundsUseCase credit;

    public StudyRoomScheduler(FindStudyRoomsToCreditUseCase rooms, CreditStudyRoomRoundsUseCase credit) {
        this.rooms = rooms;
        this.credit = credit;
    }

    @Scheduled(cron = "${synaptixfit.together.study-room-cron:0 * * * * *}")
    public void creditFinishedRounds() {
        int recorded = 0;
        int failed = 0;
        for (UUID roomId : rooms.roomsToCredit()) {
            try {
                recorded += credit.creditRounds(roomId);
            } catch (RuntimeException e) {
                failed++;
                LOG.warn("Study room {} rounds could not be credited", roomId, e);
            }
        }
        if (recorded > 0 || failed > 0) {
            LOG.info("Study room Pomodoros recorded: {} (failed rooms: {})", recorded, failed);
        }
    }
}
