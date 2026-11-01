package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.BusinessRuleException;
import com.synaptixfit.domain.model.social.PostType;

/** Ese tipo de publicación no se puede crear a mano en el muro (ver {@link PostType#publishableByHand()}). */
public class PostTypeNotAllowedException extends BusinessRuleException {

    public PostTypeNotAllowedException(PostType type) {
        super("POST_TYPE_NOT_ALLOWED", "Post type " + type + " cannot be published by hand");
    }
}
