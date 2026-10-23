package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.planner;

import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.port.output.planner.FocusSessionRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner.FocusSessionJpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link FocusSessionRepositoryPort} con JPA (escrituras volcadas al momento). */
@Repository
public class FocusSessionPersistenceAdapter implements FocusSessionRepositoryPort {

    private final FocusSessionJpaRepository repository;

    public FocusSessionPersistenceAdapter(FocusSessionJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public FocusSession save(FocusSession session) {
        // Se vuelca al momento: indicadores e insignias leen sesiones_focus con JDBC en la misma transacción.
        return PlannerPersistenceMapper.toDomain(repository.saveAndFlush(PlannerPersistenceMapper.toEntity(session)));
    }

    @Override
    public int sumXpAwarded(UUID userId, LocalDate date) {
        return repository.sumXpOtorgado(userId, date);
    }

    @Override
    public List<FocusSession> findByUserBetween(UUID userId, LocalDate from, LocalDate to) {
        return repository.findByUsuarioIdAndFechaBetweenOrderByCreadoEnAsc(userId, from, to).stream()
                .map(PlannerPersistenceMapper::toDomain).toList();
    }
}
