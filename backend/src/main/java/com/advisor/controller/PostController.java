package com.advisor.controller;

import com.advisor.entity.Post;
import com.advisor.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/feed")
@RequiredArgsConstructor
public class PostController {
    private final PostService postService;

    @GetMapping
    public ResponseEntity<?> getFeed() {
        return ResponseEntity.ok(Map.of("success", true, "data", postService.getFeed()));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getPostsByUser(@PathVariable String userId) {
        return ResponseEntity.ok(Map.of("success", true, "data", postService.getPostsByUser(userId)));
    }

    @GetMapping("/my-posts")
    public ResponseEntity<?> getMyPosts(Authentication auth) {
        return ResponseEntity.ok(Map.of("success", true, "data", postService.getPostsByUser(auth.getName())));
    }

    @PostMapping
    public ResponseEntity<?> createPost(Authentication auth, @RequestBody Map<String, Object> payload) {
        String content = (String) payload.get("content");
        boolean isAchievement = payload.containsKey("isAchievement") ? (Boolean) payload.get("isAchievement") : false;
        @SuppressWarnings("unchecked")
        List<String> mediaUrls = payload.containsKey("mediaUrls") ? (List<String>) payload.get("mediaUrls") : null;
        String mediaType = payload.containsKey("mediaType") ? (String) payload.get("mediaType") : null;
        Post post = postService.createPost(auth.getName(), content, isAchievement, mediaUrls, mediaType);
        return ResponseEntity.ok(Map.of("success", true, "data", postService.enrichPost(post)));
    }

    @PutMapping("/{postId}")
    public ResponseEntity<?> updatePost(Authentication auth, @PathVariable String postId, @RequestBody Map<String, String> payload) {
        try {
            Post post = postService.updatePost(postId, auth.getName(), payload.get("content"));
            return ResponseEntity.ok(Map.of("success", true, "data", post));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    @DeleteMapping("/{postId}")
    public ResponseEntity<?> deletePost(Authentication auth, @PathVariable String postId) {
        try {
            postService.deletePost(postId, auth.getName());
            return ResponseEntity.ok(Map.of("success", true, "message", "Post deleted"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    @PostMapping("/{postId}/like")
    public ResponseEntity<?> likePost(Authentication auth, @PathVariable String postId) {
        Post post = postService.likePost(postId, auth.getName());
        return ResponseEntity.ok(Map.of("success", true, "data", post));
    }

    @PostMapping("/{postId}/comment")
    public ResponseEntity<?> commentOnPost(Authentication auth, @PathVariable String postId, @RequestBody Map<String, String> payload) {
        Post post = postService.commentOnPost(postId, auth.getName(), payload.get("text"));
        return ResponseEntity.ok(Map.of("success", true, "data", post));
    }
}

