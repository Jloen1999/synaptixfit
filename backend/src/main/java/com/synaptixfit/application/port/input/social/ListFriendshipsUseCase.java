package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.social.FriendshipView;
import java.util.UUID;

/** Amigos, solicitudes recibidas o enviadas y usuarios bloqueados. */
public interface ListFriendshipsUseCase {

    PageResult<FriendshipView> list(UUID userId, FriendshipListKind kind, PageRequest page);
}
