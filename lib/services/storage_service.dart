import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para persistência de dados locais
class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _recentKey = 'recent_channels';
  static const String _settingsKey = 'settings';
  static const String _playbackProgressKey = 'playback_progress';

  static SharedPreferences? _prefs;

  /// Inicializa o serviço
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Verifica se está inicializado
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        'StorageService não inicializado. Chame init() primeiro.',
      );
    }
    return _prefs!;
  }

  // ===== FAVORITOS =====

  /// Obtém lista de IDs favoritos
  static Set<String> getFavoriteIds() {
    final List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.toSet();
  }

  /// Adiciona um canal aos favoritos
  static Future<bool> addFavorite(String channelId) async {
    final favorites = getFavoriteIds();
    favorites.add(channelId);
    return prefs.setStringList(_favoritesKey, favorites.toList());
  }

  /// Remove um canal dos favoritos
  static Future<bool> removeFavorite(String channelId) async {
    final favorites = getFavoriteIds();
    favorites.remove(channelId);
    return prefs.setStringList(_favoritesKey, favorites.toList());
  }

  /// Alterna o status de favorito
  static Future<bool> toggleFavorite(String channelId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(channelId)) {
      return removeFavorite(channelId);
    } else {
      return addFavorite(channelId);
    }
  }

  /// Verifica se um canal é favorito
  static bool isFavorite(String channelId) {
    return getFavoriteIds().contains(channelId);
  }

  // ===== CANAIS RECENTES =====

  /// Obtém lista de IDs de canais recentes
  static List<String> getRecentIds() {
    return prefs.getStringList(_recentKey) ?? [];
  }

  /// Adiciona um canal aos recentes (máximo 20)
  static Future<bool> addRecent(String channelId) async {
    final recents = getRecentIds();

    // Remove se já existe para reordenar
    recents.remove(channelId);

    // Adiciona no início
    recents.insert(0, channelId);

    // Mantém apenas os 20 mais recentes
    if (recents.length > 20) {
      recents.removeRange(20, recents.length);
    }

    return prefs.setStringList(_recentKey, recents);
  }

  /// Limpa histórico de recentes
  static Future<bool> clearRecents() async {
    return prefs.remove(_recentKey);
  }

  static Map<String, int> _getPlaybackProgressMap() {
    final json = prefs.getString(_playbackProgressKey);
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = <String, int>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is int) {
          result[entry.key] = value;
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            result[entry.key] = parsed;
          }
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<bool> _setPlaybackProgressMap(Map<String, int> map) {
    if (map.isEmpty) {
      return prefs.remove(_playbackProgressKey);
    }
    return prefs.setString(_playbackProgressKey, jsonEncode(map));
  }

  static Duration? getPlaybackProgress(String channelId) {
    final map = _getPlaybackProgressMap();
    final seconds = map[channelId];
    if (seconds == null || seconds <= 0) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  static Future<bool> savePlaybackProgress(
    String channelId,
    Duration position,
  ) {
    final map = _getPlaybackProgressMap();
    map[channelId] = position.inSeconds;
    return _setPlaybackProgressMap(map);
  }

  static Future<bool> clearPlaybackProgress(String channelId) {
    final map = _getPlaybackProgressMap();
    if (!map.containsKey(channelId)) {
      return Future.value(true);
    }
    map.remove(channelId);
    return _setPlaybackProgressMap(map);
  }

  // ===== CONFIGURAÇÕES =====

  /// Obtém uma configuração
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) return defaultValue;

    try {
      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      return settings[key] as T? ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Define uma configuração
  static Future<bool> setSetting(String key, dynamic value) async {
    final settingsJson = prefs.getString(_settingsKey);
    Map<String, dynamic> settings = {};

    if (settingsJson != null) {
      try {
        settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      } catch (e) {
        settings = {};
      }
    }

    settings[key] = value;
    return prefs.setString(_settingsKey, jsonEncode(settings));
  }

  /// Obtém preferência de qualidade padrão
  static String getPreferredQuality() {
    return getSetting<String>('preferredQuality', defaultValue: 'FHD') ?? 'FHD';
  }

  /// Define preferência de qualidade
  static Future<bool> setPreferredQuality(String quality) {
    return setSetting('preferredQuality', quality);
  }

  /// Obtém se deve mostrar conteúdo adulto
  static bool showAdultContent() {
    return getSetting<bool>('showAdultContent', defaultValue: false) ?? false;
  }

  /// Define se deve mostrar conteúdo adulto
  static Future<bool> setShowAdultContent(bool show) {
    return setSetting('showAdultContent', show);
  }

  /// Limpa todos os dados
  static Future<bool> clearAll() async {
    return prefs.clear();
  }
}
