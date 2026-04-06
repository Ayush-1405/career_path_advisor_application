package com.advisor.repository;

import com.advisor.entity.Connection;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import java.util.Optional;

@Repository
public interface ConnectionRepository extends MongoRepository<Connection, String> {
    List<Connection> findByFollowerId(String followerId);
    List<Connection> findByFollowedId(String followedId);
    List<Connection> findByFollowerIdAndStatus(String followerId, String status);
    List<Connection> findByFollowedIdAndStatus(String followedId, String status);
    Optional<Connection> findByFollowerIdAndFollowedId(String followerId, String followedId);
    boolean existsByFollowerIdAndFollowedId(String followerId, String followedId);
    void deleteByFollowerIdAndFollowedId(String followerId, String followedId);
}
