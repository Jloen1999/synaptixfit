package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Número de amigos invitados fuera de los límites (reto: 1-24 amigos; entrenar juntos: 1-4). */
public class TogetherGroupSizeException extends BusinessRuleException {

    public TogetherGroupSizeException(int invited, int min, int max) {
        super("TOGETHER_GROUP_SIZE", "Invited " + invited + " friends; allowed " + min + "-" + max);
    }
}
