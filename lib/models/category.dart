import 'package:flutter/material.dart';

/// Modelo representando uma categoria de canais
class Category {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final int channelCount;

  const Category({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    this.channelCount = 0,
  });

  /// Cria uma cópia com modificações
  Category copyWith({
    String? name,
    String? displayName,
    IconData? icon,
    Color? color,
    int? channelCount,
  }) {
    return Category(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      channelCount: channelCount ?? this.channelCount,
    );
  }

  /// Mapeamento de categorias para ícones e cores
  static Category fromString(String categoryName, {int count = 0}) {
    final cleanName = categoryName.replaceAll('Canais:', '').trim();
    
    final categoryMap = {
      'Filmes e Series': (Icons.movie_outlined, Colors.purple),
      'Esportes': (Icons.sports_soccer_outlined, Colors.green),
      'Esportes PPV': (Icons.sports_mma_outlined, Colors.orange),
      'Esportes Estaduais': (Icons.sports_outlined, Colors.teal),
      'Esportes Europeus': (Icons.sports_outlined, Colors.blue),
      'Infantil': (Icons.child_care_outlined, Colors.pink),
      'Documentários': (Icons.nature_outlined, Colors.brown),
      'Noticias': (Icons.newspaper_outlined, Colors.red),
      'Variedades e Músicas': (Icons.music_note_outlined, Colors.indigo),
      'Abertos': (Icons.tv_outlined, Colors.cyan),
      '4K': (Icons.hd_outlined, Colors.amber),
      'FHD H.265': (Icons.high_quality_outlined, Colors.deepPurple),
      'Pay Per View': (Icons.live_tv_outlined, Colors.deepOrange),
      '24hrs': (Icons.schedule_outlined, Colors.blueGrey),
      'Globo': (Icons.circle_outlined, Colors.lightBlue),
      'Disney +': (Icons.castle_outlined, Colors.blue),
      'Legendados': (Icons.subtitles_outlined, Colors.grey),
      'Religioso': (Icons.church_outlined, Colors.brown),
      'Adultos': (Icons.eighteen_mp_outlined, Colors.red),
      'Área do Cliente': (Icons.person_outlined, Colors.blueGrey),
    };

    final entry = categoryMap[cleanName];
    
    return Category(
      name: categoryName,
      displayName: cleanName,
      icon: entry?.$1 ?? Icons.live_tv_outlined,
      color: entry?.$2 ?? Colors.grey,
      channelCount: count,
    );
  }

  @override
  String toString() => 'Category($displayName, $channelCount channels)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
