import 'channel.dart';

/// Representa uma série com suas temporadas e episódios
class Series {
  final String name;
  final String logoUrl;
  final String category;
  final Map<int, List<Episode>> seasons;

  Series({
    required this.name,
    required this.logoUrl,
    required this.category,
    required this.seasons,
  });

  /// Total de episódios
  int get totalEpisodes {
    int count = 0;
    for (final eps in seasons.values) {
      count += eps.length;
    }
    return count;
  }

  /// Total de temporadas
  int get totalSeasons => seasons.length;

  /// Lista de temporadas ordenadas
  List<int> get sortedSeasons {
    final list = seasons.keys.toList();
    list.sort();
    return list;
  }

  /// Obtém episódios de uma temporada
  List<Episode> getEpisodes(int season) {
    final eps = seasons[season] ?? [];
    eps.sort((a, b) => a.episode.compareTo(b.episode));
    return eps;
  }
}

/// Representa um episódio de uma série
class Episode {
  final int season;
  final int episode;
  final Channel channel;

  Episode({
    required this.season,
    required this.episode,
    required this.channel,
  });

  String get displayName => 'S${season.toString().padLeft(2, '0')} E${episode.toString().padLeft(2, '0')}';
}

/// Utilitário para extrair informações de série do nome do canal
class SeriesParser {
  /// Regex para detectar padrão de série: Nome S01 E01 ou Nome T01 E01
  static final RegExp _seriesPattern = RegExp(
    r'^(.+?)\s+[ST](\d{1,2})\s*E(\d{1,2})$',
    caseSensitive: false,
  );

  /// Verifica se o nome é de um episódio de série
  static bool isSeries(String name) {
    return _seriesPattern.hasMatch(name.trim());
  }

  /// Extrai informações de série do nome
  static SeriesInfo? parseSeriesName(String name) {
    final match = _seriesPattern.firstMatch(name.trim());
    if (match == null) return null;

    return SeriesInfo(
      seriesName: match.group(1)?.trim() ?? '',
      season: int.tryParse(match.group(2) ?? '0') ?? 0,
      episode: int.tryParse(match.group(3) ?? '0') ?? 0,
    );
  }

  /// Agrupa canais em séries
  static Map<String, Series> groupIntoSeries(List<Channel> channels) {
    final Map<String, Map<int, List<Episode>>> seriesMap = {};
    final Map<String, String> seriesLogos = {};
    final Map<String, String> seriesCategories = {};

    for (final channel in channels) {
      final info = parseSeriesName(channel.name);
      if (info != null && info.seriesName.isNotEmpty) {
        // Inicializa se não existe
        seriesMap.putIfAbsent(info.seriesName, () => {});
        seriesMap[info.seriesName]!.putIfAbsent(info.season, () => []);

        // Adiciona episódio
        seriesMap[info.seriesName]![info.season]!.add(Episode(
          season: info.season,
          episode: info.episode,
          channel: channel,
        ));

        // Guarda logo e categoria
        if (channel.logoUrl.isNotEmpty) {
          seriesLogos[info.seriesName] = channel.logoUrl;
        }
        seriesCategories[info.seriesName] = channel.category;
      }
    }

    // Converte para objetos Series
    final Map<String, Series> result = {};
    for (final entry in seriesMap.entries) {
      result[entry.key] = Series(
        name: entry.key,
        logoUrl: seriesLogos[entry.key] ?? '',
        category: seriesCategories[entry.key] ?? '',
        seasons: entry.value,
      );
    }

    return result;
  }

  /// Filtra apenas canais que NÃO são séries
  static List<Channel> filterNonSeries(List<Channel> channels) {
    return channels.where((ch) => !isSeries(ch.name)).toList();
  }

  /// Filtra apenas canais que SÃO séries
  static List<Channel> filterSeries(List<Channel> channels) {
    return channels.where((ch) => isSeries(ch.name)).toList();
  }
}

/// Informações extraídas do nome da série
class SeriesInfo {
  final String seriesName;
  final int season;
  final int episode;

  SeriesInfo({
    required this.seriesName,
    required this.season,
    required this.episode,
  });
}
