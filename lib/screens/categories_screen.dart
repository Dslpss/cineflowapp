import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';
import 'series_screen.dart';

/// Tela de categorias
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Category? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
              if (_selectedCategory != null) {
                return _buildCategoryChannels(context, provider);
              }
              return _buildCategoriesGrid(provider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(ChannelProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        
        // Stats
        _buildStats(provider),
        
        // Grid de categorias
        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: 2,
                  duration: const Duration(milliseconds: 375),
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _CategoryCard(
                        category: category,
                        onTap: () {
                          // Detecta se é categoria de streaming/séries
                          final isSeriesCategory = _isSeriesCategory(category.name);
                          
                          if (isSeriesCategory) {
                            // Navega para tela de séries
                            final channels = provider.getChannelsByCategory(category.name);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeriesScreen(
                                  categoryName: category.displayName,
                                  channels: channels,
                                ),
                              ),
                            );
                          } else {
                            // Navega normal
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
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

  /// Verifica se uma categoria é de séries/streaming
  bool _isSeriesCategory(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    return lowerName.contains('streaming') ||
           lowerName.contains('netflix') ||
           lowerName.contains('amazon') ||
           lowerName.contains('prime') ||
           lowerName.contains('hbo') ||
           lowerName.contains('disney') ||
           lowerName.contains('apple') ||
           lowerName.contains('paramount') ||
           lowerName.contains('star+') ||
           lowerName.contains('globoplay') ||
           lowerName.contains('séries') ||
           lowerName.contains('series');
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF87).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          // Título
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore por tipo de conteúdo',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildStats(ChannelProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatBadge(
            Icons.category_rounded,
            '${provider.categories.length}',
            'categorias',
            const Color(0xFF00FF87),
          ),
          const SizedBox(width: 12),
          _buildStatBadge(
            Icons.tv_rounded,
            '${provider.allChannels.length}',
            'canais',
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChannels(BuildContext context, ChannelProvider provider) {
    final channels = provider.getChannelsByCategory(_selectedCategory!.name);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com voltar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                ),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedCategory!.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedCategory!.icon,
                  color: _selectedCategory!.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory!.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${channels.length} canais',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedCategory!.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Lista de canais
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: ChannelCard(
                        channel: channel,
                        isFavorite: provider.isFavorite(channel.id),
                        onTap: () {
                          provider.addToRecent(channel);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(channel: channel),
                            ),
                          );
                        },
                        onFavoriteToggle: () => provider.toggleFavorite(channel),
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
}

/// Card de categoria
class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withOpacity(0.25),
              category.color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: category.color.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            // Ícone grande de fundo
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                category.icon,
                size: 80,
                color: category.color.withOpacity(0.1),
              ),
            ),
            
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 22,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${category.channelCount}',
                            style: TextStyle(
                              fontSize: 13,
                              color: category.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'canais',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: category.color.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
