package com.advisor.dto;

import lombok.Data;
import com.advisor.entity.Role;
import jakarta.validation.constraints.NotNull;

@Data
public class AdminUserManagementRequest {
    @NotNull(message = "User ID is required")
    private String userId;
    
    private Role role;
    private Boolean isActive;
    private Boolean emailVerified;
}
