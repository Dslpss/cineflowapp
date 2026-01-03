import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/channel.dart';
import '../theme/app_theme.dart';
import '../widgets/cast_device_sheet.dart';

/// Tela de reprodução de vídeo
class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  
  // Controle de reconexão automática
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _isReconnecting = false;
  DateTime? _lastPlaybackTime;

  @override
  void initState() {
    super.initState();
    // Ativa wakelock para manter tela ligada
    WakelockPlus.enable();
    
    _initializePlayer();
    
    // Força orientação paisagem para o player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cria o controller do video player
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.streamUrl),
        httpHeaders: {
          'User-Agent': 'CineFlow/1.0',
        },
      );

      await _videoController!.initialize();

      // Cria o controller do Chewie com UI customizada
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: AppTheme.backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando ${widget.channel.name}...',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: AppTheme.backgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao reproduzir',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: AppTheme.textMuted.withOpacity(0.3),
          bufferedColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
      );

      // Listener para detectar quando o stream para (conexão cortada)
      _videoController!.addListener(_onPlayerStateChanged);

      setState(() {
        _isLoading = false;
        _reconnectAttempts = 0; // Reset tentativas em caso de sucesso
        _isReconnecting = false;
      });
    } catch (e) {
      // Se falhou e ainda tem tentativas, tenta reconectar
      if (_isReconnecting && _reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          _initializePlayer();
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao inicializar o player: $e';
          _isReconnecting = false;
        });
      }
    }
  }

  /// Monitora estado do player para detectar interrupções
  void _onPlayerStateChanged() {
    if (_videoController == null || !mounted) return;
    
    final isPlaying = _videoController!.value.isPlaying;
    final hasError = _videoController!.value.hasError;
    
    // Se está reproduzindo, atualiza o tempo da última reprodução
    if (isPlaying) {
      _lastPlaybackTime = DateTime.now();
      _reconnectAttempts = 0; // Reset tentativas quando está funcionando
    }
    
    // Detecta se o stream travou (não está reproduzindo, sem erro explícito, mas tinha reprodução recente)
    if (!isPlaying && 
        !hasError && 
        !_isLoading && 
        !_isReconnecting &&
        _lastPlaybackTime != null) {
      
      final timeSinceLastPlay = DateTime.now().difference(_lastPlaybackTime!);
      
      // Se passou mais de 5 segundos sem reproduzir e não está pausado manualmente
      if (timeSinceLastPlay.inSeconds > 5 && 
          _videoController!.value.isInitialized &&
          _reconnectAttempts < _maxReconnectAttempts) {
        _handleStreamInterruption();
      }
    }
    
    // Detecta erro explícito
    if (hasError && !_isReconnecting && _reconnectAttempts < _maxReconnectAttempts) {
      _handleStreamInterruption();
    }
  }

  /// Trata interrupção do stream com reconexão automática
  Future<void> _handleStreamInterruption() async {
    if (_isReconnecting || !mounted) return;
    
    setState(() {
      _isReconnecting = true;
    });
    
    _reconnectAttempts++;
    
    // Limpa controllers antigos
    _videoController?.removeListener(_onPlayerStateChanged);
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
    
    // Aguarda um pouco antes de reconectar
    await Future.delayed(const Duration(seconds: 2));
    
    // Tenta reconectar
    if (mounted) {
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    // Desativa wakelock ao sair
    WakelockPlus.disable();
    
    // Remove listener antes de dispose
    _videoController?.removeListener(_onPlayerStateChanged);
    _videoController?.dispose();
    _chewieController?.dispose();
    
    // Restaura orientação e UI do sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Player de vídeo ou loading inicial (não reconexão)
          if (_chewieController != null && !_isLoading && _error == null)
            Center(
              child: Chewie(controller: _chewieController!),
            )
          else if (_isLoading && !_isReconnecting)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState(),
          
          // Overlay de reconexão (simples, sobre tela preta)
          if (_isReconnecting)
            _buildReconnectingOverlay(),
          
          // Header com informações do canal (visível apenas em portrait)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),
        ],
      ),
    );
  }

  /// Overlay simples de reconexão - apenas ícone de reload
  Widget _buildReconnectingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de reload com animação
            Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de progresso
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryColor.withOpacity(0.8),
                  ),
                ),
                // Ícone de refresh
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Texto de reconexão
            Text(
              'Reconectando...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            // Contador de tentativas
            Text(
              'Tentativa $_reconnectAttempts de $_maxReconnectAttempts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Botão de voltar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações do canal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'AO VIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.channel.category.replaceAll('Canais:', '').trim(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                            // Botão de Cast (transmitir para TV)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CastButton(
                  mediaUrl: widget.channel.streamUrl,
                  mediaTitle: widget.channel.name,
                  thumbnailUrl: widget.channel.logoUrl,
                  color: Colors.white,
                ),
              ),
                            // Qualidade
              if (widget.channel.quality.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getQualityColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getQualityColor().withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    widget.channel.quality,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getQualityColor(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getQualityColor() {
    switch (widget.channel.quality.toUpperCase()) {
      case '4K':
        return const Color(0xFFFFD700);
      case 'FHD':
        return const Color(0xFF00FF87);
      case 'HD':
        return const Color(0xFF00D9FF);
      case 'SD':
        return const Color(0xFFFF6B9D);
      default:
        return Colors.white;
    }
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animação de loading
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            
            // Nome do canal
            Text(
              widget.channel.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Mensagem de loading
            const Text(
              'Conectando ao stream...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress bar
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.surfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Erro ao reproduzir',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              _error ?? 'Erro desconhecido',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                      color: AppTheme.textMuted.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _initializePlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
