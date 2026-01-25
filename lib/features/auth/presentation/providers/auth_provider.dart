import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_di_providers.dart';
import 'state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('🔍 [AuthNotifier] checkAuthStatus() appelé');
    final result = await _repository.getCurrentUser();

    result.fold(
      (failure) {
        debugPrint('🔍 [AuthNotifier] checkAuthStatus - Pas d\'utilisateur connecté: ${failure.message}');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      },
      (user) {
        debugPrint('🔍 [AuthNotifier] checkAuthStatus - Utilisateur trouvé: ${user.email}');
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  Future<void> login(String email, String password) async {
    debugPrint('🔐 [AuthNotifier] login() appelé avec email: $email');
    debugPrint('🔐 [AuthNotifier] État actuel: ${state.status}');
    
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    debugPrint('🔐 [AuthNotifier] État mis à loading');

    try {
      debugPrint('🔐 [AuthNotifier] Appel de repository.login()...');
      final result = await _repository.login(email: email, password: password);
      debugPrint('🔐 [AuthNotifier] Résultat reçu du repository');

      result.fold(
        (failure) {
          debugPrint('❌ [AuthNotifier] Échec login: ${failure.message}');
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        },
        (authResponse) {
          debugPrint('✅ [AuthNotifier] Login réussi pour: ${authResponse.user.email}');
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: authResponse.user,
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('💥 [AuthNotifier] Exception inattendue: $e');
      debugPrint('💥 [AuthNotifier] StackTrace: $stackTrace');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Erreur inattendue: $e',
      );
    }
  }

  Future<void> register({
    required String name,
    required String pName,
    required String email,
    required String phone,
    required String password,
    required String licenseNumber,
    required String city,
    required String address,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _repository.register(
      name: name,
      pName: pName,
      email: email,
      phone: phone,
      password: password,
      licenseNumber: licenseNumber,
      city: city,
      address: address,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (authResponse) => state = state.copyWith(
        status: AuthStatus.registered,
        user: authResponse.user,
      ),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
