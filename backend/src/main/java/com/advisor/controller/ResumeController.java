package com.advisor.controller;

import com.advisor.entity.*;
import com.advisor.repository.*;
import com.advisor.service.ResumeAnalysisService;
import com.advisor.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/resumes")
@RequiredArgsConstructor
public class ResumeController {

  private final ResumeRepository resumeRepository;
  private final UserRepository userRepository;
  private final ResumeAnalysisService analysisService;
  private final DashboardService dashboardService;

  @PostMapping
  public ResumeAnalysis add(@RequestBody Resume resume, Authentication auth) {
    User u = userRepository.findById(auth.getName()).orElseThrow();
    resume.setUser(u);
    ResumeAnalysis analysis = analysisService.analyzeAndSave(resume, u);
    
    // Track resume upload activity
    dashboardService.trackUserActivity(u.getId(), "resume_upload", 
        "{\"resumeId\":\"" + resume.getId() + "\",\"analysisId\":\"" + analysis.getId() + "\"}");
    
    return analysis;
  }

  @GetMapping("/me")
  public List<Resume> myResumes(Authentication auth) {
    User u = userRepository.findById(auth.getName()).orElseThrow();
    return resumeRepository.findByUser_Id(u.getId());
  }

  @GetMapping("/{id}/analysis")
  public ResumeAnalysis getAnalysis(@PathVariable String id, Authentication auth) {
    User u = userRepository.findById(auth.getName()).orElseThrow();
    Resume r = resumeRepository.findById(id).orElseThrow(() -> new RuntimeException("Resume not found"));
    if (!r.getUser().getId().equals(u.getId())) {
      throw new RuntimeException("Unauthorized");
    }
    return analysisService.getAnalysisByResumeId(id);
  }

  @DeleteMapping("/{id}")
  public void delete(@PathVariable String id, Authentication auth) {
    User u = userRepository.findById(auth.getName()).orElseThrow();
    Resume r = resumeRepository.findById(id).orElseThrow(() -> new RuntimeException("Resume not found"));
    if (!r.getUser().getId().equals(u.getId())) {
      throw new RuntimeException("Unauthorized");
    }
    resumeRepository.delete(r);
  }
}