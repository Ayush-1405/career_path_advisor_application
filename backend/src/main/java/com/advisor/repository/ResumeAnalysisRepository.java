package com.advisor.repository;

import com.advisor.entity.ResumeAnalysis;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ResumeAnalysisRepository extends MongoRepository<ResumeAnalysis, String> {
  List<ResumeAnalysis> findByUser_Id(String userId);
  List<ResumeAnalysis> findByUserId(String userId);
  void deleteByUser_Id(String userId);
  List<ResumeAnalysis> findByResume_Id(String resumeId);
  List<ResumeAnalysis> findByResumeId(String resumeId);

  @org.springframework.data.mongodb.repository.Query(value = "{}", fields = "{ 'overallScore' : 1 }")
  List<ResumeAnalysis> findAllScoresOnly();
}



