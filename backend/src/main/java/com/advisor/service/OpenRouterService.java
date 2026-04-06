package com.advisor.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class OpenRouterService {

    @Value("${openrouter.api.key}")
    private String apiKey;

    @Value("${openrouter.api.url}")
    private String apiUrl;

    @Value("${openrouter.model}")
    private String modelName;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public String getChatResponse(String userMessage) {
        try {
            ObjectNode root = objectMapper.createObjectNode();
            root.put("model", modelName);

            ArrayNode messages = root.putArray("messages");
            
            ObjectNode systemMsg = messages.addObject();
            systemMsg.put("role", "system");
            systemMsg.put("content", "You are an expert Career Advisor AI. Help users with career paths, resume tips, and interview preparation. Be professional, supportive, and concise.");

            ObjectNode userMsgNode = messages.addObject();
            userMsgNode.put("role", "user");
            userMsgNode.put("content", userMessage);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);
            headers.set("HTTP-Referer", "https://careerpathadvisor.com"); // Required by OpenRouter

            HttpEntity<String> entity = new HttpEntity<>(root.toString(), headers);
            String response = restTemplate.postForObject(apiUrl, entity, String.class);

            JsonNode responseJson = objectMapper.readTree(response);
            return responseJson.path("choices").get(0).path("message").path("content").asText();

        } catch (Exception e) {
            log.error("Error communicating with OpenRouter", e);
            return "I apologize, but I'm having trouble connecting to my brain right now. Please try again later.";
        }
    }

    public Map<String, Object> analyzeResume(String resumeText) {
        try {
            ObjectNode root = objectMapper.createObjectNode();
            root.put("model", modelName);

            ArrayNode messages = root.putArray("messages");
            
            ObjectNode systemMsg = messages.addObject();
            systemMsg.put("role", "system");
            systemMsg.put("content", "You are an expert Resume Reviewer. Analyze the provided resume text and provide a structured review in JSON format. The response must be a single JSON object with the following keys: 'score' (number 0-100), 'strengths' (string, comma-separated list), 'improvements' (string, comma-separated list), 'feedback' (string, professional summary), and 'careerPath' (string, a recommended step-by-step career roadmap based on skills). Do not include any text outside the JSON.");

            ObjectNode userMsgNode = messages.addObject();
            userMsgNode.put("role", "user");
            userMsgNode.put("content", "Analyze this resume text:\n\n" + resumeText);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);
            headers.set("HTTP-Referer", "https://careerpathadvisor.com");

            HttpEntity<String> entity = new HttpEntity<>(root.toString(), headers);
            String response = restTemplate.postForObject(apiUrl, entity, String.class);

            JsonNode responseJson = objectMapper.readTree(response);
            String content = responseJson.path("choices").get(0).path("message").path("content").asText();

            // Handle potential Markdown formatting in AI response
            if (content.contains("```") && content.contains("json")) {
                content = content.substring(content.indexOf("{"), content.lastIndexOf("}") + 1);
            }

            return objectMapper.readValue(content, Map.class);

        } catch (Exception e) {
            log.error("Error analyzing resume with AI", e);
            return Map.of(
                "score", 50,
                "strengths", "Error in AI analysis",
                "improvements", "Try again later",
                "feedback", "Communication with AI failed: " + e.getMessage()
            );
        }
    }
}
