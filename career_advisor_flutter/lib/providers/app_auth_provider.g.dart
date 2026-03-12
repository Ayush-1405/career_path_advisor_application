part of 'app_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appAuthHash() => r'29547631d52a46e86138bb7cb140cf1c35717d43';

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
