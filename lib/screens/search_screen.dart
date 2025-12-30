import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/common_widgets.dart';
import 'player_screen.dart';

/// Tela de busca
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedQuality = 'all';

  @override
  void initState() {
    super.initState();
    // Foca no campo de busca ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    // Limpa a busca ao sair
    context.read<ChannelProvider>().setSearchQuery('');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header com busca
            _buildSearchHeader(),
            
            // Filtros de qualidade
            _buildQualityFilters(),
            
            // Resultados
            Expanded(
              child: Consumer<ChannelProvider>(
                builder: (context, provider, child) {
                  if (_searchController.text.isEmpty) {
                    return _buildRecentSearches();
                  }
                  
                  final results = provider.filteredChannels;
                  
                  if (results.isEmpty) {
                    return _buildNoResults();
                  }
                  
                  return _buildResults(provider, results);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão de voltar
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textSecondary,
            ),
          ),
          
          // Campo de busca
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar canais, filmes, séries...',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            context.read<ChannelProvider>().setSearchQuery('');
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  context.read<ChannelProvider>().setSearchQuery(value);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityFilters() {
    final qualities = ['all', '4K', 'FHD', 'HD', 'SD'];
    final labels = {'all': 'Todas', '4K': '4K', 'FHD': 'FHD', 'HD': 'HD', 'SD': 'SD'};
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: qualities.length,
        itemBuilder: (context, index) {
          final quality = qualities[index];
          final isSelected = _selectedQuality == quality;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedQuality = quality;
              });
              context.read<ChannelProvider>().setQualityFilter(quality);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.textMuted.withOpacity(0.2),
                ),
              ),
              child: Text(
                labels[quality]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sugestões
          const Text(
            'Sugestões de busca',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Globo'),
              _buildSuggestionChip('ESPN'),
              _buildSuggestionChip('Filmes'),
              _buildSuggestionChip('Séries'),
              _buildSuggestionChip('Esportes'),
              _buildSuggestionChip('Infantil'),
              _buildSuggestionChip('Documentários'),
              _buildSuggestionChip('HBO'),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Dicas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dica de busca',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Você pode buscar por nome do canal, categoria ou qualidade',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        context.read<ChannelProvider>().setSearchQuery(text);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppTheme.textMuted,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente buscar por "${_searchController.text}" de outra forma',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ChannelProvider provider, List results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${results.length} resultados para "${_searchController.text}"',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final channel = results[index];
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
                              builder: (context) => PlayerScreen(
                                channel: channel,
                              ),
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
