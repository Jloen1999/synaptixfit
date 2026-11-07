package com.synaptixfit.application.service.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** El historial de deporte hecho se lee solo de la persona y con la página pedida. */
class SportActivityHistoryServiceTest {

    private final LoggedActivityRepositoryPort activities = mock(LoggedActivityRepositoryPort.class);
    private final SportActivityHistoryService service = new SportActivityHistoryService(activities);

    @Test
    void listsTheActivitiesOfThePersonWithTheRequestedPage() {
        UUID userId = UUID.randomUUID();
        PageRequest page = new PageRequest(1, 20);
        PageResult<LoggedSportActivity> found = new PageResult<>(List.of(mock(LoggedSportActivity.class)), 1, 20, 21);
        when(activities.findSportActivities(userId, page)).thenReturn(found);

        assertThat(service.list(userId, page)).isSameAs(found);
        verify(activities).findSportActivities(userId, page);
    }
}
