package com.advisor.repository;

import com.advisor.entity.ResumeProfile;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ResumeProfileRepository extends MongoRepository<ResumeProfile, String> {
    Optional<ResumeProfile> findByUser_Id(String userId);
    Optional<ResumeProfile> findByUserEmail(String email);
}

