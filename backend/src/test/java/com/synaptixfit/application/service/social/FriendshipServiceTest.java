package com.synaptixfit.application.service.social;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.social.FriendshipAlreadyExistsException;
import com.synaptixfit.domain.exception.social.FriendshipBlockedException;
import com.synaptixfit.domain.exception.social.FriendshipInvalidStateException;
import com.synaptixfit.domain.exception.social.FriendshipNotFoundException;
import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import com.synaptixfit.domain.exception.social.SocialUserNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.FriendshipStatus;
import com.synaptixfit.domain.model.social.FriendshipView;
import com.synaptixfit.domain.model.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class FriendshipServiceTest {

    private SocialFakes fakes;
    private FriendshipService service;
    private User ana;
    private User bea;

    @BeforeEach
    void setUp() {
        fakes = new SocialFakes();
        service = new FriendshipService(fakes.friendshipPort(), fakes.userPort(), fakes.queryPort(),
                fakes.notificationPort(), SocialFakes.CLOCK);
        ana = fakes.user("Ana", Visibility.PUBLIC);
        bea = fakes.user("Bea", Visibility.FRIENDS);
    }

    @Test
    void requestThenAcceptNotifiesBothWays() {
        FriendshipView sent = service.sendRequest(ana.id(), bea.id());
        assertThat(sent.relation()).isEqualTo(FriendshipRelation.REQUEST_SENT);
        assertThat(sent.userId()).isEqualTo(bea.id());

        FriendshipView accepted = service.accept(bea.id(), sent.id());
        assertThat(accepted.status()).isEqualTo(FriendshipStatus.ACCEPTED);
        assertThat(accepted.relation()).isEqualTo(FriendshipRelation.FRIENDS);
        assertThat(fakes.notifications).extracting(c -> c.userId()).containsExactly(bea.id(), ana.id());
    }

    @Test
    void cannotRequestSelfOrDuplicate() {
        assertThatThrownBy(() -> service.sendRequest(ana.id(), ana.id()))
                .isInstanceOf(FriendshipSelfTargetException.class);
        service.sendRequest(ana.id(), bea.id());
        assertThatThrownBy(() -> service.sendRequest(ana.id(), bea.id()))
                .isInstanceOf(FriendshipAlreadyExistsException.class);
    }

    @Test
    void mutualRequestIsAccepted() {
        service.sendRequest(ana.id(), bea.id());
        FriendshipView result = service.sendRequest(bea.id(), ana.id());
        assertThat(result.status()).isEqualTo(FriendshipStatus.ACCEPTED);
        assertThatThrownBy(() -> service.sendRequest(ana.id(), bea.id()))
                .isInstanceOf(FriendshipAlreadyExistsException.class);
    }

    @Test
    void onlyAddresseeCanAcceptOrReject() {
        FriendshipView sent = service.sendRequest(ana.id(), bea.id());
        assertThatThrownBy(() -> service.accept(ana.id(), sent.id()))
                .isInstanceOf(FriendshipInvalidStateException.class);
        User other = fakes.user("Otra", Visibility.PUBLIC);
        assertThatThrownBy(() -> service.accept(other.id(), sent.id()))
                .isInstanceOf(FriendshipNotFoundException.class);
    }

    @Test
    void rejectedRequestCanBeRenewed() {
        FriendshipView sent = service.sendRequest(ana.id(), bea.id());
        FriendshipView rejected = service.reject(bea.id(), sent.id());
        assertThat(rejected.status()).isEqualTo(FriendshipStatus.REJECTED);

        FriendshipView renewed = service.sendRequest(ana.id(), bea.id());
        assertThat(renewed.status()).isEqualTo(FriendshipStatus.PENDING);
        assertThat(renewed.id()).isEqualTo(sent.id());
    }

    @Test
    void blockingHidesTheBlockerAndOnlyBlockerCanUnblock() {
        service.sendRequest(ana.id(), bea.id());
        FriendshipView block = service.block(bea.id(), ana.id());
        assertThat(block.status()).isEqualTo(FriendshipStatus.BLOCKED);
        assertThat(block.relation()).isEqualTo(FriendshipRelation.BLOCKED);

        // Para la bloqueada, Bea ya no existe.
        assertThatThrownBy(() -> service.sendRequest(ana.id(), bea.id()))
                .isInstanceOf(SocialUserNotFoundException.class);
        assertThatThrownBy(() -> service.remove(ana.id(), block.id()))
                .isInstanceOf(FriendshipNotFoundException.class);
        // Quien bloquea debe desbloquear antes de pedir amistad.
        assertThatThrownBy(() -> service.sendRequest(bea.id(), ana.id()))
                .isInstanceOf(FriendshipBlockedException.class);

        service.remove(bea.id(), block.id());
        assertThat(fakes.friendships).isEmpty();
    }

    @Test
    void cannotRequestShadowbannedOrMissingUsers() {
        User troll = fakes.user("Troll", Visibility.PUBLIC, true);
        assertThatThrownBy(() -> service.sendRequest(ana.id(), troll.id()))
                .isInstanceOf(SocialUserNotFoundException.class);
        assertThatThrownBy(() -> service.sendRequest(ana.id(), java.util.UUID.randomUUID()))
                .isInstanceOf(SocialUserNotFoundException.class);
    }

    @Test
    void requestFromShadowbannedUserIsSilent() {
        User troll = fakes.user("Troll", Visibility.PUBLIC, true);
        service.sendRequest(troll.id(), ana.id());
        assertThat(fakes.notifications).isEmpty();
    }
}
