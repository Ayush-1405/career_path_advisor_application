package com.advisor.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AdminDashboardStatsResponse {
    
    private long totalUsers;
    private long verifiedUsers;
    private long resumesParsed;
    private long activeUsers;
    private long newUsersToday;
    private long successfulLogins;
    private double verificationRate;
    private double completionRate;
    private double systemUptime;
    private List<AdminRecentActivity> recentActivities;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdminRecentActivity {
        private String type;
        private String message;
        private String timestamp;
        private String icon;
        private String color;
    }
}
