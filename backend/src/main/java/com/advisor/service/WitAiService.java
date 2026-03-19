package com.advisor.service;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class WitAiService {

    @Value("${wit.ai.token:JNK2GIILYFJNSXMX4AWZE6KOFYSBLRSP}")
    private String witToken;

    @Value("${wit.ai.version:20260319}")
    private String witVersion;

    private final RestTemplate restTemplate;

    public WitAiService() {
        this.restTemplate = new RestTemplate();
    }

    public Map<String, Object> analyzeMessage(String message) {
        try {
            String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8.toString());
            String url = "https://api.wit.ai/message?v=" + witVersion + "&q=" + encodedMessage;

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + witToken);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, entity, Map.class);
            return response.getBody();
        } catch (Exception e) {
            e.printStackTrace();
            return Map.of("error", e.getMessage());
        }
    }
}
