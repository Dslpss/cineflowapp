import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../providers/channel_provider.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// Tela de Filmes organizada por gêneros
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String? _selectedGenre;
  String _searchQuery = '';

  /// Gêneros de filmes baseados nas categorias do M3U
  List<_MovieGenre> _getGenres(ChannelProvider provider) {
    final genreData = <String, List<Channel>>{};
    
    for (final category in provider.categories) {
      if (category.name.startsWith('Filmes:') || category.name == 'Show') {
        final channels = provider.getChannelsByCategory(category.name);
        if (channels.isNotEmpty) {
          genreData[category.name] = channels;
        }
      }
    }
    
    return genreData.entries.map((e) => _MovieGenre(
      name: e.key,
      displayName: e.key.replaceAll('Filmes:', '').trim(),
      movies: e.value,
      icon: _getGenreIcon(e.key),
      color: _getGenreColor(e.key),
    )).toList()
      ..sort((a, b) => b.movies.length.compareTo(a.movies.length));
  }

  IconData _getGenreIcon(String genre) {
    final lower = genre.toLowerCase();
    if (lower.contains('ação')) return Icons.local_fire_department;
    if (lower.contains('comédia') || lower.contains('comedia')) return Icons.mood;
    if (lower.contains('terror')) return Icons.dark_mode;
    if (lower.contains('romance')) return Icons.favorite;
    if (lower.contains('drama')) return Icons.theater_comedy;
    if (lower.contains('animação') || lower.contains('animacao')) return Icons.animation;
    if (lower.contains('ficção') || lower.contains('ficcao')) return Icons.rocket_launch;
    if (lower.contains('infantil')) return Icons.child_care;
    if (lower.contains('suspense')) return Icons.psychology;
    if (lower.contains('documentário') || lower.contains('documentario')) return Icons.menu_book;
    if (lower.contains('fantasia')) return Icons.auto_awesome;
    if (lower.contains('faroeste')) return Icons.terrain;
    if (lower.contains('marvel')) return Icons.shield;
    if (lower.contains('lançamento') || lower.contains('lancamento')) return Icons.new_releases;
    if (lower.contains('4k')) return Icons.hd;
    if (lower.contains('show')) return Icons.mic_external_on;
    return Icons.movie;
  }

  Color _getGenreColor(String genre) {
    final lower = genre.toLowerCase();
    if (lower.contains('ação')) return Colors.orange;
    if (lower.contains('comédia') || lower.contains('comedia')) return Colors.yellow.shade700;
    if (lower.contains('terror')) return Colors.deepPurple;
    if (lower.contains('romance')) return Colors.pink;
    if (lower.contains('drama')) return Colors.blue;
    if (lower.contains('animação') || lower.contains('animacao')) return Colors.cyan;
    if (lower.contains('ficção') || lower.contains('ficcao')) return Colors.indigo;
    if (lower.contains('infantil')) return Colors.green;
    if (lower.contains('suspense')) return Colors.brown;
    if (lower.contains('fantasia')) return Colors.purple;
    if (lower.contains('marvel')) return Colors.red;
    if (lower.contains('lançamento') || lower.contains('lancamento')) return Colors.teal;
    if (lower.contains('4k')) return Colors.amber;
    if (lower.contains('show')) return Colors.purpleAccent;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<ChannelProvider>(
            builder: (context, provider, child) {
              final genres = _getGenres(provider);
              
              if (_selectedGenre != null) {
                final genre = genres.firstWhere(
                  (g) => g.name == _selectedGenre,
                  orElse: () => genres.first,
                );
                return _buildMoviesList(context, genre, provider);
              }
              
              return _buildGenresView(context, genres);
            },
          ),
      ),
    );
  }

  Widget _buildGenresView(BuildContext context, List<_MovieGenre> genres) {
    // Se tiver busca, mostra os filmes encontrados
    if (_searchQuery.isNotEmpty) {
      final allMovies = genres.expand((g) => g.movies).toList();
      final filteredMovies = allMovies
          .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toSet() // Remove duplicatas se o mesmo filme estiver em várias categorias
          .toList();

      return Column(
        children: [
          // Header simplificado
          _buildHeader(filteredMovies.length, 0, isSearch: true),
          
          // Barra de busca
          _buildSearchBar(),
          
          if (filteredMovies.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 60, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum filme encontrado para "$_searchQuery"',
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
                  itemCount: filteredMovies.length,
                  itemBuilder: (context, index) {
                    final movie = filteredMovies[index];
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      columnCount: 3,
                      duration: const Duration(milliseconds: 300),
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _MovieCard(
                            movie: movie,
                            onTap: () {
                              context.read<ChannelProvider>().addToRecent(movie);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(channel: movie),
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

    // Se NÃO tiver busca, mostra as categorias (Gêneros)
    final totalMovies = genres.fold<int>(0, (sum, g) => sum + g.movies.length);
    
    return Column(
      children: [
        // Header padrão
        _buildHeader(totalMovies, genres.length),
        
        // Barra de busca
        _buildSearchBar(),
        
        // Grid de gêneros
        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: 2,
                  duration: const Duration(milliseconds: 375),
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _GenreCard(
                        genre: genre,
                        onTap: () {
                          setState(() {
                            _selectedGenre = genre.name;
                          });
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

  Widget _buildHeader(int count, int subtitleCount, {bool isSearch = false}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB20710)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE50914).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(isSearch ? Icons.search : Icons.movie_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSearch ? 'Resultados' : 'Filmes',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  isSearch 
                      ? '$count filmes encontrados'
                      : '$count filmes em $subtitleCount gêneros',
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
            hintText: 'Buscar gênero ou filme...',
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

  Widget _buildMoviesList(BuildContext context, _MovieGenre genre, ChannelProvider provider) {
    var movies = genre.movies;
    
    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      movies = movies.where((m) => 
        m.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return Column(
      children: [
        // Header com voltar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedGenre = null),
                style: IconButton.styleFrom(backgroundColor: AppTheme.surfaceColor),
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: genre.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(genre.icon, color: genre.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genre.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${movies.length} filmes',
                      style: TextStyle(fontSize: 12, color: genre.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Busca
        Padding(
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
                hintText: 'Buscar em ${genre.displayName}...',
                hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Grid de filmes
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
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: 3,
                  duration: const Duration(milliseconds: 300),
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _MovieCard(
                        movie: movie,
                        onTap: () {
                          provider.addToRecent(movie);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(channel: movie),
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
}

/// Modelo de gênero de filme
class _MovieGenre {
  final String name;
  final String displayName;
  final List<Channel> movies;
  final IconData icon;
  final Color color;

  _MovieGenre({
    required this.name,
    required this.displayName,
    required this.movies,
    required this.icon,
    required this.color,
  });
}

/// Card de gênero
class _GenreCard extends StatelessWidget {
  final _MovieGenre genre;
  final VoidCallback onTap;

  const _GenreCard({required this.genre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              genre.color.withOpacity(0.3),
              genre.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: genre.color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(genre.icon, size: 70, color: genre.color.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: genre.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(genre.icon, color: genre.color, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    genre.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${genre.movies.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: genre.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'filmes',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
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

/// Card de filme
class _MovieCard extends StatelessWidget {
  final Channel movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

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
                    if (movie.logoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: movie.logoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: 400,
                          memCacheHeight: 600,
                          maxWidthDiskCache: 600,
                          maxHeightDiskCache: 900,
                          placeholder: (_, __) => const Center(
                            child: Icon(Icons.movie, color: AppTheme.textMuted, size: 32),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.movie, color: AppTheme.textMuted, size: 32),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.movie, color: AppTheme.textMuted, size: 32),
                      ),
                    
                    // Play overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
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
            ),
            
            // Nome
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  movie.name,
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
            ),
          ],
        ),
      ),
    );
  }
}
