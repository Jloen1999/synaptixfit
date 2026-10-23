package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.UserCard;
import java.util.UUID;

/** Busca usuarios por nombre para añadirlos (respeta privacidad, shadowban y bloqueos). */
public interface SearchUsersUseCase {

    PageResult<UserCard> search(UUID viewerId, String term, PageRequest page);
}
