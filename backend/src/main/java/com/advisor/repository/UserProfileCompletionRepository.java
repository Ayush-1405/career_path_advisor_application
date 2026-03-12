package com.advisor.repository;

import com.advisor.entity.UserProfileCompletion;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserProfileCompletionRepository extends MongoRepository<UserProfileCompletion, String> {
    
    Optional<UserProfileCompletion> findByUser_Id(String userId);
    
    @Query("{'user.$id': ?0}")
    Optional<UserProfileCompletion> findByUserId(String userId);
    
    Long countByHasResumeTrue();
    
    Long countByHasSkillsAssessmentTrue();
}
