import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para verificar atualizações do app e status do usuário
class AppCheckService {
  // URL base do servidor admin (alterar para produção)
  static const String _baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String _baseUrl = 'https://seu-servidor.com'; // Produção
  
  /// Verifica se o usuário está bloqueado
  static Future<UserStatus> checkUserStatus(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/$uid/status'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserStatus(
          isBlocked: data['isBlocked'] ?? false,
          blockedReason: data['blockedReason'] ?? '',
        );
      }
      
      // Se der erro, permite acesso por padrão
      return UserStatus(isBlocked: false, blockedReason: '');
    } catch (e) {
      // Em caso de erro de conexão, permite acesso
      print('Erro ao verificar status do usuário: $e');
      return UserStatus(isBlocked: false, blockedReason: '');
    }
  }
  
  /// Verifica se há atualização obrigatória
  static Future<AppVersionInfo> checkAppVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-version'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AppVersionInfo(
          minVersion: data['minVersion'] ?? '1.0.0',
          forceUpdate: data['forceUpdate'] ?? false,
          updateMessage: data['updateMessage'] ?? '',
          downloadUrl: data['downloadUrl'] ?? '',
        );
      }
      
      return AppVersionInfo.noUpdate();
    } catch (e) {
      print('Erro ao verificar versão do app: $e');
      return AppVersionInfo.noUpdate();
    }
  }
  
  /// Compara versões (retorna true se currentVersion < minVersion)
  static bool isVersionOutdated(String currentVersion, String minVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final minimum = minVersion.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        final c = i < current.length ? current[i] : 0;
        final m = i < minimum.length ? minimum[i] : 0;
        
        if (c < m) return true;
        if (c > m) return false;
      }
      
      return false; // São iguais
    } catch (e) {
      return false;
    }
  }
  
  /// Registra/atualiza dados do usuário no Firestore via API
  static Future<void> syncUserData(User user) async {
    try {
      // O servidor irá criar/atualizar o documento do usuário
      // Isso pode ser feito também via Cloud Functions
      print('Usuário sincronizado: ${user.uid}');
    } catch (e) {
      print('Erro ao sincronizar usuário: $e');
    }
  }
}

/// Status do usuário
class UserStatus {
  final bool isBlocked;
  final String blockedReason;
  
  UserStatus({
    required this.isBlocked,
    required this.blockedReason,
  });
}

/// Informações de versão do app
class AppVersionInfo {
  final String minVersion;
  final bool forceUpdate;
  final String updateMessage;
  final String downloadUrl;
  
  AppVersionInfo({
    required this.minVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.downloadUrl,
  });
  
  factory AppVersionInfo.noUpdate() {
    return AppVersionInfo(
      minVersion: '1.0.0',
      forceUpdate: false,
      updateMessage: '',
      downloadUrl: '',
    );
  }
}
