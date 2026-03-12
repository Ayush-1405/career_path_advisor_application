package com.advisor.repository;

import com.advisor.entity.UserSavedCareerPath;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserSavedCareerPathRepository extends MongoRepository<UserSavedCareerPath, String> {
  List<UserSavedCareerPath> findByUser_Id(String userId);
  boolean existsByUser_IdAndCareerPath_Id(String userId, String careerPathId);
  void deleteByUser_IdAndCareerPath_Id(String userId, String careerPathId);
}
