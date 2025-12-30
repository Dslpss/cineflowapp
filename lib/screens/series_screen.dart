import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/channel.dart';
import '../models/series.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// Tela de séries com agrupamento por temporadas
class SeriesScreen extends StatefulWidget {
  final String categoryName;
  final List<Channel> channels;

  const SeriesScreen({
    super.key,
    required this.categoryName,
    required this.channels,
  });

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  late Map<String, Series> _series;
  late List<Channel> _nonSeriesChannels;
  String _searchQuery = '';
  bool _showOnlySeries = true;

  @override
  void initState() {
    super.initState();
    _processChannels();
  }

  void _processChannels() {
    _series = SeriesParser.groupIntoSeries(widget.channels);
    _nonSeriesChannels = SeriesParser.filterNonSeries(widget.channels);
  }

  List<Series> get _filteredSeries {
    if (_searchQuery.isEmpty) {
      final list = _series.values.toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }
    return _series.values
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Channel> get _filteredNonSeries {
    if (_searchQuery.isEmpty) return _nonSeriesChannels;
    return _nonSeriesChannels
        .where((ch) => ch.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
            colors: [
              Color(0xFF0F0F18),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Barra de busca
              _buildSearchBar(),
              
              // Toggle Séries/Todos
              _buildToggle(),
              
              // Estatísticas
              _buildStats(),
              
              // Lista de conteúdo
              Expanded(
                child: _showOnlySeries
                    ? _buildSeriesGrid()
                    : _buildChannelsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_series.length} séries • ${_nonSeriesChannels.length} outros',
                  style: const TextStyle(
                    fontSize: 12,
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
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.2),
          ),
        ),
        child: TextField(
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar série...',
            hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.7)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildToggleButton(
            'Séries',
            Icons.video_library_rounded,
            _showOnlySeries,
            () => setState(() => _showOnlySeries = true),
          ),
          const SizedBox(width: 8),
          _buildToggleButton(
            'Todos',
            Icons.list_rounded,
            !_showOnlySeries,
            () => setState(() => _showOnlySeries = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.textMuted.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            _showOnlySeries ? Icons.video_library_rounded : Icons.list_rounded,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            _showOnlySeries
                ? '${_filteredSeries.length} séries encontradas'
                : '${_filteredNonSeries.length} itens encontrados',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesGrid() {
    final series = _filteredSeries;
    
    if (series.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'Nenhuma série encontrada',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: series.length,
        itemBuilder: (context, index) {
          final s = series[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 375),
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _SeriesCard(
                  series: s,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeriesDetailScreen(series: s),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelsList() {
    final channels = _filteredNonSeries;
    
    if (channels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'Nenhum item encontrado',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _ChannelTile(
                  channel: channel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(channel: channel),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card de série
class _SeriesCard extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;

  const _SeriesCard({
    required this.series,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    if (series.logoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: series.logoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.movie_rounded,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.movie_rounded,
                          size: 48,
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                      ),
                    
                    // Badge de temporadas
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${series.totalSeasons} temp',
                          style: const TextStyle(
                            fontSize: 10,
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
            
            // Informações
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: AppTheme.secondaryColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${series.totalEpisodes} episódios',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
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

/// Tile de canal (para não-séries)
class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            if (channel.logoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: channel.logoUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.movie, color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie, color: AppTheme.textMuted),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.play_arrow_rounded,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de detalhes da série
class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late int _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.series.sortedSeasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.series.getEpisodes(_selectedSeason);

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
        child: CustomScrollView(
          slivers: [
            // Header com imagem
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppTheme.backgroundColor,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.series.logoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.series.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceColor,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.backgroundColor.withOpacity(0.8),
                            AppTheme.backgroundColor,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.series.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoBadge(
                                Icons.video_library,
                                '${widget.series.totalSeasons} Temporadas',
                              ),
                              const SizedBox(width: 12),
                              _buildInfoBadge(
                                Icons.play_circle,
                                '${widget.series.totalEpisodes} Episódios',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Seletor de temporada
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temporadas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.series.totalSeasons,
                        itemBuilder: (context, index) {
                          final season = widget.series.sortedSeasons[index];
                          final isSelected = _selectedSeason == season;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSeason = season;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
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
                                'T$season',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de episódios
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Temporada $_selectedSeason',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${episodes.length} episódios',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final episode = episodes[index];
                    return _EpisodeTile(
                      episode: episode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScreen(
                              channel: episode.channel,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: episodes.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de episódio
class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textMuted.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Número do episódio
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'E${episode.episode}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.channel.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            
            // Play button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
