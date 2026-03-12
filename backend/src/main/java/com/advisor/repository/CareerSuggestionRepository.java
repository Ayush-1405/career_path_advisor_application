package com.advisor.repository;

import com.advisor.entity.CareerSuggestion;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CareerSuggestionRepository extends MongoRepository<CareerSuggestion, String> {
    
    List<CareerSuggestion> findByUser_IdOrderBySuggestedAtDesc(String userId);
    
    List<CareerSuggestion> findByUser_IdAndIsViewedOrderBySuggestedAtDesc(String userId, Boolean isViewed);
    
    @Query("{'user.$id': ?0, 'suggestedAt': {$gte: ?1}}")
    List<CareerSuggestion> findRecentSuggestionsByUserId(String userId, LocalDateTime since);
    
    Long countByIsViewedFalse();
    
    Long countByUser_IdAndIsViewedFalse(String userId);
    
    @Query("{'user.$id': ?0, 'isViewed': false}")
    List<CareerSuggestion> findUnviewedSuggestionsByUserId(String userId);
}
