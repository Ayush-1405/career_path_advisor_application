package com.advisor.service;

import com.advisor.entity.Connection;
import com.advisor.entity.User;
import com.advisor.repository.ConnectionRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ConnectionService {
    private final ConnectionRepository connectionRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    private String resolveUserId(String identifier) {
        if (identifier == null) return null;
        if (identifier.contains("@")) {
            return userRepository.findByEmail(identifier)
                    .map(User::getId)
                    .orElse(identifier);
        }
        return identifier;
    }

    public void followUser(String followerIdentifier, String followedIdentifier) {
        String followerId = resolveUserId(followerIdentifier);
        String followedId = resolveUserId(followedIdentifier);
        if (followerId == null || followedId == null || followerId.equals(followedId)) return;
        
        // 1. Check for ANY existing connection (SAME direction)
        Optional<Connection> myFollowing = connectionRepository.findByFollowerIdAndFollowedId(followerId, followedId);
        // 2. Check for ANY existing connection (REVERSE direction)
        Optional<Connection> theirFollowing = connectionRepository.findByFollowerIdAndFollowedId(followedId, followerId);

        if (myFollowing.isPresent() || (theirFollowing.isPresent() && theirFollowing.get().getStatus().equals("ACCEPTED"))) {
            // Disconnect Logic: Delete ALL records between these two users to ensure pure disconnect
            myFollowing.ifPresent(connectionRepository::delete);
            theirFollowing.ifPresent(connectionRepository::delete);
            return;
        }

        if (theirFollowing.isPresent()) {
            // They sent a request (PENDING) -> Accept it
            acceptRequest(followedId, followerId);
            return;
        }

        // 3. No connection exists -> Create new request
        Connection connection = new Connection();
        connection.setFollowerId(followerId);
        connection.setFollowedId(followedId);
        connection.setStatus("PENDING");
        connectionRepository.save(connection);
        
        User follower = userRepository.findById(followerId).orElse(null);
        String followerName = follower != null ? follower.getName() : "Someone";
        notificationService.createNotification(
            followedId,
            followerId,
            "FOLLOW_REQUEST",
            followerName + " sent you a connection request",
            null
        );
    }

    public void acceptRequest(String followerId, String followedIdentifier) {
        String followedId = resolveUserId(followedIdentifier);
        connectionRepository.findByFollowerIdAndFollowedId(followerId, followedId).ifPresent(conn -> {
            conn.setStatus("ACCEPTED");
            connectionRepository.save(conn);
            
            User followed = userRepository.findById(followedId).orElse(null);
            String followedName = followed != null ? followed.getName() : "Someone";
            notificationService.createNotification(
                followerId,
                followedId,
                "FOLLOW_ACCEPT",
                followedName + " accepted your connection request",
                null
            );
        });
    }

    public void rejectRequest(String followerId, String followedIdentifier) {
        String followedId = resolveUserId(followedIdentifier);
        connectionRepository.findByFollowerIdAndFollowedId(followerId, followedId).ifPresent(conn -> {
            connectionRepository.delete(conn);
        });
    }

    public List<Map<String, Object>> getInvitations(String identifier) {
        String userId = resolveUserId(identifier);
        List<Connection> incoming = connectionRepository.findByFollowedIdAndStatus(userId, "PENDING");
        return incoming.stream().map(conn -> {
            User user = userRepository.findById(conn.getFollowerId()).orElse(null);
            return enrichUser(user);
        }).filter(u -> u != null).collect(Collectors.toList());
    }

    public List<Map<String, Object>> getSentRequests(String identifier) {
        String userId = resolveUserId(identifier);
        List<Connection> outgoing = connectionRepository.findByFollowerIdAndStatus(userId, "PENDING");
        return outgoing.stream().map(conn -> {
            User user = userRepository.findById(conn.getFollowedId()).orElse(null);
            return enrichUser(user);
        }).filter(u -> u != null).collect(Collectors.toList());
    }

    public List<Map<String, Object>> getMyNetwork(String identifier) {
        String userId = resolveUserId(identifier);
        List<Connection> following = connectionRepository.findByFollowerIdAndStatus(userId, "ACCEPTED");
        List<Connection> followers = connectionRepository.findByFollowedIdAndStatus(userId, "ACCEPTED");
        
        List<Map<String, Object>> network = new ArrayList<>(following.stream().map(conn -> {
            User user = userRepository.findById(conn.getFollowedId()).orElse(null);
            return enrichUser(user);
        }).filter(u -> u != null).collect(Collectors.toList()));

        followers.stream().map(conn -> {
            User user = userRepository.findById(conn.getFollowerId()).orElse(null);
            return enrichUser(user);
        }).filter(u -> u != null && network.stream().noneMatch(n -> n.get("id").equals(u.get("id"))))
          .forEach(network::add);

        return network;
    }

    public List<Map<String, Object>> getSuggestedFriends(String identifier) {
        String userId = resolveUserId(identifier);
        List<Connection> following = connectionRepository.findByFollowerId(userId);
        List<Connection> followers = connectionRepository.findByFollowedId(userId);

        List<String> excludedIds = new ArrayList<>();
        excludedIds.add(userId);
        
        // Only exclude if status is ACCEPTED or PENDING (active/ongoing requests)
        excludedIds.addAll(following.stream()
                .filter(c -> c.getStatus().equals("ACCEPTED") || c.getStatus().equals("PENDING"))
                .map(Connection::getFollowedId)
                .collect(Collectors.toList()));
                
        excludedIds.addAll(followers.stream()
                .filter(c -> c.getStatus().equals("ACCEPTED") || c.getStatus().equals("PENDING"))
                .map(Connection::getFollowerId)
                .collect(Collectors.toList()));
        
        List<User> allUsers = userRepository.findAll();
        return allUsers.stream()
                .filter(u -> !excludedIds.contains(u.getId()))
                .map(this::enrichUser)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getSocialStats(String identifier) {
        String userId = resolveUserId(identifier);
        long followingCount = connectionRepository.findByFollowerIdAndStatus(userId, "ACCEPTED").size();
        long followersCount = connectionRepository.findByFollowedIdAndStatus(userId, "ACCEPTED").size();
        long connectionsCount = getMyNetwork(userId).size();
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("followersCount", followersCount);
        stats.put("followingCount", followingCount);
        stats.put("connectionsCount", connectionsCount);
        return stats;
    }

    private Map<String, Object> enrichUser(User user) {
        if (user == null) return null;
        Map<String, Object> map = new HashMap<>();
        map.put("id", user.getId());
        map.put("name", user.getName() != null ? user.getName() : "Unknown");
        map.put("profilePictureUrl", user.getProfilePictureUrl());
        map.put("bio", user.getBio());
        if (user.getRole() != null) {
            map.put("role", user.getRole().toString());
        }
        return map;
    }
}
