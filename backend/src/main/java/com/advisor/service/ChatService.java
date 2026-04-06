package com.advisor.service;

import com.advisor.entity.ChatRoom;
import com.advisor.entity.Message;
import com.advisor.entity.User;
import com.advisor.repository.ChatRoomRepository;
import com.advisor.repository.MessageRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {
    private final ChatRoomRepository chatRoomRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;

    public ChatRoom getOrCreateRoom(String userId1, String userId2) {
        List<ChatRoom> existing = chatRoomRepository.findByParticipantIdsContainingOrderByLastUpdateDesc(userId1);
        for (ChatRoom room : existing) {
            if (room.getParticipantIds().contains(userId2)) {
                return room;
            }
        }
        ChatRoom newRoom = new ChatRoom();
        newRoom.setParticipantIds(Arrays.asList(userId1, userId2));
        return chatRoomRepository.save(newRoom);
    }

    public Message sendMessage(String senderId, String receiverId, String content) {
        ChatRoom room = getOrCreateRoom(senderId, receiverId);
        
        Message message = new Message();
        message.setChatRoomId(room.getId());
        message.setSenderId(senderId);
        message.setContent(content);
        message = messageRepository.save(message);
        
        room.setLastMessage(content);
        room.setLastUpdate(LocalDateTime.now());
        chatRoomRepository.save(room);
        
        return message;
    }

    public List<Message> getMessages(String chatRoomId) {
        return messageRepository.findByChatRoomIdOrderByTimestampAsc(chatRoomId);
    }

    public void markAsRead(String chatRoomId, String currentUserId) {
        List<Message> unread = messageRepository.findByChatRoomIdAndSenderIdNotAndIsReadFalse(chatRoomId, currentUserId);
        if (!unread.isEmpty()) {
            for (Message m : unread) {
                m.setRead(true);
            }
            messageRepository.saveAll(unread);
        }
    }

    public List<Map<String, Object>> getMyChats(String userId) {
        List<ChatRoom> rooms = chatRoomRepository.findByParticipantIdsContainingOrderByLastUpdateDesc(userId);
        
        return rooms.stream().map(room -> {
            Map<String, Object> map = new HashMap<>();
            map.put("chatRoomId", room.getId());
            map.put("lastMessage", room.getLastMessage());
            map.put("lastUpdate", room.getLastUpdate());
            
            // Find other participant
            String otherUserId = room.getParticipantIds().stream().filter(id -> !id.equals(userId)).findFirst().orElse(null);
            if (otherUserId != null) {
                User otherUser = userRepository.findById(otherUserId).orElse(null);
                if (otherUser != null) {
                    map.put("otherUserId", otherUser.getId());
                    map.put("otherUserName", otherUser.getName());
                    map.put("otherUserAvatar", otherUser.getProfilePictureUrl());
                }
            }
            
            // Unread count
            int unread = messageRepository.countByChatRoomIdAndSenderIdNotAndIsReadFalse(room.getId(), userId);
            map.put("unreadCount", unread);
            
            return map;
        }).collect(Collectors.toList());
    }

    public void clearAllChats(String userId) {
        List<ChatRoom> rooms = chatRoomRepository.findByParticipantIdsContainingOrderByLastUpdateDesc(userId);
        for(ChatRoom room : rooms) {
            messageRepository.deleteByChatRoomId(room.getId());
            chatRoomRepository.delete(room);
        }
    }

    public void deleteChat(String roomId, String userId) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElse(null);
        if (room != null && room.getParticipantIds().contains(userId)) {
            messageRepository.deleteByChatRoomId(roomId);
            chatRoomRepository.delete(room);
        }
    }

    public void clearMessages(String roomId, String userId) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElse(null);
        if (room != null && room.getParticipantIds().contains(userId)) {
            messageRepository.deleteByChatRoomId(roomId);
            room.setLastMessage("");
            chatRoomRepository.save(room);
        }
    }
}
