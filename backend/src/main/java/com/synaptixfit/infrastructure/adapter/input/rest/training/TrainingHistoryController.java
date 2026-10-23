package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HistoryDtos.PersonalRecordResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.HistoryDtos.SessionHistoryResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Historial de entrenamiento con nombres y récords ({@link ListSessionHistoryUseCase}, {@link ListPersonalRecordsUseCase}). */
@Tag(name = "Training history")
@RestController
@RequestMapping("/api/v1/training")
public class TrainingHistoryController {

    private final ListSessionHistoryUseCase history;
    private final ListPersonalRecordsUseCase records;
    private final ListLastPerformanceUseCase last;

    public TrainingHistoryController(ListSessionHistoryUseCase history, ListPersonalRecordsUseCase records,
                                     ListLastPerformanceUseCase last) {
        this.history = history;
        this.records = records;
        this.last = last;
    }

    @GetMapping("/history")
    public PageResponse<SessionHistoryResponse> history(@CurrentUserId UUID userId,
                                                        @RequestParam(defaultValue = "0") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(history.listHistory(userId, new PageRequest(page, size)),
                SessionHistoryResponse::from);
    }

    @GetMapping("/records")
    public List<PersonalRecordResponse> records(@CurrentUserId UUID userId) {
        return records.listPersonalRecords(userId).stream().map(PersonalRecordResponse::from).toList();
    }

    /** Mejor serie de la última sesión de cada ejercicio: la referencia al registrar la siguiente. */
    @GetMapping("/last-performance")
    public List<PersonalRecordResponse> lastPerformance(@CurrentUserId UUID userId) {
        return last.lastPerformance(userId).stream().map(PersonalRecordResponse::from).toList();
    }
}
