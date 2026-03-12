package com.advisor.service;

import com.advisor.dto.DashboardStatsResponse;
import com.advisor.entity.*;
import com.advisor.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class DashboardService {
    
    @Autowired
    private UserProfileCompletionRepository profileCompletionRepository;
    
    @Autowired
    private CareerSuggestionRepository careerSuggestionRepository;
    
    @Autowired
    private SkillsAssessmentRepository skillsAssessmentRepository;
    
    @Autowired
    private UserActivityRepository userActivityRepository;
    
    @Autowired
    private ResumeRepository resumeRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    public DashboardStatsResponse getUserDashboardStatsByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return getUserDashboardStats(user.getId());
    }
    
    public DashboardStatsResponse getUserDashboardStats(String userId) {
        // Get profile completion data
        Optional<UserProfileCompletion> profileCompletion = profileCompletionRepository.findByUserId(userId);
        boolean hasResume = profileCompletion.map(UserProfileCompletion::getHasResume).orElse(false);
        boolean hasSkillsAssessment = profileCompletion.map(UserProfileCompletion::getHasSkillsAssessment).orElse(false);
        
        // Double check with actual assessment records if flag is false
        if (!hasSkillsAssessment) {
            hasSkillsAssessment = !skillsAssessmentRepository
                .findByUser_IdOrderByCompletedAtDesc(userId)
                .isEmpty();
            if (hasSkillsAssessment) {
                updateProfileCompletion(userId, "skills_assessment");
            }
        }
        
        int completionRate = profileCompletion.map(UserProfileCompletion::getCompletionPercentage).orElse(0);
        
        // Count suggestions
        long suggestionsCount = careerSuggestionRepository.countByUser_IdAndIsViewedFalse(userId);
        
        // Get ALL activities for the user, not just recent ones
        List<UserActivity> allActivities = userActivityRepository.findByUserIdOrderByCreatedAtDesc(userId);
        
        // Build recent activities for response (limited to 5 for the UI)
        List<DashboardStatsResponse.RecentActivity> recentActivitiesResponse = new ArrayList<>();
        int limit = Math.min(allActivities.size(), 5);
        for (int i = 0; i < limit; i++) {
            recentActivitiesResponse.add(mapActivityToResponse(allActivities.get(i)));
        }
        
        return new DashboardStatsResponse(
            hasResume,
            (int) suggestionsCount,
            hasSkillsAssessment,
            completionRate,
            allActivities.size(), // Use total count
            recentActivitiesResponse.size(), // Use limited count
            recentActivitiesResponse
        );
    }
    
    public void trackUserActivityByEmail(String email, String activityType, String activityData) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        trackUserActivity(user.getId(), activityType, activityData);
    }
    
    public void trackUserActivity(String userId, String activityType, String activityData) {
        try {
            User user = userRepository.findById(userId).orElse(null);
            UserActivity activity = new UserActivity(user, activityType, activityData);
            userActivityRepository.save(activity);
        } catch (Exception e) {
            // Do not let activity logging break primary flows like login/OTP
            System.err.println("Failed to track user activity for userId=" + userId
                    + ", type=" + activityType + ": " + e.getMessage());
        }

        try {
            // Update profile completion if needed, but never break caller on failure
            updateProfileCompletion(userId, activityType);
        } catch (Exception e) {
            System.err.println("Failed to update profile completion for userId=" + userId
                    + ", type=" + activityType + ": " + e.getMessage());
        }
    }
    
    public void updateProfileCompletion(String userId, String activityType) {
        try {
            Optional<UserProfileCompletion> profileCompletion =
                profileCompletionRepository.findByUserId(userId);
            User user = userRepository.findById(userId).orElseThrow();
            UserProfileCompletion completion =
                profileCompletion.orElse(new UserProfileCompletion(user));

            switch (activityType) {
                case "resume_upload":
                    completion.setHasResume(true);
                    break;
                case "skills_assessment":
                case "skills_assessment_completed":
                    completion.setHasSkillsAssessment(true);
                    break;
                case "career_preferences":
                    completion.setHasCareerPreferences(true);
                    break;
                case "education_update":
                    completion.setHasEducationInfo(true);
                    break;
                default:
                    // other activity types do not affect completion flags
                    break;
            }

            completion.calculateCompletionPercentage();
            try {
                profileCompletionRepository.save(completion);
            } catch (DuplicateKeyException ex) {
                // If a concurrent request already created the record or a legacy
                // duplicate exists, try to load the latest and update in place
                Optional<UserProfileCompletion> existing =
                    profileCompletionRepository.findByUser_Id(userId);
                if (existing.isPresent()) {
                    UserProfileCompletion current = existing.get();
                    current.setHasResume(completion.getHasResume());
                    current.setHasSkillsAssessment(completion.getHasSkillsAssessment());
                    current.setHasCareerPreferences(completion.getHasCareerPreferences());
                    current.setHasEducationInfo(completion.getHasEducationInfo());
                    current.calculateCompletionPercentage();
                    try {
                        profileCompletionRepository.save(current);
                    } catch (DuplicateKeyException ignore) {
                        // Final safeguard: never break login/OTP on profile completion issues.
                    }
                }
            }
        } catch (Exception e) {
            // Swallow any error to keep critical flows working
            System.err.println("updateProfileCompletion failed for userId="
                    + userId + ", type=" + activityType + ": " + e.getMessage());
        }
    }
    
    private DashboardStatsResponse.RecentActivity mapActivityToResponse(UserActivity activity) {
        String message = getActivityMessage(activity.getActivityType());
        String icon = getActivityIcon(activity.getActivityType());
        String color = getActivityColor(activity.getActivityType());
        String timestamp = activity.getCreatedAt().format(DateTimeFormatter.ofPattern("MMM dd, yyyy 'at' HH:mm"));
        
        return new DashboardStatsResponse.RecentActivity(
            activity.getActivityType(),
            message,
            timestamp,
            icon,
            color
        );
    }
    
    private String getActivityMessage(String activityType) {
        if (activityType == null) return "Activity completed";
        switch (activityType) {
            case "resume_upload":
                return "Resume uploaded successfully";
            case "skills_assessment":
                return "Skills assessment completed";
            case "login":
                return "Logged in successfully";
            case "profile_update":
                return "Profile updated";
            case "career_suggestion_viewed":
                return "Viewed career suggestions";
            case "career_application":
                return "Applied for a career path";
            case "career_saved":
                return "Saved a career path";
            case "dashboard_visit":
                return "Visited dashboard";
            default:
                return activityType.replace("_", " ").substring(0, 1).toUpperCase() + 
                       activityType.replace("_", " ").substring(1);
        }
    }
    
    private String getActivityIcon(String activityType) {
        if (activityType == null) return "ri-check-line";
        switch (activityType) {
            case "resume_upload":
                return "ri-file-text-line";
            case "skills_assessment":
                return "ri-brain-line";
            case "login":
                return "ri-login-box-line";
            case "profile_update":
                return "ri-user-settings-line";
            case "career_suggestion_viewed":
                return "ri-lightbulb-line";
            case "career_application":
                return "ri-send-plane-line";
            case "career_saved":
                return "ri-bookmark-line";
            case "dashboard_visit":
                return "ri-dashboard-line";
            default:
                return "ri-check-line";
        }
    }
    
    private String getActivityColor(String activityType) {
        if (activityType == null) return "text-gray-600";
        switch (activityType) {
            case "resume_upload":
                return "text-green-600";
            case "skills_assessment":
                return "text-purple-600";
            case "login":
                return "text-blue-600";
            case "profile_update":
                return "text-orange-600";
            case "career_suggestion_viewed":
                return "text-yellow-600";
            case "career_application":
                return "text-indigo-600";
            case "career_saved":
                return "text-pink-600";
            case "dashboard_visit":
                return "text-cyan-600";
            default:
                return "text-gray-600";
        }
    }
}
