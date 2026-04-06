package com.advisor.controller;

import com.advisor.dto.ResumeUpdateRequest;
import com.advisor.entity.ResumeProfile;
import com.advisor.entity.User;
import com.advisor.repository.UserRepository;
import com.advisor.service.DashboardService;
import com.advisor.service.ResumePdfService;
import com.advisor.service.ResumeProfileService;
import com.advisor.service.ResumeStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/resume")
@RequiredArgsConstructor
public class ResumeProfileController {

    private final UserRepository userRepository;
    private final ResumeProfileService resumeProfileService;
    private final ResumeStorageService resumeStorageService;
    private final ResumePdfService resumePdfService;
    private final DashboardService dashboardService;

    /**
     * POST /api/resume/upload
     * Upload a PDF/DOCX and parse into structured resume fields.
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> upload(@RequestParam("file") MultipartFile file, Authentication auth) {
        User user = userRepository.findById(auth.getName()).orElseThrow();
        var stored = resumeStorageService.storeResume(file);
        ResumeProfile profile = resumeProfileService.uploadAndParse(user, stored);

        try {
            dashboardService.trackUserActivity(user.getId(), "resume_upload",
                    "{\"fileName\":\"" + stored.originalFileName() + "\"}");
        } catch (Exception ignored) {}

        return ResponseEntity.ok(Map.of(
                "success", true,
                "storedFile", stored.toMap(),
                "resume", profile
        ));
    }

    /**
     * GET /api/resume/{userId}
     * Fetch resume data for a user (user can fetch own record).
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ResumeProfile> getByUser(@PathVariable String userId, Authentication auth) {
        User user = userRepository.findById(auth.getName()).orElseThrow();
        if (!user.getId().equals(userId)) {
            return ResponseEntity.status(403).build();
        }
        ResumeProfile rp = resumeProfileService.getByUserId(userId);
        return rp == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(rp);
    }

    /**
     * PUT /api/resume/update
     * Update structured resume data.
     */
    @PutMapping("/update")
    public ResponseEntity<ResumeProfile> update(@RequestBody ResumeUpdateRequest request, Authentication auth) {
        User user = userRepository.findById(auth.getName()).orElseThrow();
        ResumeProfile updated = resumeProfileService.updateFromRequest(user, request);
        try {
            dashboardService.trackUserActivity(user.getId(), "resume_update", null);
        } catch (Exception ignored) {}
        return ResponseEntity.ok(updated);
    }

    /**
     * POST /api/resume/generate-pdf
     * Generate a PDF from stored resume fields (no dummy data).
     */
    @PostMapping("/generate-pdf")
    public ResponseEntity<byte[]> generatePdf(@RequestBody Map<String, String> body, Authentication auth) {
        User user = userRepository.findById(auth.getName()).orElseThrow();
        String userId = body.getOrDefault("userId", user.getId());
        if (!user.getId().equals(userId)) {
            return ResponseEntity.status(403).build();
        }

        ResumeProfile rp = resumeProfileService.getByUserId(userId);
        if (rp == null) {
            return ResponseEntity.notFound().build();
        }
        byte[] pdf = resumePdfService.generatePdf(rp);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"resume.pdf\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}

