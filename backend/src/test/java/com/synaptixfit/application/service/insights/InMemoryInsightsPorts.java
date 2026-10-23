package com.synaptixfit.application.service.insights;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.insights.BodyProfile;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PhysicalLoadRecord;
import com.synaptixfit.domain.model.insights.PracticeSessions;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import com.synaptixfit.domain.port.output.insights.CognitiveStateRepositoryPort;
import com.synaptixfit.domain.port.output.insights.CrossRegulationRepositoryPort;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import com.synaptixfit.domain.port.output.insights.PhysicalLoadRepositoryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Dobles en memoria de los puertos de indicadores. */
final class InMemoryInsightsPorts {

    final List<PhysicalLoadRecord> loads = new ArrayList<>();
    final Map<UUID, CrossRegulationState> regulation = new HashMap<>();
    final Map<UUID, CognitiveState> cognitive = new HashMap<>();
    final List<CompletedStudyBlock> blocks = new ArrayList<>();
    /** Filas de práctica sin bloque que devuelve la fuente, sin filtrar (lo decide el servicio). */
    final List<PracticeSessions.Focus> focus = new ArrayList<>();
    final List<PracticeSessions.TestSession> tests = new ArrayList<>();
    final List<PracticeSessions.Review> reviews = new ArrayList<>();
    final Set<UUID> materialsWithCompletedBlock = new HashSet<>();
    final List<DomainEvent> events = new ArrayList<>();
    final List<DailyCheckIn> checkIns = new ArrayList<>();
    Instant nextExam;
    BodyProfile profile;
    WeeklyAcademicLoad weekly;
    InsightsSourcePort.DeadlineCounts deadlineCounts = new InsightsSourcePort.DeadlineCounts(0, 0);
    int cognitiveSaves;

    final PhysicalLoadRepositoryPort loadPort = new PhysicalLoadRepositoryPort() {
        public Optional<PhysicalLoadRecord> findBySession(UUID userId, UUID sessionId) {
            return loads.stream().filter(r -> r.userId().equals(userId) && sessionId.equals(r.sessionId())).findFirst();
        }

        public PhysicalLoadRecord save(PhysicalLoadRecord record) {
            loads.removeIf(r -> r.id().equals(record.id()));
            loads.add(record);
            return record;
        }

        public boolean deleteBySession(UUID userId, UUID sessionId) {
            return loads.removeIf(r -> r.userId().equals(userId) && sessionId.equals(r.sessionId()));
        }

        public List<PhysicalLoadHistory.Entry> entriesBetween(UUID userId, LocalDate from, LocalDate to) {
            return loads.stream().filter(r -> r.userId().equals(userId) && !r.date().isBefore(from) && !r.date().isAfter(to))
                    .map(r -> new PhysicalLoadHistory.Entry(r.date(), r.rpe(), r.durationMinutes())).toList();
        }

        public List<PhysicalLoadHistory.Entry> allEntries(UUID userId) {
            return entriesBetween(userId, LocalDate.MIN, LocalDate.MAX);
        }
    };

    final CrossRegulationRepositoryPort regulationPort = new CrossRegulationRepositoryPort() {
        public Optional<CrossRegulationState> findByUser(UUID userId) { return Optional.ofNullable(regulation.get(userId)); }
        public CrossRegulationState save(CrossRegulationState s) { regulation.put(s.userId(), s); return s; }
    };

    final CognitiveStateRepositoryPort cognitivePort = new CognitiveStateRepositoryPort() {
        /** Devuelve una copia, como la base de datos: modificar lo leído no cambia lo guardado. */
        public Optional<CognitiveState> findByUser(UUID userId) {
            return Optional.ofNullable(cognitive.get(userId)).map(s -> new CognitiveState(s.userId(), s.cognitiveLoad(),
                    s.attentionCapacity(), s.lastBlockMinutes(), s.lastRestAt(), s.rmrBase(), s.createdAt(),
                    s.updatedAt()));
        }
        public CognitiveState save(CognitiveState s) { cognitiveSaves++; cognitive.put(s.userId(), s); return s; }
    };

    final InsightsSourcePort sourcePort = new InsightsSourcePort() {
        public Optional<Instant> nextPendingExam(UUID userId, Instant from) {
            return Optional.ofNullable(nextExam).filter(e -> !e.isBefore(from));
        }

        public List<CompletedStudyBlock> completedStudyBlocks(UUID userId, Instant from, Instant to) {
            return blocks.stream().filter(b -> !b.start().isBefore(from) && b.start().isBefore(to))
                    .sorted(Comparator.comparing(CompletedStudyBlock::start)).toList();
        }

        public PracticeSessions.Log practiceLog(UUID userId, Instant from, Instant to) {
            return new PracticeSessions.Log(
                    focus.stream().filter(f -> inRange(f.completedAt(), from, to)).toList(),
                    tests.stream().filter(t -> inRange(t.completedAt(), from, to)).toList(),
                    reviews.stream().filter(r -> inRange(r.at(), from, to)).toList(),
                    materialsWithCompletedBlock);
        }

        public Optional<BodyProfile> bodyProfile(UUID userId) { return Optional.ofNullable(profile); }

        public Optional<WeeklyAcademicLoad> weeklyAcademicLoad(UUID userId, LocalDate weekStart) {
            return Optional.ofNullable(weekly).filter(w -> w.weekStart().equals(weekStart));
        }

        public Optional<DailyCheckIn> checkIn(UUID userId, LocalDate date) {
            return checkIns.stream().filter(c -> c.date().equals(date)).findFirst();
        }

        public List<DailyCheckIn> checkIns(UUID userId, LocalDate from, LocalDate to) {
            return checkIns.stream().filter(c -> !c.date().isBefore(from) && !c.date().isAfter(to)).toList();
        }

        public DeadlineCounts deadlineCounts(UUID userId, Instant from, Instant to) { return deadlineCounts; }
    };

    private static boolean inRange(Instant at, Instant from, Instant to) {
        return !at.isBefore(from) && at.isBefore(to);
    }
}
