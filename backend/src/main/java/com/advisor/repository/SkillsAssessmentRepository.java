package com.advisor.repository;

import com.advisor.entity.SkillsAssessment;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SkillsAssessmentRepository extends MongoRepository<SkillsAssessment, String> {
    
    List<SkillsAssessment> findByUser_IdOrderByCompletedAtDesc(String userId);
    
    Optional<SkillsAssessment> findFirstByUser_IdAndAssessmentTypeOrderByCompletedAtDesc(String userId, String assessmentType);
    
    @Query("{'user.$id': ?0, 'completedAt': {$gte: ?1}}")
    List<SkillsAssessment> findRecentAssessmentsByUserId(String userId, LocalDateTime since);
}
