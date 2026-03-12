package com.advisor.repository;

import com.advisor.entity.SystemSettings;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SystemSettingsRepository extends MongoRepository<SystemSettings, String> {
}
