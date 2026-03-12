package com.advisor.controller;

import com.advisor.entity.ResumeAnalysis;
import com.advisor.entity.User;
import com.advisor.repository.ResumeAnalysisRepository;
import com.advisor.repository.UserRepository;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {

  private final UserRepository userRepository;
  private final ResumeAnalysisRepository analysisRepository;

  @PostMapping(value = "/generate", produces = MediaType.APPLICATION_JSON_VALUE)
  public Map<String, Object> generateJson(@RequestBody ReportRequest request, Authentication auth) {
    User u = userRepository.findByEmail(auth.getName()).orElseThrow();
    List<ResumeAnalysis> list = analysisRepository.findByUserId(u.getId());
    ResumeAnalysis latest = list.isEmpty() ? null : list.get(list.size() - 1);

    String name = request.getName() != null ? request.getName() : u.getName();
    int score = latest != null ? latest.getOverallScore() : 75;
    List<String> strengths = latest != null && latest.getStrengths() != null
        ? Arrays.asList(latest.getStrengths().split(","))
        : List.of("Problem Solving", "Communication", "Teamwork");
    List<String> improvements = latest != null && latest.getImprovements() != null
        ? Arrays.asList(latest.getImprovements().split(","))
        : List.of("Leadership", "Cloud", "System design");

    return Map.of(
        "userInfo", Map.of(
            "name", name,
            "email", u.getEmail(),
            "date", LocalDate.now().toString(),
            "role", request.getRole() == null ? "Career Report" : request.getRole()
        ),
        "summary", Map.of(
            "overallScore", score,
            "strengths", strengths,
            "improvements", improvements
        )
    );
  }

  @PostMapping(value = "/pdf", produces = MediaType.APPLICATION_OCTET_STREAM_VALUE)
  public ResponseEntity<byte[]> generatePdf(@RequestBody ReportRequest request, Authentication auth) {
    User u = userRepository.findByEmail(auth.getName()).orElseThrow();
    List<ResumeAnalysis> list = analysisRepository.findByUserId(u.getId());
    ResumeAnalysis latest = list.isEmpty() ? null : list.get(list.size() - 1);

    String name = request.getName() != null ? request.getName() : u.getName();
    String role = request.getRole() == null ? "Career Report" : request.getRole();
    int score = latest != null ? latest.getOverallScore() : 75;
    String content = "CAREER DEVELOPMENT REPORT\n\n" +
        "Generated for: " + name + "\n" +
        "Date: " + LocalDate.now() + "\n" +
        "Target Role: " + role + "\n\n" +
        "EXECUTIVE SUMMARY\n" +
        "Overall Career Readiness Score: " + score + "%\n";

    byte[] bytes = content.getBytes(StandardCharsets.UTF_8);
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=Career_Report.txt")
        .contentType(MediaType.APPLICATION_OCTET_STREAM)
        .body(bytes);
  }

  @Data
  public static class ReportRequest {
    @NotBlank(message = "role is required")
    private String role;
    private String name;
  }
}


