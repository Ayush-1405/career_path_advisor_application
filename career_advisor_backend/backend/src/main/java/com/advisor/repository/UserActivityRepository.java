package com.advisor.repository;

import com.advisor.entity.UserActivity;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface UserActivityRepository extends MongoRepository<UserActivity, String> {
    
    List<UserActivity> findByUser_IdOrderByCreatedAtDesc(String userId);
    
    List<UserActivity> findByUser_IdAndActivityTypeOrderByCreatedAtDesc(String userId, String activityType);
    
    @Query("{'user.$id': ?0, 'createdAt': {$gte: ?1}}")
    List<UserActivity> findRecentActivitiesByUserId(String userId, LocalDateTime since);
    
    @Query(value = "{'user.$id': ?0}", sort = "{ 'createdAt': -1 }")
    List<UserActivity> findByUserIdOrderByCreatedAtDesc(String userId);
    
    Long countByActivityTypeAndCreatedAtAfter(String activityType, LocalDateTime since);

    List<UserActivity> findByCreatedAtAfterOrderByCreatedAtDesc(LocalDateTime oneDayAgo);

    List<UserActivity> findAllByOrderByCreatedAtDesc();
}
