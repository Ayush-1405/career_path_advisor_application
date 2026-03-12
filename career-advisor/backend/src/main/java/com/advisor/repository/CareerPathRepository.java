package com.advisor.repository;

import com.advisor.entity.CareerPath;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CareerPathRepository extends MongoRepository<CareerPath, String> {
}
