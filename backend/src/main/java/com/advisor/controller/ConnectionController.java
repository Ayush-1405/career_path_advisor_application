package com.advisor.controller;

import com.advisor.service.ConnectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/connections")
@RequiredArgsConstructor
public class ConnectionController {
    private final ConnectionService connectionService;

    @GetMapping("/network")
    public ResponseEntity<?> getMyNetwork(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getMyNetwork(auth.getName())));
    }

    @GetMapping("/suggestions")
    public ResponseEntity<?> getSuggestedFriends(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getSuggestedFriends(auth.getName())));
    }

    @PostMapping("/follow/{userId}")
    public ResponseEntity<?> followUser(Authentication auth, @PathVariable String userId) {
        connectionService.followUser(auth.getName(), userId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Follow status toggled"));
    }

    @GetMapping("/invitations")
    public ResponseEntity<?> getInvitations(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getInvitations(auth.getName())));
    }

    @GetMapping("/sent")
    public ResponseEntity<?> getSentRequests(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getSentRequests(auth.getName())));
    }

    @PostMapping("/accept/{userId}")
    public ResponseEntity<?> acceptRequest(Authentication auth, @PathVariable String userId) {
        connectionService.acceptRequest(userId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true, "message", "Request accepted"));
    }

    @PostMapping("/reject/{userId}")
    public ResponseEntity<?> rejectRequest(Authentication auth, @PathVariable String userId) {
        connectionService.rejectRequest(userId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true, "message", "Request rejected"));
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getMySocialStats(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getSocialStats(auth.getName())));
    }

    @GetMapping("/stats/{userId}")
    public ResponseEntity<?> getUserSocialStats(@PathVariable String userId) {
        return ResponseEntity.ok(Map.of("success", true, "data", connectionService.getSocialStats(userId)));
    }
}
