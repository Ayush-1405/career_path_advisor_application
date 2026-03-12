package com.advisor.controller;

import com.advisor.dto.AdminDashboardStatsResponse;
import com.advisor.service.AdminDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
public class AdminDashboardController {
    
    @Autowired
    private AdminDashboardService adminDashboardService;
    
    @GetMapping("/dashboard/stats")
    public ResponseEntity<AdminDashboardStatsResponse> getAdminDashboardStats() {
        try {
            AdminDashboardStatsResponse stats = adminDashboardService.getAdminDashboardStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            // Return default stats on error
            AdminDashboardStatsResponse defaultStats = new AdminDashboardStatsResponse(
                0L, 0L, 0L, 0L, 0L, 0L, 0.0, 0.0, 98.5, new java.util.ArrayList<>()
            );
            return ResponseEntity.ok(defaultStats);
        }
    }
    
    @GetMapping("/analytics")
    public ResponseEntity<Object> getAnalytics() {
        try {
            // This would return more detailed analytics
            // For now, return basic structure
            return ResponseEntity.ok(java.util.Map.of(
                "message", "Analytics endpoint - implement detailed analytics here",
                "timestamp", java.time.LocalDateTime.now()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to get analytics: " + e.getMessage());
        }
    }
}
