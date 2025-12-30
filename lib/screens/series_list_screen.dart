import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../models/series.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import 'series_screen.dart';

/// Tela de Séries organizada por plataforma/gênero
class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key});

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  String _searchQuery = '';

  /// Obtém categorias de séries
  List<_SeriesCategory> _getSeriesCategories(ChannelProvider provider) {
    final categories = <_SeriesCategory>[];
    
    for (final category in provider.categories) {
      final name = category.name;
      
      // Séries de streaming
      if (name.startsWith('Streaming:') || name.startsWith(' Streaming:')) {
        final channels = provider.getChannelsByCategory(name);
        if (channels.isNotEmpty) {
          final series = SeriesParser.groupIntoSeries(channels);
          categories.add(_SeriesCategory(
            name: name,
            displayName: name.replaceAll('Streaming:', '').replaceAll(' Streaming:', '').trim(),
            channels: channels,
            seriesCount: series.length,
            episodeCount: channels.length,
            icon: _getPlatformIcon(name),
            color: _getPlatformColor(name),
          ));
        }
      }
      
      // Séries por gênero
      if (name.startsWith('Serie:')) {
        final channels = provider.getChannelsByCategory(name);
        if (channels.isNotEmpty) {
          final series = SeriesParser.groupIntoSeries(channels);
          categories.add(_SeriesCategory(
            name: name,
            displayName: name.replaceAll('Serie:', '').trim(),
            channels: channels,
            seriesCount: series.length,
            episodeCount: channels.length,
            icon: _getGenreIcon(name),
            color: _getGenreColor(name),
          ));
        }
      }
      
      // Novelas
      if (name.contains('Novela')) {
        final channels = provider.getChannelsByCategory(name);
        if (channels.isNotEmpty) {
          final series = SeriesParser.groupIntoSeries(channels);
          categories.add(_SeriesCategory(
            name: name,
            displayName: name,
            channels: channels,
            seriesCount: series.length,
            episodeCount: channels.length,
            icon: Icons.live_tv,
            color: Colors.pink,
          ));
        }
      }
      
      // Desenhos e Animes
      if (name.contains('Desenho') || name.contains('Anime')) {
        final channels = provider.getChannelsByCategory(name);
        if (channels.isNotEmpty) {
          final series = SeriesParser.groupIntoSeries(channels);
          categories.add(_SeriesCategory(
            name: name,
            displayName: name,
            channels: channels,
            seriesCount: series.length,
            episodeCount: channels.length,
            icon: Icons.animation,
            color: Colors.purple,
          ));
        }
      }
    }
    
    // Ordena por quantidade de séries
    categories.sort((a, b) => b.seriesCount.compareTo(a.seriesCount));
    
    return categories;
  }

  IconData _getPlatformIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return Icons.play_circle_fill;
    if (lower.contains('amazon') || lower.contains('prime')) return Icons.shopping_bag;
    if (lower.contains('disney')) return Icons.castle;
    if (lower.contains('hbo') || lower.contains('max')) return Icons.movie_filter;
    if (lower.contains('apple')) return Icons.apple;
    if (lower.contains('paramount')) return Icons.star;
    if (lower.contains('globo')) return Icons.public;
    if (lower.contains('star')) return Icons.star_border;
    if (lower.contains('crunchyroll')) return Icons.animation;
    if (lower.contains('discovery')) return Icons.explore;
    return Icons.tv;
  }

  Color _getPlatformColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return const Color(0xFFE50914);
    if (lower.contains('amazon') || lower.contains('prime')) return const Color(0xFF00A8E1);
    if (lower.contains('disney')) return const Color(0xFF113CCF);
    if (lower.contains('hbo') || lower.contains('max')) return const Color(0xFF991EEB);
    if (lower.contains('apple')) return Colors.grey.shade700;
    if (lower.contains('paramount')) return const Color(0xFF0064FF);
    if (lower.contains('globo')) return const Color(0xFFFF0000);
    if (lower.contains('star')) return const Color(0xFF042958);
    if (lower.contains('crunchyroll')) return const Color(0xFFF47521);
    if (lower.contains('discovery')) return const Color(0xFF00838F);
    return AppTheme.primaryColor;
  }

  IconData _getGenreIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ação') || lower.contains('crime')) return Icons.local_fire_department;
    if (lower.contains('comédia') || lower.contains('comedia')) return Icons.mood;
    if (lower.contains('terror') || lower.contains('suspense')) return Icons.dark_mode;
    if (lower.contains('drama')) return Icons.theater_comedy;
    if (lower.contains('fantasia') || lower.contains('ficção')) return Icons.auto_awesome;
    if (lower.contains('documentário') || lower.contains('documentario')) return Icons.menu_book;
    return Icons.tv;
  }

  Color _getGenreColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ação') || lower.contains('crime')) return Colors.orange;
    if (lower.contains('comédia') || lower.contains('comedia')) return Colors.amber;
    if (lower.contains('terror') || lower.contains('suspense')) return Colors.deepPurple;
    if (lower.contains('drama')) return Colors.blue;
    if (lower.contains('fantasia') || lower.contains('ficção')) return Colors.indigo;
    if (lower.contains('documentário') || lower.contains('documentario')) return Colors.teal;
    return AppTheme.primaryColor;
  }

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
          child: Consumer<ChannelProvider>(
            builder: (context, provider, child) {
              final categories = _getSeriesCategories(provider);
              
              // Se tiver busca, mostra as Séries encontradas
              if (_searchQuery.isNotEmpty) {
                 final allChannels = categories.expand((c) => c.channels).toList();
                 final allSeriesMap = SeriesParser.groupIntoSeries(allChannels);
                 final filteredSeries = allSeriesMap.values
                     .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                     .toList();

                return Column(
                  children: [
                    // Header simplificado
                    _buildHeader(filteredSeries.length, 0, 0, isSearch: true),
                    
                    // Barra de busca
                    _buildSearchBar(),
                    
                    if (filteredSeries.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 60, color: AppTheme.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma série encontrada para "$_searchQuery"',
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: AnimationLimiter(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredSeries.length,
                            itemBuilder: (context, index) {
                              final series = filteredSeries[index];
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                columnCount: 3,
                                duration: const Duration(milliseconds: 300),
                                child: ScaleAnimation(
                                  child: FadeInAnimation(
                                    child: _SeriesCard(
                                      series: series,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SeriesScreen(
                                              categoryName: series.name,
                                              channels: series.seasons.values.expand((e) => e.map((ep) => ep.channel)).toList(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              }

              // Se NÃO tiver busca, mostra as categorias (Plataformas/Gêneros)
              final totalSeries = categories.fold<int>(0, (sum, c) => sum + c.seriesCount);
              final totalEpisodes = categories.fold<int>(0, (sum, c) => sum + c.episodeCount);
              
              return Column(
                children: [
                  // Header
                  _buildHeader(totalSeries, totalEpisodes, categories.length),
                  
                  // Busca
                  _buildSearchBar(),
                  
                  // Lista de categorias
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50,
                              child: FadeInAnimation(
                                child: _CategoryTile(
                                  category: category,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SeriesScreen(
                                          categoryName: category.displayName,
                                          channels: category.channels,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalSeries, int totalEpisodes, int categoryCount, {bool isSearch = false}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF6C5CE7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(isSearch ? Icons.search : Icons.video_library_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSearch ? 'Resultados' : 'Séries',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  isSearch 
                      ? '$totalSeries séries encontradas'
                      : '$totalSeries séries • $totalEpisodes episódios',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
        ),
        child: TextField(
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar plataforma ou série...',
            hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.7)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }
}

/// Modelo de categoria de séries
class _SeriesCategory {
  final String name;
  final String displayName;
  final List<Channel> channels;
  final int seriesCount;
  final int episodeCount;
  final IconData icon;
  final Color color;

  _SeriesCategory({
    required this.name,
    required this.displayName,
    required this.channels,
    required this.seriesCount,
    required this.episodeCount,
    required this.icon,
    required this.color,
  });
}

/// Tile de categoria
class _CategoryTile extends StatelessWidget {
  final _SeriesCategory category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withOpacity(0.2),
              category.color.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 30),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBadge(
                        Icons.video_library,
                        '${category.seriesCount} séries',
                        category.color,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        Icons.play_circle,
                        '${category.episodeCount} eps',
                        AppTheme.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Seta
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: category.color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de série com capa
class _SeriesCard extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;

  const _SeriesCard({required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Tenta pegar a capa do primeiro episódio
    final episodes = series.seasons.values.expand((e) => e).toList();
    final firstEpisode = episodes.isNotEmpty ? episodes.first : null;
    final logoUrl = series.logoUrl.isNotEmpty 
        ? series.logoUrl 
        : (firstEpisode?.channel.logoUrl ?? '');

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
            // Poster
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    if (logoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => const Center(
                            child: Icon(Icons.tv, color: AppTheme.textMuted, size: 32),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.tv, color: AppTheme.textMuted, size: 32),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.tv, color: AppTheme.textMuted, size: 32),
                      ),
                    
                    // Seasons count
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${series.seasons.length} Temp',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
