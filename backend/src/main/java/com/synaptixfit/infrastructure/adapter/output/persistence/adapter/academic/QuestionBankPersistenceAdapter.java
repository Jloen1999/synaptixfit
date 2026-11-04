package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionBankEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.QuestionBankJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.QuestionJpaRepository;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link QuestionBankRepositoryPort} con JPA. */
@Repository
public class QuestionBankPersistenceAdapter implements QuestionBankRepositoryPort {

    private final QuestionBankJpaRepository banks;
    private final QuestionJpaRepository questions;

    public QuestionBankPersistenceAdapter(QuestionBankJpaRepository banks, QuestionJpaRepository questions) {
        this.banks = banks;
        this.questions = questions;
    }

    @Override
    public Optional<QuestionBank> findByIdAndUser(UUID id, UUID userId) {
        return banks.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public Optional<QuestionBank> findByMaterial(UUID materialId) {
        return banks.findFirstByMaterialIdOrderByGeneratedAtDesc(materialId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public QuestionBank save(QuestionBank bank) {
        QuestionBankEntity entity = banks.findById(bank.id()).orElseGet(QuestionBankEntity::new);
        AcademicPersistenceMapper.copy(bank, entity);
        return AcademicPersistenceMapper.toDomain(banks.saveAndFlush(entity));
    }

    @Override
    public void replaceQuestions(UUID bankId, List<Question> list) {
        questions.deleteByBank(bankId);
        questions.saveAll(list.stream().map(AcademicPersistenceMapper::toEntity).toList());
        questions.flush();
    }

    @Override
    public List<Question> findQuestions(UUID bankId) {
        return questions.findByBankIdOrderByPositionAsc(bankId).stream().map(AcademicPersistenceMapper::toDomain)
                .toList();
    }

    @Override
    public int countQuestions(UUID bankId) {
        return (int) questions.countByBankId(bankId);
    }

    @Override
    public List<Question> findQuestionsByIds(Collection<UUID> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        return questions.findByIdIn(ids).stream().map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public Optional<Question> findQuestionOfUser(UUID questionId, UUID userId) {
        return questions.findOfUser(questionId, userId).map(AcademicPersistenceMapper::toDomain);
    }
}
