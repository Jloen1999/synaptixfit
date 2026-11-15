package com.synaptixfit.application.port.input.together;

/** Los topes de «Con amigos» que manda el servidor (ADR 0045): el cliente no los repite. */
public interface GetTogetherLimitsUseCase {

    TogetherLimits limits();
}
