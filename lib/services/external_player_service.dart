import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// Representa um player externo disponível
class ExternalPlayer {
  final String id;
  final String name;
  final String packageName;
  final String description;
  final IconData icon;
  final Color color;

  const ExternalPlayer({
    required this.id,
    required this.name,
    required this.packageName,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Serviço para abrir vídeos em players externos
class ExternalPlayerService {
  static const List<ExternalPlayer> availablePlayers = [
    ExternalPlayer(
      id: 'share',
      name: 'Compartilhar URL',
      packageName: '',
      description: 'Abre o menu de compartilhamento do sistema',
      icon: Icons.share_rounded,
      color: Color(0xFF4CAF50),
    ),
  ];

  /// Abre o modal de compartilhamento do sistema
  static Future<bool> shareUrl({
    required String videoUrl,
    String? title,
  }) async {
    try {
      await Share.share(
        videoUrl,
        subject: title ?? 'Vídeo',
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao compartilhar: $e');
      return false;
    }
  }

  /// Abre o vídeo no player especificado
  static Future<bool> openInPlayer({
    required String videoUrl,
    required ExternalPlayer player,
    String? title,
  }) async {
    try {
      Uri uri;
      final encodedUrl = Uri.encodeComponent(videoUrl);
      final encodedTitle = Uri.encodeComponent(title ?? 'Video');

      // Compartilhar URL - abre o modal de compartilhamento do sistema
      if (player.id == 'share') {
        return await shareUrl(videoUrl: videoUrl, title: title);
      }

      if (player.id == 'default') {
        // Abre com o player padrão do sistema
        uri = Uri.parse(videoUrl);
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (player.id == 'web_video_cast') {
        // Web Video Cast - usar compartilhamento direcionado
        return await shareUrl(videoUrl: videoUrl, title: title);
      }

      if (player.id == 'vlc') {
        // VLC usa vlc:// scheme
        uri = Uri.parse('vlc://$videoUrl');
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        
        // Fallback com intent
        uri = Uri.parse(
          'intent:$videoUrl#Intent;action=android.intent.action.VIEW;type=video/*;package=${player.packageName};S.title=$encodedTitle;end'
        );
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (player.id == 'mx_player' || player.id == 'mx_player_pro') {
        // MX Player usa intent com dados específicos
        uri = Uri.parse(
          'intent:$videoUrl#Intent;action=android.intent.action.VIEW;type=video/*;package=${player.packageName};S.title=$encodedTitle;end'
        );
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (player.id == 'kodi') {
        // Kodi pode receber URLs diretamente
        uri = Uri.parse(
          'intent:$videoUrl#Intent;action=android.intent.action.VIEW;type=video/*;package=${player.packageName};end'
        );
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Para outros players, tenta abrir com intent genérico de vídeo
      uri = Uri.parse(
        'intent:$videoUrl#Intent;action=android.intent.action.VIEW;type=video/*;package=${player.packageName};end'
      );
      
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
      
    } catch (e) {
      debugPrint('Erro ao abrir player externo: $e');
      return false;
    }
  }

  /// Abre o seletor de apps do sistema para escolher o player
  static Future<bool> openWithSystemPicker({
    required String videoUrl,
    String? title,
  }) async {
    try {
      final uri = Uri.parse(videoUrl);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Erro ao abrir seletor do sistema: $e');
      return false;
    }
  }

  /// Copia a URL para a área de transferência
  static Future<void> copyUrlToClipboard(BuildContext context, String url) async {
    // Usando o Clipboard do Flutter
    await Future.delayed(Duration.zero); // Placeholder
    // A implementação real usará Clipboard.setData
  }
}
