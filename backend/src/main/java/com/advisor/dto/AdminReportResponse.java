package com.advisor.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AdminReportResponse {
    private Long totalUsers;
    private Long activeUsers;
    private Long newUsersThisMonth;
    private Long totalResumes;
    private Long totalAnalyses;
    private Double averageResumeScore;
    private List<UserActivityReport> userActivities;
    private List<ResumeAnalysisReport> resumeAnalyses;
    private Map<String, Long> userRegistrationsByMonth;
    private Map<String, Long> roleDistribution;
    private Double systemUptime;
    private LocalDateTime generatedAt;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserActivityReport {
        private String userId;
        private String userName;
        private String userEmail;
        private String activityType;
        private String activityData;
        private LocalDateTime timestamp;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ResumeAnalysisReport {
        private String analysisId;
        private String userId;
        private String userName;
        private String resumeFileName;
        private Double overallScore;
        private String strengths;
        private String weaknesses;
        private LocalDateTime analyzedAt;
    }
}
