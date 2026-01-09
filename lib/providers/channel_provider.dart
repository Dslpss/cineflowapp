import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../services/m3u_parser.dart';
import '../services/storage_service.dart';
import '../services/content_sync_service.dart';

/// Provider para gerenciamento de estado dos canais
class ChannelProvider extends ChangeNotifier {
  List<Channel> _allChannels = [];
  List<Channel> _rawChannels = []; // Canais originais sem filtro
  List<Channel> _filteredChannels = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSyncing = false; // Indica se está sincronizando com servidor
  String? _error;
  String _qualityFilter = 'all';
  
  // Informações sobre o conteúdo carregado
  ContentSource _contentSource = ContentSource.none;
  String _contentVersion = '';
  DateTime? _lastSync;

  // Getters
  List<Channel> get allChannels => _allChannels;
  List<Channel> get filteredChannels => _filteredChannels;
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String get qualityFilter => _qualityFilter;
  
  // Getters de sincronização
  ContentSource get contentSource => _contentSource;
  String get contentVersion => _contentVersion;
  DateTime? get lastSync => _lastSync;
  
  int get totalChannels => _allChannels.length;
  int get totalCategories => _categories.length;

  /// Atualiza visibilidade de conteúdo adulto
  void updateAdultContentVisibility() {
    _updateChannelsFromRaw();
    notifyListeners();
  }

  /// Aplica filtros globais (como conteúdo adulto) na lista raw
  void _updateChannelsFromRaw() {
    if (_rawChannels.isEmpty) return;
    
    // Filtra conteúdo adulto se necessário
    if (!StorageService.showAdultContent()) {
      _allChannels = _rawChannels.where((ch) => 
        !ch.category.toLowerCase().contains('adulto')
      ).toList();
    } else {
      _allChannels = List.from(_rawChannels);
    }
    
    // Atualiza categorias
    _categories = M3UParser.getCategories(_allChannels);
    
    // Aplica filtros de busca/categoria
    _applyFilters();
  }

  /// Canais favoritos
  List<Channel> get favoriteChannels {
    final favoriteIds = StorageService.getFavoriteIds();
    return _allChannels.where((ch) => favoriteIds.contains(ch.id)).toList();
  }
  
  int get totalFavorites => favoriteChannels.length;

  /// Canais recentes
  List<Channel> get recentChannels {
    final recentIds = StorageService.getRecentIds();
    final List<Channel> recents = [];
    for (final id in recentIds) {
      final channel = _allChannels.firstWhere(
        (ch) => ch.id == id,
        orElse: () => Channel(id: '', name: '', logoUrl: '', streamUrl: '', category: ''),
      );
      if (channel.id.isNotEmpty) {
        recents.add(channel);
      }
    }
    return recents;
  }

