import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

/// Card de canal compacto para listas
class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Logo do canal
          _ChannelLogo(logoUrl: channel.logoUrl),
          const SizedBox(width: 12),
          
          // Informações do canal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (channel.quality.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      QualityBadge(quality: channel.quality),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  channel.category.replaceAll('Canais:', '').trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Botão de favorito
          IconButton(
            onPressed: onFavoriteToggle,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppTheme.accentColor : AppTheme.textMuted,
            ),
          ),
          
          // Ícone de play
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de canal em grid
class ChannelGridCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const ChannelGridCard({
    super.key,
    required this.channel,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com logo e favorito
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Logo
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.borderRadiusMedium),
                      ),
                    ),
                    child: Center(
                      child: _ChannelLogo(
                        logoUrl: channel.logoUrl,
                        size: 60,
                      ),
                    ),
                  ),
                  
                  // Badge de qualidade
                  if (channel.quality.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: QualityBadge(quality: channel.quality),
                    ),
                  
                  // Botão de favorito
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? AppTheme.accentColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Overlay de play
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Informações do canal
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      channel.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel.category.replaceAll('Canais:', '').trim(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de canal horizontal para seções
class ChannelHorizontalCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap;

  const ChannelHorizontalCard({
    super.key,
    required this.channel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: _ChannelLogo(
                        logoUrl: channel.logoUrl,
                        size: 50,
                      ),
                    ),
                    if (channel.quality.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: QualityBadge(
                          quality: channel.quality,
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para exibir o logo do canal
class _ChannelLogo extends StatelessWidget {
  final String logoUrl;
  final double size;

  const _ChannelLogo({
    required this.logoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.tv_rounded,
          size: size * 0.5,
          color: AppTheme.primaryColor,
        ),
      );
    }

    final cacheSize = (size * 3).toInt(); // 3x for high density screens

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        maxWidthDiskCache: 400, // Limit disk cache size too
        maxHeightDiskCache: 400,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.tv_rounded,
            size: size * 0.5,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
