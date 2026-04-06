package com.advisor.controller;

import java.util.Map;

import com.advisor.service.OpenRouterService;
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

    @Autowired
    private OpenRouterService openRouterService;

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

        // Use OpenRouter AI for a high-quality response
        String reply = openRouterService.getChatResponse(message);

        return ResponseEntity.ok(Map.of("reply", reply));
    }
}






