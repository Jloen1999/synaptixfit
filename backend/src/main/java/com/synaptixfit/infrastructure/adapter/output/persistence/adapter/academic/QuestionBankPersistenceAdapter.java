package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionBankEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.QuestionBankJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.QuestionJpaRepository;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
    public void addQuestions(UUID bankId, List<Question> list) {
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

    /** Dos consultas: los bancos de los materiales (el más reciente de cada uno) y sus preguntas. */
    @Override
    public Map<UUID, List<Question>> findQuestionsByMaterials(Collection<UUID> materialIds) {
        if (materialIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, QuestionBankEntity> latest = new HashMap<>();
        for (QuestionBankEntity b : banks.findByMaterialIdIn(materialIds)) {
            latest.merge(b.getMaterialId(), b,
                    (a, c) -> c.getGeneratedAt().isAfter(a.getGeneratedAt()) ? c : a);
        }
        Map<UUID, UUID> materialOfBank = new HashMap<>();
        latest.forEach((material, bank) -> materialOfBank.put(bank.getId(), material));
        if (materialOfBank.isEmpty()) {
            return Map.of();
        }
        Map<UUID, List<Question>> byMaterial = new LinkedHashMap<>();
        for (var q : questions.findByBankIdInOrderByPositionAsc(materialOfBank.keySet())) {
            byMaterial.computeIfAbsent(materialOfBank.get(q.getBankId()), k -> new ArrayList<>())
                    .add(AcademicPersistenceMapper.toDomain(q));
        }
        return byMaterial;
    }

    @Override
    public Optional<Question> findQuestionOfUser(UUID questionId, UUID userId) {
        return questions.findOfUser(questionId, userId).map(AcademicPersistenceMapper::toDomain);
    }
}
