package com.advisor.service;

import com.advisor.entity.CareerPath;
import com.advisor.entity.User;
import com.advisor.entity.UserCareerPath;
import com.advisor.entity.UserSavedCareerPath;
import com.advisor.repository.CareerPathRepository;
import com.advisor.repository.UserCareerPathRepository;
import com.advisor.repository.UserSavedCareerPathRepository;
import com.advisor.repository.UserRepository;
import com.advisor.repository.ResumeAnalysisRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserCareerPathService {
    private final UserCareerPathRepository userCareerPathRepository;
    private final CareerPathRepository careerPathRepository;
    private final UserRepository userRepository;
    private final UserSavedCareerPathRepository userSavedCareerPathRepository;
    private final DashboardService dashboardService;
    private final ResumeAnalysisRepository resumeAnalysisRepository;

    public UserCareerPath applyForCareerPath(User user, String careerPathId) {
        CareerPath careerPath = careerPathRepository.findById(careerPathId)
                .orElseThrow(() -> new RuntimeException("Career path not found"));

        // Check if already applied
        UserCareerPath existing = userCareerPathRepository.findByUser_IdAndCareerPath_Id(user.getId(), careerPathId)
                .orElse(null);
        
        if (existing != null) {
            return existing;
        }

        UserCareerPath application = UserCareerPath.builder()
                .user(user)
                .careerPath(careerPath)
                .status("APPLIED")
                .appliedAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        
        UserCareerPath saved = userCareerPathRepository.save(application);
        
        // Track activity
        dashboardService.trackUserActivity(user.getId(), "career_application", 
                "{\"title\":\"" + careerPath.getTitle() + "\", \"id\":\"" + careerPath.getId() + "\"}");
        
        return saved;
    }

    public List<UserCareerPath> getUserApplications(User user) {
        return userCareerPathRepository.findByUser_Id(user.getId());
    }

    public List<UserCareerPath> getAllApplications() {
        return userCareerPathRepository.findAllByOrderByAppliedAtDesc();
    }

    public UserCareerPath updateStatus(String applicationId, String status) {
        UserCareerPath application = userCareerPathRepository.findById(applicationId)
                .orElseThrow(() -> new RuntimeException("Application not found"));
        
        application.setStatus(status);
        application.setUpdatedAt(LocalDateTime.now());
        return userCareerPathRepository.save(application);
    }

    // Saved career paths (bookmarks)
    public List<UserSavedCareerPath> getUserSavedCareers(User user) {
        return userSavedCareerPathRepository.findByUser_Id(user.getId());
    }

    public UserSavedCareerPath saveCareerPath(User user, String careerPathId) {
        CareerPath careerPath = careerPathRepository.findById(careerPathId)
                .orElseThrow(() -> new RuntimeException("Career path not found"));
        boolean exists = userSavedCareerPathRepository.existsByUser_IdAndCareerPath_Id(user.getId(), careerPathId);
        if (exists) {
            // Return existing without duplicate
            return userSavedCareerPathRepository.findByUser_Id(user.getId()).stream()
                    .filter(x -> x.getCareerPath().getId().equals(careerPathId))
                    .findFirst()
                    .orElseGet(() -> userSavedCareerPathRepository.save(
                            UserSavedCareerPath.builder()
                                    .user(user)
                                    .careerPath(careerPath)
                                    .build()
                    ));
        }
        UserSavedCareerPath saved = UserSavedCareerPath.builder()
                .user(user)
                .careerPath(careerPath)
                .build();
        UserSavedCareerPath result = userSavedCareerPathRepository.save(saved);
        
        // Track activity
        dashboardService.trackUserActivity(user.getId(), "career_saved", 
                "{\"title\":\"" + careerPath.getTitle() + "\", \"id\":\"" + careerPath.getId() + "\"}");
        
        return result;
    }

    public void unsaveCareerPath(User user, String careerPathId) {
        userSavedCareerPathRepository.deleteByUser_IdAndCareerPath_Id(user.getId(), careerPathId);
    }

    public List<CareerPath> getRecommendations(String userId) {
        // 1. Get the latest resume analysis
        return resumeAnalysisRepository.findTopByUser_IdOrderByAnalyzedAtDesc(userId)
                .map(analysis -> {
                    // 2. Extract skills from strengths (comma-separated list)
                    String strengths = analysis.getStrengths();
                    if (strengths == null || strengths.isEmpty()) {
                        return careerPathRepository.findAll(); // Fallback to all if no strengths
                    }
                    
                    List<String> userSkills = java.util.Arrays.stream(strengths.split(","))
                            .map(String::trim)
                            .map(String::toLowerCase)
                            .collect(java.util.stream.Collectors.toList());

                    // 3. Match against CareerPaths
                    return careerPathRepository.findAll().stream()
                            .sorted((cp1, cp2) -> {
                                long match1 = cp1.getRequiredSkills().stream()
                                        .filter(s -> userSkills.contains(s.toLowerCase()))
                                        .count();
                                long match2 = cp2.getRequiredSkills().stream()
                                        .filter(s -> userSkills.contains(s.toLowerCase()))
                                        .count();
                                return Long.compare(match2, match1); // Descending score
                            })
                            .limit(5)
                            .collect(java.util.stream.Collectors.toList());
                })
                .orElseGet(careerPathRepository::findAll); // Fallback to all
    }
}
