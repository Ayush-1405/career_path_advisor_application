package com.advisor.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsResponse {
    
    private boolean resumeUploaded;
    private int suggestionsAvailable;
    private boolean skillsAssessed;
    private int completionRate;
    private int totalActivities;
    private int recentActivitiesCount;
    private List<RecentActivity> recentActivities;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RecentActivity {
        private String type;
        private String message;
        private String timestamp;
        private String icon;
        private String color;
    }
}
