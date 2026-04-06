// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'9e957e4308d419e2fc949ef6f06b0db31a6764f9';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = FutureProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = FutureProviderRef<User?>;
String _$appAuthHash() => r'e51905f463fe26c28ec61d5b21f1e047a4b4d8f0';

/// See also [AppAuth].
@ProviderFor(AppAuth)
final appAuthProvider = AsyncNotifierProvider<AppAuth, AuthStatus>.internal(
  AppAuth.new,
  name: r'appAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppAuth = AsyncNotifier<AuthStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
