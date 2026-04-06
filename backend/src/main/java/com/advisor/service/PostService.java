package com.advisor.service;

import com.advisor.entity.Post;
import com.advisor.entity.User;
import com.advisor.repository.PostRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PostService {
    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public Post createPost(String userId, String content, boolean isAchievement) {
        return createPost(userId, content, isAchievement, null, null);
    }

    public Post createPost(String userId, String content, boolean isAchievement, List<String> mediaUrls, String mediaType) {
        Post post = new Post();
        post.setUserId(userId);
        post.setContent(content);
        post.setAchievement(isAchievement);
        if (mediaUrls != null && !mediaUrls.isEmpty()) {
            post.setMediaUrls(mediaUrls);
        }
        if (mediaType != null) {
            post.setMediaType(mediaType);
        }
        return postRepository.save(post);
    }

    public List<Map<String, Object>> getFeed() {
        List<Post> posts = postRepository.findAllByOrderByCreatedAtDesc();
        return posts.stream().map(this::enrichPost).collect(Collectors.toList());
    }

    public List<Map<String, Object>> getPostsByUser(String userId) {
        List<Post> posts = postRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return posts.stream().map(this::enrichPost).collect(Collectors.toList());
    }

    public Post likePost(String postId, String userId) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new RuntimeException("Post not found"));
        if (post.getLikes().contains(userId)) {
            post.getLikes().remove(userId);
        } else {
            post.getLikes().add(userId);
            User liker = resolveUser(userId);
            String likerName = liker != null ? liker.getName() : "Someone";
            notificationService.createNotification(
                post.getUserId(),
                userId,
                "LIKE",
                likerName + " liked your post",
                postId
            );
        }
        return postRepository.save(post);
    }

    public Post commentOnPost(String postId, String userId, String text) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new RuntimeException("Post not found"));
        Post.Comment comment = new Post.Comment();
        comment.setUserId(userId);
        comment.setText(text);
        post.getComments().add(comment);
        
        User commenter = resolveUser(userId);
        String commenterName = commenter != null ? commenter.getName() : "Someone";
        notificationService.createNotification(
            post.getUserId(),
            userId,
            "COMMENT",
            commenterName + " commented: " + (text.length() > 20 ? text.substring(0, 20) + "..." : text),
            postId
        );
        
        return postRepository.save(post);
    }

    public Post updatePost(String postId, String userId, String newContent) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new RuntimeException("Post not found"));
        if (!post.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized");
        }
        post.setContent(newContent);
        return postRepository.save(post);
    }

    public void deletePost(String postId, String userId) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new RuntimeException("Post not found"));
        if (!post.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized");
        }
        postRepository.delete(post);
    }

    private User resolveUser(String userIdOrEmail) {
        if (userIdOrEmail == null) return null;
        // Try by ID first
        User user = userRepository.findById(userIdOrEmail).orElse(null);
        if (user != null) return user;
        // Fallback: old posts may have stored email as userId
        return userRepository.findByEmail(userIdOrEmail).orElse(null);
    }

    public Map<String, Object> enrichPost(Post post) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", post.getId());
        map.put("content", post.getContent());
        map.put("isAchievement", post.isAchievement());
        map.put("createdAt", post.getCreatedAt());
        map.put("likesCount", post.getLikes().size());
        map.put("commentsCount", post.getComments().size());

        User user = resolveUser(post.getUserId());
        if (user != null) {
            map.put("userId", user.getId());
            map.put("userName", user.getName());
            map.put("userAvatar", user.getProfilePictureUrl());
            map.put("userBio", user.getBio());
        } else {
            map.put("userId", post.getUserId());
            map.put("userName", "Unknown User");
        }

        // Enrich comments
        List<Map<String, Object>> enrichedComments = new ArrayList<>();
        for (Post.Comment c : post.getComments()) {
            Map<String, Object> cmap = new HashMap<>();
            cmap.put("text", c.getText());
            cmap.put("createdAt", c.getCreatedAt());
            User cUser = resolveUser(c.getUserId());
            if (cUser != null) {
                cmap.put("userName", cUser.getName());
                cmap.put("userAvatar", cUser.getProfilePictureUrl());
            }
            enrichedComments.add(cmap);
        }
        map.put("comments", enrichedComments);
        
        map.put("likes", post.getLikes());

        // Media attachments
        if (post.getMediaUrls() != null && !post.getMediaUrls().isEmpty()) {
            map.put("mediaUrls", post.getMediaUrls());
        } else {
            map.put("mediaUrls", new ArrayList<>());
        }
        if (post.getMediaType() != null) {
            map.put("mediaType", post.getMediaType());
        }

        return map;
    }
}

