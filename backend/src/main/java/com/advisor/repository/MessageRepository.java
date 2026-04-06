package com.advisor.repository;

import com.advisor.entity.Message;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends MongoRepository<Message, String> {
    List<Message> findByChatRoomIdOrderByTimestampAsc(String chatRoomId);
    int countByChatRoomIdAndSenderIdNotAndIsReadFalse(String chatRoomId, String currentUserId);
    List<Message> findByChatRoomIdAndSenderIdNotAndIsReadFalse(String chatRoomId, String currentUserId);
    void deleteByChatRoomId(String chatRoomId);
}
