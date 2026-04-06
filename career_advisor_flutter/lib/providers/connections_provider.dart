import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../services/api_service.dart';

final connectionsProvider = StateNotifierProvider<ConnectionsNotifier, AsyncValue<ConnectionsState>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConnectionsNotifier(apiService);
});

class ConnectionsState {
  final List<ConnectionUser> network;
  final List<ConnectionUser> suggested;
  final List<ConnectionUser> invitations;
  final List<ConnectionUser> sentRequests;

  ConnectionsState({
    this.network = const [],
    this.suggested = const [],
    this.invitations = const [],
    this.sentRequests = const [],
  });

  ConnectionsState copyWith({
    List<ConnectionUser>? network,
    List<ConnectionUser>? suggested,
    List<ConnectionUser>? invitations,
    List<ConnectionUser>? sentRequests,
  }) {
    return ConnectionsState(
      network: network ?? this.network,
      suggested: suggested ?? this.suggested,
      invitations: invitations ?? this.invitations,
      sentRequests: sentRequests ?? this.sentRequests,
    );
  }
}

class ConnectionsNotifier extends StateNotifier<AsyncValue<ConnectionsState>> {
  final ApiService _apiService;

  ConnectionsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchData();
  }

  Future<void> fetchData({bool background = false}) async {
    if (!background) {
      state = const AsyncValue.loading();
    }
    try {
      dynamic networkRes;
      try {
        networkRes = await _apiService.fetchMyNetwork();
      } catch (e) {
        print('Error fetching network: $e');
        rethrow;
      }

      dynamic suggestedRes;
      try {
        suggestedRes = await _apiService.fetchSuggestedFriends();
      } catch (e) {
        print('Error fetching suggested: $e');
        rethrow;
      }

      dynamic invitationsRes;
      try {
        invitationsRes = await _apiService.fetchInvitations();
      } catch (e) {
        print('Error fetching invitations: $e');
        rethrow;
      }

      dynamic sentRes;
      try {
        sentRes = await _apiService.fetchSentRequests();
        print('Sent requests result: $sentRes');
      } catch (e) {
        print('Error fetching sent requests: $e');
        sentRes = [];
      }

      List<ConnectionUser> network = [];
      List<ConnectionUser> suggested = [];
      List<ConnectionUser> invitations = [];
      List<ConnectionUser> sentRequests = [];

      if (networkRes is List) {
        network = networkRes.map((e) => ConnectionUser.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (suggestedRes is List) {
        suggested = suggestedRes.map((e) => ConnectionUser.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (invitationsRes is List) {
        invitations = invitationsRes.map((e) => ConnectionUser.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (sentRes is List) {
        sentRequests = sentRes.map((e) => ConnectionUser.fromJson(e as Map<String, dynamic>)).toList();
      }

      state = AsyncValue.data(ConnectionsState(
        network: network,
        suggested: suggested,
        invitations: invitations,
        sentRequests: sentRequests,
      ));
    } catch (e, st) {
      print('Overall connections error: $e');
      if (!background) {
        state = AsyncValue.error(e, st);
      } else if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> followUser(String userId) async {
    // Optimistic Update: Move from suggested to sentRequests (as requested/pending)
    if (state.value != null) {
      final currentState = state.value!;
      final usersToMove = currentState.suggested.where((u) => u.id == userId).toList();
      final newSuggested = currentState.suggested.where((u) => u.id != userId).toList();
      final newSentRequests = List<ConnectionUser>.from(currentState.sentRequests)..addAll(usersToMove);
      
      // If user navigated from somewhere else (not in suggested), we create a mock pending entry 
      if (usersToMove.isEmpty && !newSentRequests.any((u) => u.id == userId)) {
        newSentRequests.add(ConnectionUser(id: userId, name: 'Pending User')); 
        // Real data fetch will overwrite this mock entry shortly
      }
      
      state = AsyncValue.data(currentState.copyWith(suggested: newSuggested, sentRequests: newSentRequests));
    }

    try {
      await _apiService.followUser(userId);
      await fetchData(background: true);
    } catch (e) {
      await fetchData(background: true);
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId) async {
    // Optimistic Update: Remove from network and move back to suggested
    if (state.value != null) {
      final currentState = state.value!;
      
      // Find the user in network, invitations, or sentRequests to move them back to suggested
      final inNetwork = currentState.network.where((u) => u.id == userId).toList();
      final inSent = currentState.sentRequests.where((u) => u.id == userId).toList();
      final inInvitations = currentState.invitations.where((u) => u.id == userId).toList();
      
      final userToMove = [...inNetwork, ...inSent, ...inInvitations].firstOrNull;
      
      final newNetwork = currentState.network.where((u) => u.id != userId).toList();
      final newSent = currentState.sentRequests.where((u) => u.id != userId).toList();
      final newInvitations = currentState.invitations.where((u) => u.id != userId).toList();
      
      List<ConnectionUser> newSuggested = List<ConnectionUser>.from(currentState.suggested);
      if (userToMove != null && !newSuggested.any((u) => u.id == userId)) {
        newSuggested.add(userToMove);
      }
      
      state = AsyncValue.data(currentState.copyWith(
        network: newNetwork,
        suggested: newSuggested,
        sentRequests: newSent,
        invitations: newInvitations,
      ));
    }

    try {
      await _apiService.followUser(userId); // Toggle-based backend
      // Artificial delay to allow DB to settle
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchData(background: true);
    } catch (e) {
      await fetchData(background: true);
      rethrow;
    }
  }

  Future<void> acceptInvitation(String userId) async {
    try {
      await _apiService.acceptRequest(userId);
      await fetchData(background: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectInvitation(String userId) async {
    try {
      await _apiService.rejectRequest(userId);
      await fetchData(background: true);
    } catch (e) {
      rethrow;
    }
  }
}
