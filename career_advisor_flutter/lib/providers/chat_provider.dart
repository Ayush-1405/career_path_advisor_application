import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

final myChatsProvider = StateNotifierProvider<MyChatsNotifier, AsyncValue<List<ChatRoom>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MyChatsNotifier(apiService);
});

class MyChatsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final ApiService _apiService;

  MyChatsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchChats();
  }

  Future<void> fetchChats({bool background = false}) async {
    if (!background) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiService.fetchMyChats();
      if (response is List) {
        final chats = response.map((e) => ChatRoom.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(chats);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!background) {
        state = AsyncValue.error(e, st);
      } else if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }
  Future<void> markAllAsRead() async {
    final currentChats = state.valueOrNull;
    if (currentChats == null || currentChats.isEmpty) return;

    try {
      final updatedChats = currentChats.map((room) => room.copyWith(unreadCount: 0)).toList();
      state = AsyncValue.data(updatedChats);

      final roomsWithUnread = currentChats.where((r) => (r.unreadCount ?? 0) > 0);
      await Future.wait(roomsWithUnread.map((room) => _apiService.markMessagesAsRead(room.id)));
      await fetchChats(background: true);
    } catch (e) {
      state = AsyncValue.data(currentChats);
      rethrow;
    }
  }

  Future<void> deleteChat(String roomId) async {
    final currentChats = state.valueOrNull ?? [];
    // Optimistic removal
    state = AsyncValue.data(currentChats.where((r) => r.chatRoomId != roomId).toList());
    try {
      await _apiService.deleteChat(roomId);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentChats);
      rethrow;
    }
  }

  Future<void> clearAllChats() async {
    final currentChats = state.valueOrNull ?? [];
    // Optimistic clear
    state = const AsyncValue.data([]);
    try {
      await _apiService.clearAllChats();
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentChats);
      rethrow;
    }
  }
}

// AutoDispose since multiple chat rooms can be opened
final chatMessagesProvider = StateNotifierProvider.family.autoDispose<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, roomId) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatMessagesNotifier(apiService, roomId);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ApiService _apiService;
  final String roomId;

  ChatMessagesNotifier(this._apiService, this.roomId) : super(const AsyncValue.loading()) {
    fetchMessages();
  }

  Future<void> fetchMessages({bool background = false}) async {
    if (!background) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiService.fetchMessages(roomId);
      if (response is List) {
        final msgs = response.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(msgs);
        _apiService.markMessagesAsRead(roomId).catchError((_) {});
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!background) {
        state = AsyncValue.error(e, st);
      } else if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      // Optimistic update could be added here, but backend fetch is reliable enough 
      // if we just await api call then fetchMessages background
      await _apiService.sendMessage(receiverId, content);
      await fetchMessages(background: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearMessages() async {
    final currentMsgs = state.valueOrNull ?? [];
    // Optimistic clear
    state = const AsyncValue.data([]);
    try {
      await _apiService.clearMessages(roomId);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentMsgs);
      rethrow;
    }
  }
}

final onlineStatusProvider = StreamProvider.family.autoDispose<bool, String>((ref, userId) async* {
  final apiService = ref.watch(apiServiceProvider);
  final initialStatus = await apiService.getUserStatus(userId);
  yield initialStatus?['isOnline'] == true;
  
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    final status = await apiService.getUserStatus(userId);
    yield status?['isOnline'] == true;
  }
});

