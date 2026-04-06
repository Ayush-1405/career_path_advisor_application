package com.advisor.controller;

import com.advisor.entity.ChatRoom;
import com.advisor.entity.Message;
import com.advisor.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/chats")
@RequiredArgsConstructor
public class ChatController {
    private final ChatService chatService;

    @GetMapping
    public ResponseEntity<?> getMyChats(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", chatService.getMyChats(auth.getName())));
    }

    @GetMapping("/room/{otherUserId}")
    public ResponseEntity<?> getOrCreateRoom(Authentication auth, @PathVariable String otherUserId) {
        ChatRoom room = chatService.getOrCreateRoom(auth.getName(), otherUserId);
        return ResponseEntity.ok(Map.of("success", true, "chatRoomId", room.getId()));
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<?> getMessages(@PathVariable String roomId) {
        return ResponseEntity.ok(Map.of("success", true, "data", chatService.getMessages(roomId)));
    }

    @PostMapping("/send/{receiverId}")
    public ResponseEntity<?> sendMessage(Authentication auth, @PathVariable String receiverId,
            @RequestBody Map<String, String> payload) {
        Message message = chatService.sendMessage(auth.getName(), receiverId, payload.get("content"));
        return ResponseEntity.ok(Map.of("success", true, "data", message));
    }

    @PutMapping("/{roomId}/read")
    public ResponseEntity<?> markAsRead(Authentication auth, @PathVariable String roomId) {
        chatService.markAsRead(roomId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @DeleteMapping("/{roomId}")
    public ResponseEntity<?> deleteChat(Authentication auth, @PathVariable String roomId) {
        chatService.deleteChat(roomId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @DeleteMapping("/{roomId}/messages")
    public ResponseEntity<?> clearMessages(Authentication auth, @PathVariable String roomId) {
        chatService.clearMessages(roomId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @DeleteMapping("/all")
    public ResponseEntity<?> clearAllChats(Authentication auth) {
        chatService.clearAllChats(auth.getName());
        return ResponseEntity.ok(Map.of("success", true));
    }
}
