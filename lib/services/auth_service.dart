import 'package:firebase_auth/firebase_auth.dart';

/// Serviço de autenticação Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream do estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuário atual
  User? get currentUser => _auth.currentUser;

  /// Verifica se o usuário está logado
  bool get isLoggedIn => currentUser != null;

  /// Login com email e senha
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Cadastro com email e senha
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualiza o nome do usuário se fornecido
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Tratamento de exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique o email.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido. Verifique o formato.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
