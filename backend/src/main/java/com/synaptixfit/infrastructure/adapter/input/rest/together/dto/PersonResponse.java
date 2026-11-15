package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.Person;
import java.util.UUID;

/** Otra persona en lo compartido con amigos: solo nombre y foto ({@code fullName} nulo si borró su cuenta). */
public record PersonResponse(UUID id, String fullName, String avatarUrl) {

    public static PersonResponse from(Person p) {
        return new PersonResponse(p.id(), p.name(), p.avatarUrl());
    }
}
