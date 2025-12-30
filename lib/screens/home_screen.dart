import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common_widgets.dart';
import 'player_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../providers/auth_provider.dart';

/// Tela principal do app - estilo Netflix/Globoplay
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F18),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<ChannelProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const _LoadingState();
              }
              
              if (provider.error != null) {
                return _ErrorState(error: provider.error!);
              }
              
              if (provider.allChannels.isEmpty) {
                return const _EmptyState();
              }
              
              return _HomeContent(provider: provider);
            },
          ),
        ),
      ),
    );
  }
}

/// Conteúdo principal da home - organizado por categorias
class _HomeContent extends StatelessWidget {
  final ChannelProvider provider;

  const _HomeContent({required this.provider});

  /// Categorias de canais ao vivo para mostrar na home
  List<String> get _liveChannelCategories {
    // Pega todas as categorias que começam com "Canais:"
    return provider.categories
        .map((c) => c.name)
        .where((name) => name.startsWith('Canais:') || name.startsWith(' Canais:'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader(context)),
        
        // Barra de busca
        SliverToBoxAdapter(child: _buildSearchBar(context)),
        
        // Estatísticas
        SliverToBoxAdapter(child: _buildStats()),
        
        // Chips de categoria
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CategoryChips(
              categories: provider.categories.take(10).toList(),
              selectedCategory: null,
              onCategorySelected: (category) {
                if (category != null) {
                  provider.selectCategory(category);
                }
              },
            ),
          ),
        ),
        
        // 🔥 SEÇÃO DE DESTAQUE - CANAIS AO VIVO
        SliverToBoxAdapter(
          child: _buildLiveChannelsHighlight(context),
        ),
        
