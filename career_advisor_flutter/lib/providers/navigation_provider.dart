import 'package:flutter_riverpod/flutter_riverpod.dart';

// Use standard StateProvider to avoid dependency on build_runner in this environment
final connectionsTabIndexProvider = StateProvider<int>((ref) => 0);
final savedCareersTabIndexProvider = StateProvider<int>((ref) => 0);
