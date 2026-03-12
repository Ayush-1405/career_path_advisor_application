package com.advisor.controller;

import java.util.Map;

import com.advisor.service.SystemSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/assistant")
public class AssistantController {

    @Autowired
    private SystemSettingsService systemSettingsService;

    @PostMapping("/chat")
    public ResponseEntity<Map<String, String>> chat(@RequestBody Map<String, String> body, Authentication auth) {
        if (!systemSettingsService.getSettings().getAiAssistantEnabled()) {
            return ResponseEntity.badRequest().body(Map.of("error", "AI Assistant is currently disabled by administrator."));
        }

        String message = body.getOrDefault("message", "").trim();
        String name = auth != null ? auth.getName() : "there";
        String reply = message.isEmpty()
            ? "Hi " + name + ", ask me anything about your career."
            : "Thanks, " + name + ". Here's a helpful tip: tailor your resume to each role, highlight measurable impact, and align skills with the job description.";
        return ResponseEntity.ok(Map.of("reply", reply));
    }
}






