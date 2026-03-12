package com.advisor.service;

import com.advisor.dto.ResumeUpdateRequest;
import com.advisor.entity.ResumeProfile;
import com.advisor.entity.User;
import com.advisor.repository.ResumeProfileRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class ResumeProfileService {

    private final ResumeProfileRepository resumeProfileRepository;
    private final UserRepository userRepository;
    private final ResumeAnalysisService resumeAnalysisService;
    private final ResumeParsingService resumeParsingService;

    public ResumeProfile getOrCreateForUser(User user) {
        return resumeProfileRepository.findByUser_Id(user.getId())
                .orElseGet(() -> {
                    ResumeProfile rp = new ResumeProfile();
                    rp.setUser(user);
                    rp.setCreatedAt(LocalDateTime.now());
                    rp.setUpdatedAt(LocalDateTime.now());
                    return saveSafe(rp);
                });
    }

    public ResumeProfile getByUserId(String userId) {
        return resumeProfileRepository.findByUser_Id(userId).orElse(null);
    }

    public ResumeProfile updateFromRequest(User authUser, ResumeUpdateRequest req) {
        User targetUser = authUser;
        if (req.getUserId() != null && !req.getUserId().isBlank()) {
            // Only allow editing own resume unless admin; simple rule: must match auth user
            if (!req.getUserId().equals(authUser.getId())) {
                throw new RuntimeException("Unauthorized");
            }
            targetUser = userRepository.findById(req.getUserId()).orElseThrow();
        }

        ResumeProfile rp = getOrCreateForUser(targetUser);
        rp.setName(req.getName());
        rp.setEmail(req.getEmail());
        rp.setPhone(req.getPhone());
        rp.setSummary(req.getSummary());
        rp.setSkills(req.getSkills());
        rp.setEducation(req.getEducation());
        rp.setExperience(req.getExperience());
        rp.setProjects(req.getProjects());
        rp.setUpdatedAt(LocalDateTime.now());
        return saveSafe(rp);
    }

    public ResumeProfile uploadAndParse(User user, ResumeStorageService.StoredFile storedFile) {
        ResumeProfile rp = getOrCreateForUser(user);

        rp.setOriginalFileName(storedFile.originalFileName());
        rp.setStoredFileName(storedFile.storedFileName());
        rp.setFileType(storedFile.fileType());
        rp.setFileSize(storedFile.fileSize());
        rp.setFilePath(storedFile.filePath());
        rp.setFileUrl(storedFile.fileUrl());

        String text = resumeAnalysisService.extractTextForParsing(storedFile.filePath(), storedFile.fileType());
        ResumeProfile parsed = resumeParsingService.parseToProfile(text);

        // Only fill if empty so user edits are not overwritten repeatedly
        if (isBlank(rp.getName())) rp.setName(parsed.getName());
        if (isBlank(rp.getEmail())) rp.setEmail(parsed.getEmail());
        if (isBlank(rp.getPhone())) rp.setPhone(parsed.getPhone());
        if (rp.getSkills() == null || rp.getSkills().isEmpty()) rp.setSkills(parsed.getSkills());
        if (isBlank(rp.getSummary())) rp.setSummary(parsed.getSummary());
        if (rp.getEducation() == null || rp.getEducation().isEmpty()) rp.setEducation(parsed.getEducation());
        if (rp.getExperience() == null || rp.getExperience().isEmpty()) rp.setExperience(parsed.getExperience());
        if (rp.getProjects() == null || rp.getProjects().isEmpty()) rp.setProjects(parsed.getProjects());

        rp.setUpdatedAt(LocalDateTime.now());
        return saveSafe(rp);
    }

    private ResumeProfile saveSafe(ResumeProfile rp) {
        try {
            return resumeProfileRepository.save(rp);
        } catch (DuplicateKeyException e) {
            // In case of legacy duplicates, re-load and update
            ResumeProfile existing = resumeProfileRepository.findByUser_Id(rp.getUser().getId()).orElse(null);
            if (existing == null) throw e;
            rp.setId(existing.getId());
            return resumeProfileRepository.save(rp);
        }
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}

