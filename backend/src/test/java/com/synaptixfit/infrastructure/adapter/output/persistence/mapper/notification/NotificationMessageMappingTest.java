package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.notification;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.notification.NotificationMessage;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NotificationMessageMappingTest {

    @Test
    void anUnknownCodeFallsBackToTheStoredText() {
        assertThat(NotificationPersistenceMapper.messageFromDb("CODIGO_RETIRADO", Map.of())).isNull();
        assertThat(NotificationPersistenceMapper.messageFromDb(null, null)).isNull();
        assertThat(NotificationPersistenceMapper.messageFromDb("LEVEL_UP", Map.of("level", "4")))
                .isEqualTo(NotificationMessage.of(NotificationMessage.Code.LEVEL_UP, "level", "4"));
    }
}
