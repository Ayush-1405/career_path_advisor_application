package com.advisor.controller;

import com.advisor.dto.*;
import com.advisor.entity.*;
import com.advisor.repository.*;
import com.advisor.service.AdminUserManagementService;
import com.advisor.service.SystemSettingsService;
import com.advisor.service.UserCareerPathService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {
    private final UserRepository userRepository;
    private final ResumeRepository resumeRepository;
    private final ResumeAnalysisRepository resumeAnalysisRepository;
    private final AdminUserManagementService adminUserManagementService;
    private final SystemSettingsService systemSettingsService;
    private final UserCareerPathService userCareerPathService;
    private final CareerPathRepository careerPathRepository;

    // User Management Endpoints
    @GetMapping("/users")
    public ResponseEntity<Page<UserProfileDto>> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<UserProfileDto> users = adminUserManagementService.getAllUsers(pageable);
        return ResponseEntity.ok(users);
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<UserProfileDto> getUserById(@PathVariable String userId) {
        try {
            UserProfileDto user = adminUserManagementService.getUserById(userId);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/users/{userId}")
    public ResponseEntity<UserProfileDto> updateUserProfile(
            @PathVariable String userId,
            @RequestBody UpdateUserProfileRequest request) {
        try {
            UserProfileDto updatedUser = adminUserManagementService.updateUserProfile(userId, request);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @PutMapping("/users/{userId}/role-status")
    public ResponseEntity<UserProfileDto> updateUserRoleAndStatus(
            @PathVariable String userId,
            @RequestBody AdminUserManagementRequest request) {
        try {
            request.setUserId(userId);
            UserProfileDto updatedUser = adminUserManagementService.updateUserRoleAndStatus(request);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<?> deleteUser(@PathVariable String userId) {
        try {
            adminUserManagementService.deleteUser(userId);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Reports and Analytics
    @GetMapping("/reports/overview")
    public ResponseEntity<AdminReportResponse> getAdminReport() {
        try {
            AdminReportResponse report = adminUserManagementService.generateAdminReport();
            return ResponseEntity.ok(report);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @GetMapping(value = "/reports/export", produces = MediaType.APPLICATION_OCTET_STREAM_VALUE)
    public ResponseEntity<byte[]> exportReport(@RequestParam(defaultValue = "csv") String format) {
        try {
            AdminReportResponse report = adminUserManagementService.generateAdminReport();
            if ("csv".equalsIgnoreCase(format)) {
                String csv = buildReportCsv(report);
                String filename = "admin-report-" + java.time.LocalDate.now() + ".csv";
                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                        .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                        .body(csv.getBytes(StandardCharsets.UTF_8));
            }
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    private String buildReportCsv(AdminReportResponse r) {
        StringBuilder sb = new StringBuilder();
        sb.append("Metric,Value\n");
        sb.append("Total Users,").append(r.getTotalUsers()).append("\n");
        sb.append("Active Users,").append(r.getActiveUsers()).append("\n");
        sb.append("New Users This Month,").append(r.getNewUsersThisMonth()).append("\n");
        sb.append("Total Resumes,").append(r.getTotalResumes()).append("\n");
        sb.append("Total Analyses,").append(r.getTotalAnalyses()).append("\n");
        sb.append("Average Resume Score,").append(r.getAverageResumeScore() != null ? r.getAverageResumeScore() : "").append("\n");
        if (r.getRoleDistribution() != null) {
            sb.append("\nRole,Count\n");
            r.getRoleDistribution().forEach((role, count) -> sb.append(role).append(",").append(count).append("\n"));
        }
        return sb.toString();
    }

    // Legacy endpoints for backward compatibility
    @GetMapping("/resumes")
    public List<Resume> resumes() { 
        return resumeRepository.findAll(); 
    }

    @GetMapping("/analyses")
    public List<ResumeAnalysis> analyses() { 
        return resumeAnalysisRepository.findAll(); 
    }

    // Search and filter endpoints
    @GetMapping("/users/search")
    public ResponseEntity<Page<UserProfileDto>> searchUsers(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(page, size);
        // This would need to be implemented in the service with custom query
        Page<UserProfileDto> users = adminUserManagementService.getAllUsers(pageable);
        return ResponseEntity.ok(users);
    }

    @GetMapping("/users/role/{role}")
    public ResponseEntity<List<UserProfileDto>> getUsersByRole(@PathVariable String role) {
        try {
            List<User> users = userRepository.findByRole(Role.valueOf(role.toUpperCase()));
            List<UserProfileDto> userDtos = users.stream()
                    .map(user -> adminUserManagementService.convertToUserProfileDto(user))
                    .collect(java.util.stream.Collectors.toList());
            return ResponseEntity.ok(userDtos);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    // Settings
    @GetMapping("/settings")
    public ResponseEntity<SystemSettings> getSettings() {
        return ResponseEntity.ok(systemSettingsService.getSettings());
    }

    @PutMapping("/settings")
    public ResponseEntity<SystemSettings> updateSettings(@RequestBody SystemSettings settings) {
        return ResponseEntity.ok(systemSettingsService.updateSettings(settings));
    }

    // Career Path Applications Management
    @GetMapping("/applications")
    public ResponseEntity<List<UserCareerPath>> getAllApplications() {
        return ResponseEntity.ok(userCareerPathService.getAllApplications());
    }

    @PostMapping("/applications/seed")
    public ResponseEntity<Map<String, Object>> seedApplications() {
        List<UserCareerPath> existing = userCareerPathService.getAllApplications();
        if (!existing.isEmpty()) {
            return ResponseEntity.ok(Map.of("message", "Applications already exist", "count", existing.size()));
        }
        List<com.advisor.entity.CareerPath> paths = careerPathRepository.findAll();
        if (paths.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "No career paths available to seed"));
        }
        String pathId = paths.get(0).getId();
        List<com.advisor.entity.User> users = userRepository.findAll();
        int created = 0;
        for (com.advisor.entity.User u : users) {
            try {
                userCareerPathService.applyForCareerPath(u, pathId);
                created++;
            } catch (RuntimeException ignored) {}
        }
        return ResponseEntity.ok(Map.of("created", created));
    }
    @PutMapping("/applications/{id}/status")
    public ResponseEntity<UserCareerPath> updateApplicationStatus(
            @PathVariable String id,
            @RequestBody Map<String, String> statusUpdate) {
        String status = statusUpdate.get("status");
        if (status == null) {
            return ResponseEntity.badRequest().build();
        }
        try {
            return ResponseEntity.ok(userCareerPathService.updateStatus(id, status));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
