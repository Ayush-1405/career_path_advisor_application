package com.advisor.controller;

import com.advisor.entity.Post;
import com.advisor.repository.ChatRoomRepository;
import com.advisor.repository.ConnectionRepository;
import com.advisor.repository.MessageRepository;
import com.advisor.repository.PostRepository;
import com.advisor.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/social")
@RequiredArgsConstructor
public class AdminSocialController {

    private final PostService postService;
    private final PostRepository postRepository;
    private final ConnectionRepository connectionRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final MessageRepository messageRepository;

    @GetMapping("/posts")
    public ResponseEntity<?> getAllPosts() {
        // Utilizing the enriched posts from postService
        List<Map<String, Object>> posts = postService.getFeed();
        return ResponseEntity.ok(Map.of("success", true, "data", posts));
    }

    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<?> deletePost(@PathVariable String postId) {
        postRepository.deleteById(postId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Post deleted successfully"));
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getSocialStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalPosts", postRepository.count());
        stats.put("totalConnections", connectionRepository.count());
        stats.put("activeChatRooms", chatRoomRepository.count());
        stats.put("totalMessages", messageRepository.count());
        
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }
}
