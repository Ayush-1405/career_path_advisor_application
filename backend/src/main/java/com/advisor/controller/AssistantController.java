package com.advisor.controller;

import java.util.Map;
import java.util.List;

import com.advisor.service.SystemSettingsService;
import com.advisor.service.WitAiService;
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

    @Autowired
    private WitAiService witAiService;

    @PostMapping("/chat")
    public ResponseEntity<Map<String, String>> chat(@RequestBody Map<String, String> body, Authentication auth) {
        if (!systemSettingsService.getSettings().getAiAssistantEnabled()) {
            return ResponseEntity.badRequest().body(Map.of("error", "AI Assistant is currently disabled by administrator."));
        }

        String message = body.getOrDefault("message", "").trim();
        String name = auth != null ? auth.getName() : "there";
        
        if (message.isEmpty()) {
            return ResponseEntity.ok(Map.of("reply", "Hi " + name + ", ask me anything about your career."));
        }

        // Call Wit.ai API for intent/entity extraction
        Map<String, Object> witAnalysis = witAiService.analyzeMessage(message);
        
        // Basic fallback reply
        String reply = "Thanks, " + name + ". I'm analyzing your request. " +
                       "Here's a general tip: tailor your resume to each role and align skills with the job description.";

        // Attempt to extract top intent from Wit.ai response
        try {
            if (witAnalysis != null && witAnalysis.containsKey("intents")) {
                List<Map<String, Object>> intents = (List<Map<String, Object>>) witAnalysis.get("intents");
                if (!intents.isEmpty()) {
                    String intentName = (String) intents.get(0).get("name");
                    // Very simple intent mapping example
                    if ("greeting".equalsIgnoreCase(intentName)) {
                        reply = "Hello " + name + "! How can I help you with your career today?";
                    } else if ("resume_help".equalsIgnoreCase(intentName) || "improve_resume".equalsIgnoreCase(intentName)) {
                        reply = "To improve your resume, focus on action verbs, quantify your achievements, and tailor it specifically to the job description.";
                    } else if ("interview_prep".equalsIgnoreCase(intentName)) {
                        reply = "For interview prep, practice the STAR method (Situation, Task, Action, Result) for behavioral questions.";
                    } else {
                        reply = "I see giving career advice for '" + intentName + "'. Make sure to stay proactive in your learning!";
                    }
                }
            }
        } catch (Exception e) {
            // Ignore parsing errors and fallback securely
        }

        return ResponseEntity.ok(Map.of("reply", reply));
    }
}






