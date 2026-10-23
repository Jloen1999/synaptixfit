package com.synaptixfit.application.service.admin;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.AuditLogItem;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.auth.RefreshToken;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.privacy.UserDataErasurePort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Dobles en memoria de los puertos que usan los servicios de administración y RGPD. */
public final class AdminTestFixtures {

    public static final Instant NOW = Instant.parse("2026-10-14T10:00:00Z");
    public static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

    private AdminTestFixtures() {
    }

    public static User user(String email, Role role) {
        return User.builder().id(UUID.randomUUID()).email(email).fullName("Usuario " + email.charAt(0))
                .passwordHash("h:secret123").role(role).level(3).levelXp(50).streak(4)
                .createdAt(NOW.minusSeconds(86_400)).build();
    }

    /** Repositorio de usuarios en memoria. */
    public static final class InMemoryUsers implements UserRepositoryPort {
        public final Map<UUID, User> store = new HashMap<>();
        public int saves;

        public User add(User u) {
            store.put(u.id(), u);
            return u;
        }

        @Override public Optional<User> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        @Override public Optional<User> findByEmail(String e) {
            return store.values().stream().filter(u -> u.email().equals(e)).findFirst();
        }
        @Override public Optional<User> findByGoogleSubject(String s) {
            return store.values().stream().filter(u -> s.equals(u.googleSubject())).findFirst();
        }
        @Override public boolean existsByEmail(String e) { return findByEmail(e).isPresent(); }
        @Override public User save(User u) {
            saves++;
            store.put(u.id(), u);
            return u;
        }
    }

    /** Auditoría en memoria. */
    public static final class RecordingAudit implements AdminAuditPort {
        public final List<AuditEntry> entries = new ArrayList<>();
        public final List<UUID> redacted = new ArrayList<>();

        @Override public void record(AuditEntry entry) { entries.add(entry); }
        @Override public PageResult<AuditLogItem> search(AuditQuery query, PageRequest page) {
            List<AuditLogItem> items = entries.stream().map(e -> new AuditLogItem(e, null, null)).toList();
            return new PageResult<>(items, page.page(), page.size(), items.size());
        }
        @Override public int redactDetailsForEntity(UUID entityId) {
            redacted.add(entityId);
            return 1;
        }
    }

    /** Borrado en memoria: registra qué operación se pidió y para quién. */
    public static final class FakeErasure implements UserDataErasurePort {
        public final List<String> calls = new ArrayList<>();
        public List<String> keys = List.of();
        public InMemoryUsers users;

        @Override public List<String> storedObjectKeys(UUID userId) { return keys; }
        @Override public int wipeContent(UUID userId, Instant at) {
            calls.add("wipe:" + userId);
            return 7;
        }
        @Override public int erasePersonalData(UUID userId) {
            calls.add("anonymize:" + userId);
            return 5;
        }
        @Override public void deleteAccount(UUID userId) {
            calls.add("delete:" + userId);
            if (users != null) {
                users.store.remove(userId);
            }
        }
    }

    /** Almacenamiento que falla para las claves indicadas. */
    public static final class FakeStorage implements FileStoragePort {
        public final List<String> deleted = new ArrayList<>();
        public final Set<String> failing = new HashSet<>();

        @Override public PresignedUrl presignUpload(String k, String c, long s, Duration v) { throw new UnsupportedOperationException(); }
        @Override public PresignedUrl presignDownload(String k, Duration v) { throw new UnsupportedOperationException(); }
        @Override public byte[] download(String k) { throw new UnsupportedOperationException(); }
        @Override public void delete(String key) {
            if (failing.contains(key)) {
                throw new IllegalStateException("R2 down");
            }
            deleted.add(key);
        }
        @Override public String publicUrl(String k) { return null; }
    }

    /** Tokens de refresco: solo registra las revocaciones. */
    public static final class RecordingTokens implements RefreshTokenRepositoryPort {
        public final List<UUID> revokedFor = new ArrayList<>();

        @Override public RefreshToken save(RefreshToken token) { return token; }
        @Override public Optional<RefreshToken> findByHash(String tokenHash) { return Optional.empty(); }
        @Override public void revokeAllForUser(UUID userId, Instant when) { revokedFor.add(userId); }
    }

    /** Eventos publicados. */
    public static final class RecordingEvents implements com.synaptixfit.domain.port.output.event.DomainEventPublisherPort {
        public final List<DomainEvent> published = new ArrayList<>();

        @Override public void publish(DomainEvent event) { published.add(event); }
    }
}
