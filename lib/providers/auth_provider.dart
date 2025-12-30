import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Estados de autenticação
enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

/// Provider de autenticação
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;

  AuthProvider() {
    _init();
  }

  /// Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Inicializa o listener de autenticação
  void _init() {
    _authService.authStateChanges.listen((user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        _status = AuthStatus.authenticated;
        _user = user;
      }
      notifyListeners();
    });
  }

  /// Login com email e senha
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Cadastro com email e senha
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Recuperação de senha
  Future<bool> resetPassword(String email) async {
    try {
      _error = null;
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Limpa o erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
