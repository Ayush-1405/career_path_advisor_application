package com.advisor.repository;

import com.advisor.entity.UserCareerPath;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserCareerPathRepository extends MongoRepository<UserCareerPath, String> {
    List<UserCareerPath> findByUser_Id(String userId);
    List<UserCareerPath> findByUserId(String userId); // Keep for compatibility if needed
    Optional<UserCareerPath> findByUser_IdAndCareerPath_Id(String userId, String careerPathId);
    List<UserCareerPath> findAllByOrderByAppliedAtDesc();
}
