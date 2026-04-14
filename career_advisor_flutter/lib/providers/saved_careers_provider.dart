import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/token_service.dart';

final savedCareersProvider = StateNotifierProvider<SavedCareersNotifier, AsyncValue<SavedCareersData>>((ref) {
  return SavedCareersNotifier(ref);
});

class SavedCareersData {
  final List<Map<String, dynamic>> saved;
  final List<Map<String, dynamic>> applied;

  SavedCareersData({this.saved = const [], this.applied = const []});
}

class SavedCareersNotifier extends StateNotifier<AsyncValue<SavedCareersData>> {
  final Ref _ref;

  SavedCareersNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData({bool background = false}) async {
    if (!background && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }

    try {
      final token = await _ref.read(tokenServiceProvider.notifier).getUserToken();
      if (token == null) {
        state = AsyncValue.data(SavedCareersData());
        return;
      }

      final userMap = await _ref.read(tokenServiceProvider.notifier).getUser();
      String userId = userMap?['id']?.toString() ?? userMap?['userId']?.toString() ?? '';
      
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_careers_$userId');
      final appliedJson = prefs.getString('applied_careers_$userId');

      final saved = savedJson != null ? List<Map<String, dynamic>>.from(jsonDecode(savedJson)) : <Map<String, dynamic>>[];
      final applied = appliedJson != null ? List<Map<String, dynamic>>.from(jsonDecode(appliedJson)) : <Map<String, dynamic>>[];

      state = AsyncValue.data(SavedCareersData(saved: saved, applied: applied));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveCareer(Map<String, dynamic> career) async {
    if (state.valueOrNull == null) return;
    
    final current = state.value!;
    final newSaved = List<Map<String, dynamic>>.from(current.saved)..add(career);
    
    state = AsyncValue.data(SavedCareersData(saved: newSaved, applied: current.applied));
    await _persist();
  }

  Future<void> unsaveCareer(String careerId) async {
    if (state.valueOrNull == null) return;
    
    final current = state.value!;
    final newSaved = current.saved.where((c) => c['id']?.toString() != careerId).toList();
    
    state = AsyncValue.data(SavedCareersData(saved: newSaved, applied: current.applied));
    await _persist();
  }

  Future<void> applyToCareer(Map<String, dynamic> career) async {
    if (state.valueOrNull == null) return;
    
    final current = state.value!;
    final newApplied = List<Map<String, dynamic>>.from(current.applied)..add({
      ...career,
      'appliedAt': DateTime.now().toIso8601String(),
    });
    
    state = AsyncValue.data(SavedCareersData(saved: current.saved, applied: newApplied));
    await _persist();
  }

  Future<void> _persist() async {
    final data = state.valueOrNull;
    if (data == null) return;

    final token = await _ref.read(tokenServiceProvider.notifier).getUserToken();
    if (token == null) return;

    final userMap = await _ref.read(tokenServiceProvider.notifier).getUser();
    String userId = userMap?['id']?.toString() ?? userMap?['userId']?.toString() ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_careers_$userId', jsonEncode(data.saved));
    await prefs.setString('applied_careers_$userId', jsonEncode(data.applied));
  }
}
