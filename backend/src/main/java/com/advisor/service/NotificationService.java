package com.advisor.service;

import com.advisor.entity.Notification;
import com.advisor.entity.User;
import com.advisor.repository.NotificationRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public void createNotification(String recipientId, String senderId, String type, String message, String relatedEntityId) {
        if (recipientId == null || recipientId.equals(senderId)) return; // Don't notify self

        User sender = userRepository.findById(senderId).orElse(null);
        String senderName = sender != null ? sender.getName() : "Someone";
        String senderAvatarUrl = sender != null ? sender.getProfilePictureUrl() : null;

        Notification notification = new Notification();
        notification.setRecipientId(recipientId);
        notification.setSenderId(senderId);
        notification.setSenderName(senderName);
        notification.setSenderAvatarUrl(senderAvatarUrl);
        notification.setType(type);
        notification.setMessage(message);
        notification.setRelatedEntityId(relatedEntityId);
        
        notificationRepository.save(notification);
    }

    public List<Notification> getNotificationsForUser(String userId) {
        return notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId);
    }

    public void markAsRead(String notificationId, String userId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            if (n.getRecipientId().equals(userId)) {
                n.setRead(true);
                notificationRepository.save(n);
            }
        });
    }

    public void markAllAsRead(String userId) {
        List<Notification> unread = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId)
                .stream().filter(n -> !n.isRead()).toList();
        unread.forEach(n -> n.setRead(true));
        if (!unread.isEmpty()) {
            notificationRepository.saveAll(unread);
        }
    }
}
