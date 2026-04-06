package com.advisor.controller;

import com.advisor.entity.Notification;
import com.advisor.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<?> getNotifications(Authentication auth) {
        List<Notification> notifications = notificationService.getNotificationsForUser(auth.getName());
        return ResponseEntity.ok(Map.of("success", true, "data", notifications));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(Authentication auth, @PathVariable String id) {
        notificationService.markAsRead(id, auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PutMapping("/read-all")
    public ResponseEntity<?> markAllAsRead(Authentication auth) {
        notificationService.markAllAsRead(auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }
}