  /// Carrega canais de um arquivo M3U
  Future<void> loadFromFile(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rawChannels = await M3UParser.parseFile(filePath);
      _updateChannelsFromRaw();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar canais: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega canais de um asset M3U
  Future<void> loadFromAsset(String assetPath) async {
    _isLoading = true;
    _error = null;
    // Não notifica imediatamente para evitar erro durante build

    try {
      // Lê o arquivo do bundle de assets
      final content = await rootBundle.loadString(assetPath);
      
      _rawChannels = M3UParser.parseContent(content);
      _updateChannelsFromRaw();
      
      _isLoading = false;
      
      // Adiamos notifyListeners para o próximo frame
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = 'Erro ao carregar canais do asset: $e';
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Carrega canais de conteúdo M3U
  void loadFromContent(String content) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rawChannels = M3UParser.parseContent(content);
      _updateChannelsFromRaw();
      
      _isLoading = false;
      
      // Adiamos notifyListeners para o próximo frame
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _error = 'Erro ao processar canais: $e';
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // ===== AÇÕES =====

  /// Seleciona uma categoria para filtro
  void selectCategory(Category? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Define a busca
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }
  
  /// Define filtro de qualidade
  void setQualityFilter(String quality) {
    _qualityFilter = quality;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica todos os filtros na lista de canais
  void _applyFilters() {
    var channels = List<Channel>.from(_allChannels);
    
    // Filtro de Categoria
    if (_selectedCategory != null) {
      channels = M3UParser.filterByCategory(channels, _selectedCategory!.name);
    }
    
    // Filtro de Busca
    if (_searchQuery.isNotEmpty) {
      channels = M3UParser.search(channels, _searchQuery);
    }
    
    // Filtro de Qualidade (exceto 'all')
    if (_qualityFilter != 'all') {
      channels = M3UParser.filterByQuality(channels, _qualityFilter);
    }
    
    _filteredChannels = channels;
  }
  
  /// Retorna canais de uma categoria específica (helper para UI)
  List<Channel> getChannelsByCategory(String categoryName) {
    return M3UParser.filterByCategory(_allChannels, categoryName);
  }

  /// Limpa filtros
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _qualityFilter = 'all';
    _applyFilters();
    notifyListeners();
  }
  
  // ===== FAVORITOS E RECENTES =====
  
  bool isFavorite(String channelId) {
    return StorageService.isFavorite(channelId);
  }
  
  Future<void> toggleFavorite(Channel channel) async {
    await StorageService.toggleFavorite(channel.id);
    notifyListeners(); // Atualiza UI
  }
  
  Future<void> addToRecent(Channel channel) async {
    await StorageService.addRecent(channel.id);
    notifyListeners(); // Atualiza UI de recentes
  }
  
  // ===== SINCRONIZAÇÃO DE CONTEÚDO =====
  
  /// Sincroniza conteúdo do servidor (método principal)
  /// [forceRefresh] - Se true, ignora cache e busca do servidor
  /// Retorna true se houve atualização de conteúdo
  Future<SyncResult> syncContent({bool forceRefresh = false}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronização já em andamento');
    }
    
    _isSyncing = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await ContentSyncService.fetchContent(forceRefresh: forceRefresh);
      
      if (result.success && result.content.isNotEmpty) {
        final previousCount = _rawChannels.length;
        
        // Processa o conteúdo
        _rawChannels = M3UParser.parseContent(result.content);
        _updateChannelsFromRaw();
        
        // Atualiza metadados
        _contentSource = result.source;
        _contentVersion = result.version;
        _lastSync = DateTime.now();
        
        _isSyncing = false;
        _isLoading = false;
        
        Future.microtask(() => notifyListeners());
        
        final newCount = _rawChannels.length;
        final diff = newCount - previousCount;
        
        String message;
        if (previousCount == 0) {
          message = '$newCount canais carregados';
        } else if (diff > 0) {
          message = '$diff novos canais adicionados';
        } else if (diff < 0) {
          message = '${-diff} canais removidos';
        } else {
          message = 'Conteúdo já está atualizado';
        }
        
        return SyncResult(
          success: true,
          message: message,
          source: result.source,
          channelsLoaded: newCount,
          newChannels: diff > 0 ? diff : 0,
        );
      } else {
        _isSyncing = false;
        _error = result.error ?? 'Falha ao carregar conteúdo';
        Future.microtask(() => notifyListeners());
        
        return SyncResult(
          success: false,
          message: result.error ?? 'Falha ao carregar conteúdo',
        );
      }
    } catch (e) {
      _isSyncing = false;
      _error = 'Erro na sincronização: $e';
      Future.microtask(() => notifyListeners());
      
      return SyncResult(success: false, message: 'Erro: $e');
    }
  }
  
  /// Força atualização do conteúdo (ignora cache)
  Future<SyncResult> refreshContent() async {
    return syncContent(forceRefresh: true);
  }
  
  /// Retorna informações do cache atual
  Future<CacheInfo> getCacheInfo() async {
    return ContentSyncService.getCacheInfo();
  }
  
  /// Limpa cache de conteúdo
  Future<void> clearContentCache() async {
    await ContentSyncService.clearCache();
    _contentVersion = '';
    _lastSync = null;
    notifyListeners();
  }
}

/// Resultado da sincronização
class SyncResult {
  final bool success;
  final String message;
  final ContentSource? source;
  final int channelsLoaded;
  final int newChannels;
  
  SyncResult({
    required this.success,
    required this.message,
    this.source,
    this.channelsLoaded = 0,
    this.newChannels = 0,
  });
}
