package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;

/** Listado paginado de usuarios con búsqueda, filtros y ordenación. */
public interface SearchUsersUseCase {

    PageResult<AdminUserSummary> searchUsers(UserSearchCriteria criteria, PageRequest page);
}
