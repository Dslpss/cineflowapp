/// Modelo representando um canal de TV/Stream
class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String category;
  final String? tvgId;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.category,
    this.tvgId,
    this.isFavorite = false,
  });

  /// Cria uma cópia com modificações
  Channel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? streamUrl,
    String? category,
    String? tvgId,
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      category: category ?? this.category,
      tvgId: tvgId ?? this.tvgId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'streamUrl': streamUrl,
      'category': category,
      'tvgId': tvgId,
      'isFavorite': isFavorite,
    };
  }

  /// Cria a partir de JSON
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
      category: json['category'] ?? '',
      tvgId: json['tvgId'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// Retorna a qualidade do canal baseado no nome
  String get quality {
    final nameUpper = name.toUpperCase();
    if (nameUpper.contains('4K')) return '4K';
    if (nameUpper.contains('FHD')) return 'FHD';
    if (nameUpper.contains('HD')) return 'HD';
    if (nameUpper.contains('SD')) return 'SD';
    return '';
  }

  /// Verifica se é um canal alternativo
  bool get isAlternative {
    return name.toLowerCase().contains('alter');
  }

  @override
  String toString() {
    return 'Channel(name: $name, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
