import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para sincronização de conteúdo (canais, filmes, séries)
/// Busca a lista M3U do servidor e mantém cache local
class ContentSyncService {
  // URL base do servidor (mesmo do app_check_service)
  static const String _baseUrl = 'https://cineflowapp-production.up.railway.app';
  
  // Chaves para cache
  static const String _cacheKey = 'cached_m3u_content';
  static const String _lastSyncKey = 'last_content_sync';
  static const String _contentVersionKey = 'content_version';
  
  // Intervalo mínimo entre sincronizações (em minutos)
  static const int _minSyncIntervalMinutes = 30;
  
  /// Busca o conteúdo M3U (do servidor ou cache)
  /// [forceRefresh] - Se true, ignora o cache e busca do servidor
  static Future<ContentResult> fetchContent({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verifica se deve buscar do servidor
    final shouldFetch = forceRefresh || await _shouldRefreshContent();
    
    if (shouldFetch) {
      try {
        final result = await _fetchFromServer();
        if (result.success) {
          // Salva no cache
          await _saveToCache(result.content, result.version);
          return result;
        }
      } catch (e) {
        debugPrint('Erro ao buscar do servidor: $e');
      }
    }
    
    // Tenta carregar do cache
    final cachedContent = prefs.getString(_cacheKey);
    if (cachedContent != null && cachedContent.isNotEmpty) {
      return ContentResult(
        success: true,
        content: cachedContent,
        source: ContentSource.cache,
        version: prefs.getString(_contentVersionKey) ?? '',
      );
    }
    
    // Fallback: carrega do asset local
    try {
      final assetContent = await rootBundle.loadString('canais.m3u');
      return ContentResult(
        success: true,
        content: assetContent,
        source: ContentSource.asset,
        version: 'local',
      );
    } catch (e) {
      return ContentResult(
        success: false,
        content: '',
        source: ContentSource.none,
        error: 'Não foi possível carregar o conteúdo: $e',
      );
    }
  }
  
  /// Busca o conteúdo do servidor
  static Future<ContentResult> _fetchFromServer() async {
    try {
      // Primeiro verifica se há nova versão
      final versionResponse = await http.get(
        Uri.parse('$_baseUrl/api/content/version'),
      ).timeout(const Duration(seconds: 10));
      
      String serverVersion = '';
      if (versionResponse.statusCode == 200) {
        final data = json.decode(versionResponse.body);
        serverVersion = data['version']?.toString() ?? '';
        
        // Verifica se a versão é a mesma do cache
        final prefs = await SharedPreferences.getInstance();
        final cachedVersion = prefs.getString(_contentVersionKey) ?? '';
        
        if (serverVersion.isNotEmpty && serverVersion == cachedVersion) {
          // Mesma versão, não precisa baixar
          final cachedContent = prefs.getString(_cacheKey);
          if (cachedContent != null) {
            // Atualiza timestamp de sync
            await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
            return ContentResult(
              success: true,
              content: cachedContent,
              source: ContentSource.cache,
              version: cachedVersion,
              message: 'Conteúdo já está atualizado',
            );
          }
        }
      }
      
      // Busca o conteúdo M3U
      final contentResponse = await http.get(
        Uri.parse('$_baseUrl/api/content/m3u'),
      ).timeout(const Duration(seconds: 30));
      
      if (contentResponse.statusCode == 200) {
        return ContentResult(
          success: true,
          content: contentResponse.body,
          source: ContentSource.server,
          version: serverVersion,
          message: 'Conteúdo atualizado com sucesso',
        );
      } else {
        return ContentResult(
          success: false,
          content: '',
          source: ContentSource.none,
          error: 'Erro do servidor: ${contentResponse.statusCode}',
        );
      }
    } catch (e) {
      return ContentResult(
        success: false,
        content: '',
        source: ContentSource.none,
        error: 'Erro de conexão: $e',
      );
    }
  }
  
  /// Verifica se deve atualizar o conteúdo
  static Future<bool> _shouldRefreshContent() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    
    if (lastSync == 0) return true;
    
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime).inMinutes;
    
    return difference >= _minSyncIntervalMinutes;
  }
  
  /// Salva o conteúdo no cache local
  static Future<void> _saveToCache(String content, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, content);
    await prefs.setString(_contentVersionKey, version);
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Limpa o cache local
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_contentVersionKey);
    await prefs.remove(_lastSyncKey);
  }
  
  /// Retorna informações sobre o cache atual
  static Future<CacheInfo> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final version = prefs.getString(_contentVersionKey) ?? '';
    final hasCache = prefs.getString(_cacheKey)?.isNotEmpty ?? false;
    
    return CacheInfo(
      hasCache: hasCache,
      version: version,
      lastSync: lastSync > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastSync) 
        : null,
    );
  }
}

/// Resultado da busca de conteúdo
class ContentResult {
  final bool success;
  final String content;
  final ContentSource source;
  final String version;
  final String? message;
  final String? error;
  
  ContentResult({
    required this.success,
    required this.content,
    required this.source,
    this.version = '',
    this.message,
    this.error,
  });
}

/// Fonte do conteúdo
enum ContentSource {
  server,  // Baixado do servidor
  cache,   // Carregado do cache local
  asset,   // Carregado do asset bundled
  none,    // Nenhum (erro)
}

/// Informações do cache
class CacheInfo {
  final bool hasCache;
  final String version;
  final DateTime? lastSync;
  
  CacheInfo({
    required this.hasCache,
    required this.version,
    this.lastSync,
  });
  
  String get lastSyncFormatted {
    if (lastSync == null) return 'Nunca';
    final now = DateTime.now();
    final diff = now.difference(lastSync!);
    
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return 'Há ${diff.inDays} dias';
  }
}
