package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.application.port.input.social.AcceptFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.BlockUserUseCase;
import com.synaptixfit.application.port.input.social.ListFriendshipsUseCase;
import com.synaptixfit.application.port.input.social.RejectFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.RemoveFriendshipUseCase;
import com.synaptixfit.application.port.input.social.SendFriendRequestUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.FriendshipResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.UserTargetRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Amistades: solicitudes, aceptación, rechazo, bloqueo y listados. */
@Tag(name = "Social - Friends")
@RestController
@RequestMapping("/api/v1/social/friends")
public class FriendshipController {

    private final ListFriendshipsUseCase listFriendships;
    private final SendFriendRequestUseCase sendRequest;
    private final AcceptFriendRequestUseCase acceptRequest;
    private final RejectFriendRequestUseCase rejectRequest;
    private final BlockUserUseCase blockUser;
    private final RemoveFriendshipUseCase removeFriendship;

    public FriendshipController(ListFriendshipsUseCase listFriendships, SendFriendRequestUseCase sendRequest,
                                AcceptFriendRequestUseCase acceptRequest, RejectFriendRequestUseCase rejectRequest,
                                BlockUserUseCase blockUser, RemoveFriendshipUseCase removeFriendship) {
        this.listFriendships = listFriendships;
        this.sendRequest = sendRequest;
        this.acceptRequest = acceptRequest;
        this.rejectRequest = rejectRequest;
        this.blockUser = blockUser;
        this.removeFriendship = removeFriendship;
    }

    @GetMapping
    public PageResponse<FriendshipResponse> list(@CurrentUserId UUID userId,
                                                 @RequestParam(defaultValue = "FRIENDS") FriendshipListKind kind,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listFriendships.list(userId, kind, new PageRequest(page, size)),
                FriendshipResponse::from);
    }

    @PostMapping("/requests")
    @ResponseStatus(HttpStatus.CREATED)
    public FriendshipResponse sendRequest(@CurrentUserId UUID userId, @Valid @RequestBody UserTargetRequest request) {
        return FriendshipResponse.from(sendRequest.sendRequest(userId, request.userId()));
    }

    @PostMapping("/{friendshipId}/accept")
    public FriendshipResponse accept(@CurrentUserId UUID userId, @PathVariable UUID friendshipId) {
        return FriendshipResponse.from(acceptRequest.accept(userId, friendshipId));
    }

    @PostMapping("/{friendshipId}/reject")
    public FriendshipResponse reject(@CurrentUserId UUID userId, @PathVariable UUID friendshipId) {
        return FriendshipResponse.from(rejectRequest.reject(userId, friendshipId));
    }

    @PostMapping("/blocks")
    public FriendshipResponse block(@CurrentUserId UUID userId, @Valid @RequestBody UserTargetRequest request) {
        return FriendshipResponse.from(blockUser.block(userId, request.userId()));
    }

    /** Cancela una solicitud enviada, elimina una amistad, limpia un rechazo o desbloquea. */
    @DeleteMapping("/{friendshipId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@CurrentUserId UUID userId, @PathVariable UUID friendshipId) {
        removeFriendship.remove(userId, friendshipId);
    }
}
