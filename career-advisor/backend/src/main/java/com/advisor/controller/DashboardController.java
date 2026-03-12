package com.advisor.controller;

import com.advisor.dto.DashboardStatsResponse;
import com.advisor.service.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users/me")
public class DashboardController {
    
    @Autowired
    private DashboardService dashboardService;
    
    @GetMapping("/stats")
    public ResponseEntity<DashboardStatsResponse> getDashboardStats(Authentication authentication) {
        try {
            // Get user by email from authentication
            String email = authentication.getName();
            DashboardStatsResponse stats = dashboardService.getUserDashboardStatsByEmail(email);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            // Return default stats on error
            DashboardStatsResponse defaultStats = new DashboardStatsResponse(
                false, 0, false, 0, 0, 0, new java.util.ArrayList<>()
            );
            return ResponseEntity.ok(defaultStats);
        }
    }
    
    @PostMapping("/activity")
    public ResponseEntity<String> trackActivity(
            @RequestParam String activityType,
            @RequestParam(required = false) String activityData,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            dashboardService.trackUserActivityByEmail(email, activityType, activityData);
            return ResponseEntity.ok("Activity tracked successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to track activity: " + e.getMessage());
        }
    }
}
