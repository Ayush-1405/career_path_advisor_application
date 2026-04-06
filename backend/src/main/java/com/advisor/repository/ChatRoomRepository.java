package com.advisor.repository;

import com.advisor.entity.ChatRoom;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends MongoRepository<ChatRoom, String> {
    List<ChatRoom> findByParticipantIdsContainingOrderByLastUpdateDesc(String userId);
    
    // Find a chat room where the participantIds exactly match the given IDs
    // We can do this in custom logic or use an IN query in MongoDB
}