        // Canais recentes
        if (provider.recentChannels.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Assistidos Recentemente',
              Icons.history_rounded,
              AppTheme.secondaryColor,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalChannelList(
              context,
              provider.recentChannels.take(15).toList(),
            ),
          ),
        ],
        
        // Canais favoritos
        if (provider.favoriteChannels.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Seus Favoritos',
              Icons.favorite_rounded,
              AppTheme.accentColor,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalChannelList(
              context,
              provider.favoriteChannels.take(15).toList(),
            ),
          ),
        ],
        
        // Seções por categoria
        ..._buildCategorySections(context),
        
        // Espaço no final
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// Constrói seções para cada categoria principal
  List<Widget> _buildCategorySections(BuildContext context) {
    final List<Widget> sections = [];
    
    for (final categoryName in _liveChannelCategories) {
      final channels = provider.getChannelsByCategory(categoryName);
      
      if (channels.isEmpty) continue;
      
      // Remove duplicados e pega só os melhores
      final uniqueChannels = _getUniqueChannels(channels);
      
      if (uniqueChannels.isEmpty) continue;
      
      // Encontra a categoria para pegar cor e icon
      final category = provider.categories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => Category(
          name: categoryName,
          displayName: categoryName.replaceAll('Canais:', '').trim(),
          icon: Icons.tv,
          color: AppTheme.primaryColor,
        ),
      );
      
      sections.add(
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            category.displayName,
            category.icon,
            category.color,
            channelCount: uniqueChannels.length,
            onSeeAll: () {
              _showAllChannels(context, category, uniqueChannels);
            },
          ),
        ),
      );
      
      sections.add(
        SliverToBoxAdapter(
          child: _buildHorizontalChannelList(
            context,
            uniqueChannels.take(15).toList(),
          ),
        ),
      );
    }
    
    return sections;
  }

  /// Remove canais duplicados mantendo a melhor qualidade
  List<Channel> _getUniqueChannels(List<Channel> channels) {
    final Map<String, Channel> uniqueMap = {};
    final qualityOrder = {'4K': 4, 'FHD': 3, 'HD': 2, 'SD': 1, '': 0};
    
    for (final channel in channels) {
      // Limpa o nome removendo qualidade e [Alter]
      String cleanName = channel.name
          .replaceAll(RegExp(r'\s*(4K|FHD|HD|SD|H\.265|\[Alter\d?\]).*', caseSensitive: false), '')
          .trim();
      
      if (cleanName.isEmpty) cleanName = channel.name;
      
      if (!uniqueMap.containsKey(cleanName)) {
        uniqueMap[cleanName] = channel;
      } else {
        final existing = uniqueMap[cleanName]!;
        final existingQuality = qualityOrder[existing.quality] ?? 0;
        final newQuality = qualityOrder[channel.quality] ?? 0;
        
        // Prioriza melhor qualidade e não-alternativo
        if (newQuality > existingQuality && !channel.isAlternative) {
          uniqueMap[cleanName] = channel;
        }
      }
    }
    
    return uniqueMap.values.toList();
  }

  void _showAllChannels(BuildContext context, Category category, List<Channel> channels) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllChannelsScreen(
          category: category,
          channels: channels,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineFlow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Premium Streaming',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          // Botão de Perfil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                final initial = user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U');
                
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppTheme.textMuted.withOpacity(0.7)),
              const SizedBox(width: 12),
              Text(
                'Buscar canais, filmes, séries...',
                style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatBadge(
            icon: Icons.tv_rounded,
            value: provider.totalChannels.toString(),
            label: 'Canais',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            icon: Icons.category_rounded,
            value: provider.totalCategories.toString(),
            label: 'Categorias',
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            icon: Icons.favorite_rounded,
            value: provider.totalFavorites.toString(),
            label: 'Favoritos',
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color, {
    int? channelCount,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (channelCount != null)
                  Text(
                    '$channelCount canais',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔥 Seção de destaque dos canais ao vivo
  Widget _buildLiveChannelsHighlight(BuildContext context) {
    // Pegar todos os canais ao vivo
    List<Channel> liveChannels = [];
    for (final categoryName in _liveChannelCategories) {
      liveChannels.addAll(provider.getChannelsByCategory(categoryName));
    }
    
    // Remove duplicados
    final uniqueChannels = _getUniqueChannels(liveChannels);
    
    if (uniqueChannels.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header especial
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 16),
          child: Row(
            children: [
              // Ícone com glow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0844).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '📺 Canais Ao Vivo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Badge AO VIVO animado
                        _AnimatedLiveBadge(),
                      ],
                    ),
                    Text(
                      '${uniqueChannels.length} canais disponíveis',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Lista horizontal de canais em destaque
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: uniqueChannels.take(20).length,
            itemBuilder: (context, index) {
              final channel = uniqueChannels[index];
              return _LiveChannelHighlightCard(
                channel: channel,
                onTap: () {
                  provider.addToRecent(channel);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(channel: channel),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildHorizontalChannelList(BuildContext context, List<Channel> channels) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return _ChannelCard(
            channel: channel,
            onTap: () {
              provider.addToRecent(channel);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(channel: channel),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Card de canal horizontal compacto
class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: channel.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: channel.logoUrl,
                                fit: BoxFit.contain,
                                width: 70,
                                height: 70,
                                placeholder: (_, __) => const Icon(
                                  Icons.tv,
                                  size: 32,
                                  color: AppTheme.textMuted,
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.tv,
                                  size: 32,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            )
                          : const Icon(Icons.tv, size: 32, color: AppTheme.textMuted),
                    ),
                    
                    // Badge de qualidade
                    if (channel.quality.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getQualityColor(channel.quality),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            channel.quality,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    
                    // Live badge
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'AO VIVO',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Nome
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _cleanChannelName(channel.name),
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

  String _cleanChannelName(String name) {
    return name
        .replaceAll(RegExp(r'\s*(FHD|HD|SD|4K|H\.265|\[Alter\d?\])', caseSensitive: false), '')
        .trim();
  }

  Color _getQualityColor(String quality) {
    switch (quality.toUpperCase()) {
      case '4K': return const Color(0xFFFFD700);
      case 'FHD': return const Color(0xFF00FF87);
      case 'HD': return const Color(0xFF00D9FF);
      case 'SD': return const Color(0xFFFF6B9D);
      default: return AppTheme.textMuted;
    }
  }
}

/// Badge de estatística
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge animado "AO VIVO" com efeito pulsante
class _AnimatedLiveBadge extends StatefulWidget {
  @override
  State<_AnimatedLiveBadge> createState() => _AnimatedLiveBadgeState();
}

class _AnimatedLiveBadgeState extends State<_AnimatedLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red,
              Colors.red.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'AO VIVO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de destaque para canal ao vivo - versão maior e mais impactante
class _LiveChannelHighlightCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _LiveChannelHighlightCard({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor,
              const Color(0xFF1F1020), // Toque de vermelho escuro
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área da imagem/logo
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.surfaceColor,
                      AppTheme.surfaceColor.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    // Logo
                    Center(
                      child: channel.logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: CachedNetworkImage(
                                imageUrl: channel.logoUrl,
                                fit: BoxFit.contain,
                                width: 100,
                                height: 100,
                                placeholder: (_, __) => const Icon(
                                  Icons.tv,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.tv,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            )
                          : const Icon(Icons.tv, size: 48, color: AppTheme.textMuted),
                    ),
                    
                    // Badge de qualidade
                    if (channel.quality.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getQualityColor(channel.quality),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: _getQualityColor(channel.quality).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            channel.quality,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    
                    // Badge AO VIVO
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF0844), Color(0xFFFF4D6D)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'AO VIVO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botão de play overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info do canal
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cleanChannelName(channel.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Transmissão ao vivo',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade300,
                      ),
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

  String _cleanChannelName(String name) {
    return name
        .replaceAll(RegExp(r'\s*(FHD|HD|SD|4K|H\.265|\[Alter\d?\])', caseSensitive: false), '')
        .trim();
  }

  Color _getQualityColor(String quality) {
    switch (quality.toUpperCase()) {
      case '4K': return const Color(0xFFFFD700);
      case 'FHD': return const Color(0xFF00FF87);
      case 'HD': return const Color(0xFF00D9FF);
      case 'SD': return const Color(0xFFFF6B9D);
      default: return AppTheme.textMuted;
    }
  }
}

/// Tela para ver todos os canais de uma categoria
class _AllChannelsScreen extends StatelessWidget {
  final Category category;
  final List<Channel> channels;

  const _AllChannelsScreen({
    required this.category,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F18), AppTheme.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: AppTheme.surfaceColor),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(category.icon, color: category.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${channels.length} canais',
                            style: TextStyle(fontSize: 12, color: category.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Grid de canais
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return _ChannelGridItem(
                      channel: channel,
                      onTap: () {
                        context.read<ChannelProvider>().addToRecent(channel);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScreen(channel: channel),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de grid de canal
class _ChannelGridItem extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelGridItem({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: channel.logoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: channel.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.tv,
                            size: 32,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      )
                    : const Icon(Icons.tv, size: 32, color: AppTheme.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                channel.name
                    .replaceAll(RegExp(r'\s*(FHD|HD|SD|4K|H\.265|\[Alter\d?\])', caseSensitive: false), '')
                    .trim(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de loading
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Carregando canais...',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de erro
class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.tv_off_rounded, color: AppTheme.primaryColor, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum canal encontrado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione um arquivo M3U para começar',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
