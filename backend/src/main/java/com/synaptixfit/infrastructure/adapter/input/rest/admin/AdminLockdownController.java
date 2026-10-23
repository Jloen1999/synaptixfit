package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import com.synaptixfit.application.port.input.admin.GetLockdownUseCase;
import com.synaptixfit.application.port.input.admin.SetLockdownUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.LockdownResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.SetLockdownRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Modo bloqueo de la plataforma (las cuentas nuevas nacen ocultas). */
@Tag(name = "Admin - Lockdown")
@RestController
@RequestMapping("/api/v1/admin/lockdown")
public class AdminLockdownController {

    private final GetLockdownUseCase getLockdown;
    private final SetLockdownUseCase setLockdown;

    public AdminLockdownController(GetLockdownUseCase getLockdown, SetLockdownUseCase setLockdown) {
        this.getLockdown = getLockdown;
        this.setLockdown = setLockdown;
    }

    @GetMapping
    public LockdownResponse get() {
        return LockdownResponse.from(getLockdown.getLockdown());
    }

    @PutMapping
    public LockdownResponse set(@CurrentUserId UUID adminId, @Valid @RequestBody SetLockdownRequest request) {
        return LockdownResponse.from(setLockdown.setLockdown(adminId, request.active()));
    }
}
