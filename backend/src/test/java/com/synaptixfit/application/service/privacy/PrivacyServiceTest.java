package com.synaptixfit.application.service.privacy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.privacy.DeleteMyAccountUseCase;
import com.synaptixfit.application.service.admin.AdminTestFixtures;
import com.synaptixfit.application.service.admin.AdminTestFixtures.FakeErasure;
import com.synaptixfit.application.service.admin.AdminTestFixtures.FakeStorage;
import com.synaptixfit.application.service.admin.AdminTestFixtures.InMemoryUsers;
import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingAudit;
import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingEvents;
import com.synaptixfit.domain.event.privacy.UserDataErased;
import com.synaptixfit.domain.exception.privacy.GdprConfirmationRequiredException;
import com.synaptixfit.domain.exception.privacy.GdprLastAdminException;
import com.synaptixfit.domain.exception.privacy.GdprPasswordMismatchException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.admin.AcademicProfileSnapshot;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.AdminUserCounts;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.admin.WellbeingProfileSnapshot;
import com.synaptixfit.domain.model.auth.Password;
import com.synaptixfit.domain.model.privacy.ErasureMode;
import com.synaptixfit.domain.model.privacy.UserDataExport;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class PrivacyServiceTest {

    private final InMemoryUsers users = new InMemoryUsers();
    private final RecordingAudit audit = new RecordingAudit();
    private final FakeErasure erasure = new FakeErasure();
    private final FakeStorage storage = new FakeStorage();
    private final RecordingEvents events = new RecordingEvents();
    private long activeAdmins = 1;
    private PrivacyService service;

    @BeforeEach
    void setUp() {
        erasure.users = users;
        PasswordHasherPort hasher = new PasswordHasherPort() {
            @Override public String hash(Password password) { return "h:" + password.value(); }
            @Override public boolean matches(String raw, String hash) { return ("h:" + raw).equals(hash); }
        };
        service = new PrivacyService(users, hasher, new AdminCount(),
                new UserDataEraser(erasure, storage, events, AdminTestFixtures.CLOCK),
                (id, at) -> "{\"exportedAt\":\"" + at + "\"}", audit, AdminTestFixtures.CLOCK);
    }

    @Test
    void passwordAccountsMustConfirmWithTheirPassword() {
        User user = users.add(AdminTestFixtures.user("me@example.com", Role.USER));

        assertThatThrownBy(() -> service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), null, true)))
                .isInstanceOf(GdprConfirmationRequiredException.class)
                .extracting("code").isEqualTo("GDPR_CONFIRMATION_REQUIRED");
        assertThatThrownBy(() -> service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), "wrong", true)))
                .isInstanceOf(GdprPasswordMismatchException.class)
                .extracting("code").isEqualTo("GDPR_PASSWORD_MISMATCH");
        assertThat(erasure.calls).isEmpty();

        service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), "secret123", false));

        assertThat(users.store).doesNotContainKey(user.id());
        assertThat(audit.entries).singleElement().satisfies(e -> {
            assertThat(e.action()).isEqualTo(AuditAction.SELF_DELETE_ACCOUNT);
            assertThat(e.adminId()).isNull();
            assertThat(e.entityId()).isEqualTo(user.id());
        });
        assertThat(audit.redacted).containsExactly(user.id());
        assertThat(events.published).singleElement()
                .isEqualTo(new UserDataErased(user.id(), ErasureMode.DELETED, AdminTestFixtures.NOW));
    }

    @Test
    void googleOnlyAccountsNeedExplicitConfirmation() {
        User user = users.add(User.builder().id(UUID.randomUUID()).email("g@example.com").fullName("Gina")
                .googleSubject("sub-1").createdAt(AdminTestFixtures.NOW).build());

        assertThatThrownBy(() -> service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), null, false)))
                .isInstanceOf(GdprConfirmationRequiredException.class);

        service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), null, true));
        assertThat(users.store).doesNotContainKey(user.id());
    }

    @Test
    void storageFailuresDoNotBlockTheDeletion() {
        User user = users.add(AdminTestFixtures.user("files@example.com", Role.USER));
        erasure.keys = List.of("usuarios/a.pdf", "usuarios/b.pdf");
        storage.failing.addAll(erasure.keys);

        service.deleteMyAccount(new DeleteMyAccountUseCase.Command(user.id(), "secret123", false));

        assertThat(users.store).doesNotContainKey(user.id());
        assertThat(audit.entries.get(0).details()).containsEntry("failedFileDeletions", 2);
    }

    @Test
    void theLastActiveAdminCannotLeave() {
        User admin = users.add(AdminTestFixtures.user("boss@example.com", Role.ADMIN));

        assertThatThrownBy(() -> service.deleteMyAccount(new DeleteMyAccountUseCase.Command(admin.id(), "secret123", false)))
                .isInstanceOf(GdprLastAdminException.class)
                .extracting("code").isEqualTo("GDPR_LAST_ADMIN");

        activeAdmins = 2;
        service.deleteMyAccount(new DeleteMyAccountUseCase.Command(admin.id(), "secret123", false));
        assertThat(users.store).doesNotContainKey(admin.id());
    }

    @Test
    void exportBelongsToTheCallerAndRequiresAnActiveAccount() {
        User user = users.add(AdminTestFixtures.user("export@example.com", Role.USER));

        UserDataExport export = service.exportMyData(user.id());

        assertThat(export.userId()).isEqualTo(user.id());
        assertThat(export.exportedAt()).isEqualTo(AdminTestFixtures.NOW);
        assertThat(export.json()).contains(AdminTestFixtures.NOW.toString());
        assertThat(audit.entries).isEmpty();
        assertThatThrownBy(() -> service.exportMyData(UUID.randomUUID())).isInstanceOf(UserNotFoundException.class);
    }

    private final class AdminCount implements AdminUserQueryPort {
        @Override public PageResult<AdminUserSummary> search(UserSearchCriteria c, PageRequest p) { return null; }
        @Override public Optional<WellbeingProfileSnapshot> findWellbeingProfile(UUID id) { return Optional.empty(); }
        @Override public Optional<AcademicProfileSnapshot> findAcademicProfile(UUID id) { return Optional.empty(); }
        @Override public AdminUserCounts counts(UUID id) { return null; }
        @Override public List<StudyWeek> recentStudyWeeks(UUID id, int weeks) { return List.of(); }
        @Override public List<StudyInterval> completedStudyIntervals(UUID id, Instant f, Instant t) { return List.of(); }
        @Override public List<CompletedSession> completedTrainingSessions(UUID id, Instant f, Instant t) {
            return List.of();
        }
        @Override public List<UserFocus> completedFocus(UUID id, LocalDate f, LocalDate t) { return List.of(); }
        @Override public PageResult<TimelineEntry> timeline(UUID id, PageRequest p) { return null; }
        @Override public long countActiveAdmins() { return activeAdmins; }
    }
}
