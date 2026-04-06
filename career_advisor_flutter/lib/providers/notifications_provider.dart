import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsNotifier(ref.read(apiServiceProvider));
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final ApiService _apiService;

  NotificationsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool background = false}) async {
    if (!background) state = const AsyncValue.loading();
    try {
      final response = await _apiService.fetchNotifications();
      if (response is Map && response.containsKey('data') && response['data'] is List) {
        final List list = response['data'];
        final notifications = list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(notifications);
      } else if (response is List) {
        final notifications = response.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(notifications);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!background) state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiService.markNotificationAsRead(id);
      // Optimistically update
      if (state is AsyncData) {
        final List<AppNotification> current = List.from(state.value!);
        final idx = current.indexWhere((n) => n.id == id);
        if (idx != -1) {
          final old = current[idx];
          current[idx] = AppNotification(
            id: old.id,
            recipientId: old.recipientId,
            senderId: old.senderId,
            senderName: old.senderName,
            senderAvatarUrl: old.senderAvatarUrl,
            type: old.type,
            message: old.message,
            relatedEntityId: old.relatedEntityId,
            isRead: true,
            createdAt: old.createdAt,
          );
          state = AsyncValue.data(current);
        }
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      // Optimistically update
      if (state is AsyncData) {
        final List<AppNotification> current = state.value!.map((old) {
          return AppNotification(
            id: old.id,
            recipientId: old.recipientId,
            senderId: old.senderId,
            senderName: old.senderName,
            senderAvatarUrl: old.senderAvatarUrl,
            type: old.type,
            message: old.message,
            relatedEntityId: old.relatedEntityId,
            isRead: true,
            createdAt: old.createdAt,
          );
        }).toList();
        state = AsyncValue.data(current);
      }
    } catch (_) {}
  }
}
