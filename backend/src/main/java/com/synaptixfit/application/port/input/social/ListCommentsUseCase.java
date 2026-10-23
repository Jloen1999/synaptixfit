package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.CommentView;
import java.util.UUID;

/** Comentarios de una publicación visible, del más antiguo al más reciente. */
public interface ListCommentsUseCase {

    PageResult<CommentView> listComments(UUID viewerId, UUID postId, PageRequest page);
}
