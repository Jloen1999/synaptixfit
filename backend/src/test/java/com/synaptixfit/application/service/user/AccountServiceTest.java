package com.synaptixfit.application.service.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.user.UpdateAccountUseCase;
import com.synaptixfit.application.service.admin.AdminTestFixtures;
import com.synaptixfit.domain.exception.user.InvalidBirthDateException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import com.synaptixfit.domain.exception.user.AvatarInvalidImageException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Edición de la cuenta (fallo 12 y ADR 0036): cada cambio del formulario se guarda y la fecha se valida. */
class AccountServiceTest {

    private final AdminTestFixtures.InMemoryUsers users = new AdminTestFixtures.InMemoryUsers();
    private final AdminTestFixtures.RecordingEvents events = new AdminTestFixtures.RecordingEvents();
    private AccountService service;
    private User ana;

    @BeforeEach
    void setUp() {
        service = new AccountService(users, events, AdminTestFixtures.CLOCK);
        ana = users.add(AdminTestFixtures.user("ana@example.com", Role.USER));
    }

    @Test
    void ageCountsTodayInThePhoneZone() {
        // 23:30 en UTC del 14 de noviembre: en el móvil (+02:00) ya es el 15, su cumpleaños.
        Clock lateNight = Clock.fixed(Instant.parse("2026-11-14T23:30:00Z"), ZoneOffset.UTC);
        AccountService nightService = new AccountService(users, events, lateNight, ZoneId.of("UTC"));
        ana.changeBirthDate(LocalDate.of(2004, 11, 15), LocalDate.of(2026, 11, 14));

        assertThat(nightService.ageToday(ana, "+02:00")).isEqualTo(22);
        assertThat(nightService.ageToday(ana, null)).isEqualTo(21);
        assertThat(nightService.ageToday(ana, " ")).isEqualTo(21);
    }

    @Test
    void savesEveryFieldOfTheFormAtOnce() {
        User saved = service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), "Ana López",
                "https://img.example.com/a.png", Visibility.PUBLIC, UsageFocus.ACADEMIC, LocalDate.of(2004, 5, 6),
                false));

        User stored = users.store.get(ana.id());
        assertThat(saved.fullName()).isEqualTo("Ana López");
        assertThat(stored.usageFocus()).isEqualTo(UsageFocus.ACADEMIC);
        assertThat(stored.privacy()).isEqualTo(Visibility.PUBLIC);
        assertThat(stored.avatarUrl()).isEqualTo("https://img.example.com/a.png");
        assertThat(stored.birthDate()).isEqualTo(LocalDate.of(2004, 5, 6));
    }

    @Test
    void nullFieldsDoNotChangeAndTheBirthDateCanBeRemoved() {
        service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, null, null, null,
                LocalDate.of(2004, 5, 6), false));

        service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, null, null, UsageFocus.FITNESS));
        assertThat(users.store.get(ana.id()).birthDate()).isEqualTo(LocalDate.of(2004, 5, 6));

        service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, null, null, null, null, true));
        assertThat(users.store.get(ana.id()).birthDate()).isNull();
        assertThat(users.store.get(ana.id()).usageFocus()).isEqualTo(UsageFocus.FITNESS);
    }

    @Test
    void aFutureBirthDateIsRejected() {
        assertThatThrownBy(() -> service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, null, null,
                null, LocalDate.of(2030, 1, 1), false)))
                .isInstanceOf(InvalidBirthDateException.class);
    }

    @Test
    void anUploadedPhotoIsNotReplacedByAnOldClientSendingAnAddress() {
        String uploaded = "https://app.test/api/v1/avatars/" + ana.id() + "/" + java.util.UUID.randomUUID() + ".jpg";
        users.store.get(ana.id()).changeAvatar(uploaded);

        service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, "", null, null, null, false));

        assertThat(users.store.get(ana.id()).avatarUrl()).isEqualTo(uploaded);
    }

    @Test
    void anotherAccountsPhotoCannotBeSetAsYours() {
        String other = "https://synaptixfit.jloenit.dev/api/v1/avatars/" + UUID.randomUUID() + "/"
                + UUID.randomUUID() + ".jpg";
        assertThatThrownBy(() -> service.updateAccount(new UpdateAccountUseCase.Command(ana.id(), null, other, null,
                null, null, false))).isInstanceOf(AvatarInvalidImageException.class);
    }
}
