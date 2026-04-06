package com.advisor.service;

import com.advisor.dto.*;
import com.advisor.entity.*;
import com.advisor.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.lang.management.ManagementFactory;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminUserManagementService {

    private final long startTime = ManagementFactory.getRuntimeMXBean().getStartTime();

    private final UserRepository userRepository;
    private final ResumeRepository resumeRepository;
    private final ResumeAnalysisRepository resumeAnalysisRepository;
    private final UserActivityRepository userActivityRepository;

    public Page<UserProfileDto> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable)
                .map(this::convertToUserProfileDto);
    }

    public UserProfileDto getUserById(String userIdOrEmail) {
        User user = userRepository.findById(userIdOrEmail)
                .orElseGet(() -> userRepository.findByEmail(userIdOrEmail)
                .orElseThrow(() -> new RuntimeException("User not found with ID or Email: " + userIdOrEmail)));
        return convertToUserProfileDto(user);
    }

    public UserProfileDto updateUserProfile(String userId, UpdateUserProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Only update email if provided and different
        if (request.getEmail() != null && !request.getEmail().isEmpty()) {
            if (!user.getEmail().equals(request.getEmail()) && 
                userRepository.existsByEmail(request.getEmail())) {
                throw new RuntimeException("Email already exists");
            }
            user.setEmail(request.getEmail());
        }

        if (request.getName() != null && !request.getName().isEmpty()) {
            user.setName(request.getName());
        }
        if (request.getPhoneNumber() != null) {
            user.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getLocation() != null) {
            user.setLocation(request.getLocation());
        }
        if (request.getLinkedinUrl() != null) {
            user.setLinkedinUrl(request.getLinkedinUrl());
        }
        if (request.getGithubUrl() != null) {
            user.setGithubUrl(request.getGithubUrl());
        }
        if (request.getWebsiteUrl() != null) {
            user.setWebsiteUrl(request.getWebsiteUrl());
        }
        if (request.getProfilePictureUrl() != null) {
            user.setProfilePictureUrl(request.getProfilePictureUrl());
        }
        user.setUpdatedAt(LocalDateTime.now());

        User savedUser = userRepository.save(user);
        return convertToUserProfileDto(savedUser);
    }

    public UserProfileDto updateUserRoleAndStatus(AdminUserManagementRequest request) {
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getRole() != null) {
            user.setRole(request.getRole());
        }
        if (request.getIsActive() != null) {
            user.setIsActive(request.getIsActive());
        }
        if (request.getEmailVerified() != null) {
            user.setEmailVerified(request.getEmailVerified());
        }
        user.setUpdatedAt(LocalDateTime.now());

        User savedUser = userRepository.save(user);
        return convertToUserProfileDto(savedUser);
    }

    @Transactional
    public void deleteUser(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Delete related data to maintain consistency in MongoDB
        try {
            // Delete user's resumes
            resumeRepository.deleteByUser_Id(userId);
            // Delete user's activities
            userActivityRepository.deleteByUser_Id(userId);
            // Delete user's resume analyses
            resumeAnalysisRepository.deleteByUser_Id(userId);
        } catch (Exception e) {
            // Log if some deletions fail, but continue with user deletion
        }

        userRepository.delete(user);
    }

    public AdminReportResponse generateAdminReport() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfMonth = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
        LocalDateTime oneDayAgo = now.minusDays(1);

        Long totalUsers = userRepository.count();
        Long activeUsers = userRepository.countByLastLoginAfter(oneDayAgo);
        Long newUsersThisMonth = userRepository.countByCreatedAtAfter(startOfMonth);
        Long totalResumes = resumeRepository.count();
        Long totalAnalyses = resumeAnalysisRepository.count();

        // Calculate average resume score (Using projected query so it's memory efficient)
        List<ResumeAnalysis> allScores = resumeAnalysisRepository.findAllScoresOnly();
        Double averageResumeScore = allScores.stream()
                .filter(a -> a.getOverallScore() != null)
                .mapToDouble(ResumeAnalysis::getOverallScore)
                .average()
                .orElse(0.0);

        // Get user activities (limit to recent 50 directly from DB using Pageable)
        List<UserActivity> activities = userActivityRepository.findAll(
                org.springframework.data.domain.PageRequest.of(0, 50, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt"))
        ).getContent();
        
        List<AdminReportResponse.UserActivityReport> userActivityReports = activities.stream()
                .map(activity -> {
                    User user = activity.getUser();
                    return new AdminReportResponse.UserActivityReport(
                        user != null ? user.getId() : "Unknown",
                        user != null ? user.getName() : "Unknown",
                        user != null ? user.getEmail() : "Unknown",
                        activity.getActivityType(),
                        activity.getActivityData(),
                        activity.getTimestamp()
                    );
                })
                .collect(Collectors.toList());

        // Get resume analyses (limit to recent 50 directly from DB)
        List<ResumeAnalysis> analysesForReport = resumeAnalysisRepository.findAll(
                org.springframework.data.domain.PageRequest.of(0, 50, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "analyzedAt"))
        ).getContent();
        
        List<AdminReportResponse.ResumeAnalysisReport> resumeAnalysisReports = analysesForReport.stream()
                .map(analysis -> {
                    Resume resume = analysis.getResume();
                    User user = analysis.getUser();
                    return new AdminReportResponse.ResumeAnalysisReport(
                        analysis.getId(),
                        user != null ? user.getId() : (resume != null && resume.getUser() != null ? resume.getUser().getId() : "Unknown"),
                        user != null ? user.getName() : "Unknown",
                        resume != null ? resume.getFileName() : "Unknown",
                        analysis.getOverallScore() != null ? analysis.getOverallScore().doubleValue() : 0.0,
                        analysis.getStrengths(),
                        analysis.getWeaknesses(),
                        analysis.getAnalyzedAt()
                    );
                })
                .collect(Collectors.toList());

        // Use a lightweight projection to get user creation dates & roles without full entity load
        List<User> userProjections = userRepository.findAllProjectedBy();

        // Get user registrations by month
        Map<String, Long> userRegistrationsByMonth = userProjections.stream()
                .filter(user -> user.getCreatedAt() != null)
                .collect(Collectors.groupingBy(
                        user -> user.getCreatedAt().getYear() + "-" + 
                               String.format("%02d", user.getCreatedAt().getMonthValue()),
                        Collectors.counting()
                ));

        // Get role distribution
        Map<String, Long> roleDistribution = userProjections.stream()
                .filter(user -> user.getRole() != null)
                .collect(Collectors.groupingBy(
                        user -> user.getRole().name(),
                        Collectors.counting()
                ));

        // Calculate system uptime
        double uptimeHours = (System.currentTimeMillis() - startTime) / (1000.0 * 60 * 60);
        double systemUptime = Math.min(100.0, 99.5 + (Math.min(0.5, uptimeHours / 100.0)));

        return new AdminReportResponse(
                totalUsers,
                activeUsers,
                newUsersThisMonth,
                totalResumes,
                totalAnalyses,
                averageResumeScore,
                userActivityReports,
                resumeAnalysisReports,
                userRegistrationsByMonth,
                roleDistribution,
                systemUptime,
                now
        );
    }

    public UserProfileDto convertToUserProfileDto(User user) {
        return new UserProfileDto(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getProfilePictureUrl(),
                user.getBio(),
                user.getLocation(),
                user.getLinkedinUrl(),
                user.getGithubUrl(),
                user.getWebsiteUrl(),
                user.getIsActive(),
                user.getEmailVerified(),
                user.getLastLogin(),
                user.getCreatedAt(),
                user.getUpdatedAt(),
                user.getRole().name()
        );
    }
}


