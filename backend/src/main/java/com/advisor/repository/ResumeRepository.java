package com.advisor.repository;

//repository/ResumeRepository.java

import com.advisor.entity.*;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ResumeRepository extends MongoRepository<Resume, String> {
List<Resume> findByUser_Id(String userId);
List<Resume> findByUserId(String userId);
void deleteByUser_Id(String userId);
}

