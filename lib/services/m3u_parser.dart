import 'dart:io';
import '../models/channel.dart';
import '../models/category.dart';

/// Parser para arquivos M3U
class M3UParser {
  /// Parse um arquivo M3U e retorna uma lista de canais
  static Future<List<Channel>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Arquivo M3U não encontrado: $filePath');
    }
    
    final content = await file.readAsString();
    return parseContent(content);
  }

  /// Parse o conteúdo M3U e retorna uma lista de canais
  static List<Channel> parseContent(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');
    
    String? currentExtInf;
    int channelId = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.startsWith('#EXTINF:')) {
        currentExtInf = trimmedLine;
      } else if (trimmedLine.isNotEmpty && 
                 !trimmedLine.startsWith('#') && 
                 currentExtInf != null) {
        // Parse a linha EXTINF
        final channel = _parseExtInf(currentExtInf, trimmedLine, channelId);
        if (channel != null) {
          channels.add(channel);
          channelId++;
        }
        currentExtInf = null;
      }
    }
    
    return channels;
  }

  /// Parse uma linha EXTINF e retorna um Canal
  static Channel? _parseExtInf(String extInf, String streamUrl, int id) {
    try {
      // Extrai tvg-id
      final tvgIdMatch = RegExp(r'tvg-id="([^"]*)"').firstMatch(extInf);
      final tvgId = tvgIdMatch?.group(1) ?? '';
      
      // Extrai tvg-name
      final tvgNameMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(extInf);
      final tvgName = tvgNameMatch?.group(1) ?? '';
      
      // Extrai tvg-logo
      final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(extInf);
      final logoUrl = logoMatch?.group(1) ?? '';
      
      // Extrai group-title
      final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(extInf);
      final category = groupMatch?.group(1) ?? 'Outros';
      
      // Extrai o nome de exibição (após a última vírgula)
      final displayNameMatch = RegExp(r',([^,]+)$').firstMatch(extInf);
      final displayName = displayNameMatch?.group(1)?.trim() ?? tvgName;
      
      if (displayName.isEmpty || streamUrl.isEmpty) {
        return null;
      }
      
      return Channel(
        id: 'ch_$id',
        name: displayName,
        logoUrl: logoUrl,
        streamUrl: streamUrl.trim(),
        category: category,
        tvgId: tvgId.isNotEmpty ? tvgId : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Agrupa canais por categoria
  static Map<String, List<Channel>> groupByCategory(List<Channel> channels) {
    final Map<String, List<Channel>> grouped = {};
    
    for (final channel in channels) {
      if (!grouped.containsKey(channel.category)) {
        grouped[channel.category] = [];
      }
      grouped[channel.category]!.add(channel);
    }
    
    return grouped;
  }

  /// Obtém lista de categorias com contagem
  static List<Category> getCategories(List<Channel> channels) {
    final grouped = groupByCategory(channels);
    
    return grouped.entries.map((entry) {
      return Category.fromString(entry.key, count: entry.value.length);
    }).toList()
      ..sort((a, b) => b.channelCount.compareTo(a.channelCount));
  }

  /// Filtra canais por categoria
  static List<Channel> filterByCategory(List<Channel> channels, String category) {
    return channels.where((ch) => ch.category == category).toList();
  }

  /// Busca canais por nome
  static List<Channel> search(List<Channel> channels, String query) {
    if (query.isEmpty) return channels;
    
    final queryLower = query.toLowerCase();
    return channels.where((ch) {
      return ch.name.toLowerCase().contains(queryLower) ||
             ch.category.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Filtra canais por qualidade
  static List<Channel> filterByQuality(List<Channel> channels, String quality) {
    return channels.where((ch) => ch.quality == quality).toList();
  }

  /// Remove canais duplicados mantendo a melhor qualidade
  static List<Channel> removeDuplicates(List<Channel> channels) {
    final Map<String, Channel> uniqueChannels = {};
    final qualityOrder = {'4K': 4, 'FHD': 3, 'HD': 2, 'SD': 1, '': 0};
    
    for (final channel in channels) {
      // Cria uma chave baseada no nome limpo (sem qualidade e [Alter])
      final cleanName = channel.name
          .replaceAll(RegExp(r'\s*(4K|FHD|HD|SD|H\.265|\[Alter\d?\]).*', caseSensitive: false), '')
          .trim();
      
      if (!uniqueChannels.containsKey(cleanName)) {
        uniqueChannels[cleanName] = channel;
      } else {
        final existing = uniqueChannels[cleanName]!;
        final existingQuality = qualityOrder[existing.quality] ?? 0;
        final newQuality = qualityOrder[channel.quality] ?? 0;
        
        if (newQuality > existingQuality && !channel.isAlternative) {
          uniqueChannels[cleanName] = channel;
        }
      }
    }
    
    return uniqueChannels.values.toList();
  }
}
