package com.advisor.controller;

import com.advisor.dto.*;
import com.advisor.entity.*;
import com.advisor.repository.*;
import com.advisor.service.AdminUserManagementService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@Slf4j
public class UserProfileController {

    private final UserRepository userRepository;
    private final AdminUserManagementService adminUserManagementService;

    @GetMapping("/profile")
    public ResponseEntity<UserProfileDto> getCurrentUserProfile() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth.getName();
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            UserProfileDto profile = adminUserManagementService.convertToUserProfileDto(user);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<UserProfileDto> updateCurrentUserProfile(@RequestBody UpdateUserProfileRequest request) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth.getName();
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            UserProfileDto updatedProfile = adminUserManagementService.updateUserProfile(user.getId(), request);
            return ResponseEntity.ok(updatedProfile);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @GetMapping("/profile/{userId}")
    public ResponseEntity<UserProfileDto> getUserProfile(@PathVariable String userId) {
        try {
            UserProfileDto profile = adminUserManagementService.getUserById(userId);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/profile")
    public ResponseEntity<?> deleteCurrentUserProfile() {
        log.info("Received request to delete current user profile");
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth.getName();
            log.info("Deleting profile for user: {}", userId);
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            adminUserManagementService.deleteUser(user.getId());
            log.info("Successfully deleted profile for user: {}", userId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error deleting user profile: {}", e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/ping")
    public ResponseEntity<?> pingUserActivity() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth.getName();
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            user.setLastActive(java.time.LocalDateTime.now());
            userRepository.save(user);
            return ResponseEntity.ok(java.util.Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/status/{userId}")
    public ResponseEntity<java.util.Map<String, Object>> getUserStatus(@PathVariable String userId) {
        try {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            boolean isOnline = false;
            if (user.getLastActive() != null) {
                isOnline = user.getLastActive().isAfter(java.time.LocalDateTime.now().minusMinutes(2));
            }
            return ResponseEntity.ok(java.util.Map.of(
                "success", true,
                "isOnline", isOnline,
                "lastActive", user.getLastActive() != null ? user.getLastActive().toString() : ""
            ));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
}





