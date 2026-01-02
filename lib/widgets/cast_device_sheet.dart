import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cast_service.dart';
import '../services/external_player_service.dart';
import '../theme/app_theme.dart';

/// Widget para exibir o modal de seleção de dispositivos de cast
class CastDeviceSheet extends StatefulWidget {
  final String? mediaUrl;
  final String? mediaTitle;
  final String? thumbnailUrl;

  const CastDeviceSheet({
    super.key,
    this.mediaUrl,
    this.mediaTitle,
    this.thumbnailUrl,
  });

  /// Exibe o bottom sheet de cast
  static Future<void> show(
    BuildContext context, {
    String? mediaUrl,
    String? mediaTitle,
    String? thumbnailUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CastDeviceSheet(
        mediaUrl: mediaUrl,
        mediaTitle: mediaTitle,
        thumbnailUrl: thumbnailUrl,
      ),
    );
  }

  @override
  State<CastDeviceSheet> createState() => _CastDeviceSheetState();
}

class _CastDeviceSheetState extends State<CastDeviceSheet> with SingleTickerProviderStateMixin {
  final CastService _castService = CastService();
  bool _isConnecting = false;
  String? _connectingDeviceId;
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    // Inicia busca de dispositivos automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _castService.startDiscovery();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _castService,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedTab == 0 ? Icons.cast_rounded : Icons.open_in_new_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTab == 0 ? 'Transmitir para TV' : 'Abrir em App Externo',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _selectedTab == 0
                                ? (_castService.isConnected
                                    ? 'Conectado a ${_castService.connectedDevice?.name}'
                                    : 'Selecione um dispositivo')
                                : 'Escolha um player',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedTab == 0)
                      if (_castService.isScanning)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => _castService.startDiscovery(),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          tooltip: 'Buscar novamente',
                        ),
                  ],
                ),
              ),
              
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cast_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Cast/TV'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('App Externo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Cast/TV
                    _castService.isConnected
                        ? _buildConnectedView()
                        : _buildDeviceList(),
                    // Tab 2: External Players
                    _buildExternalPlayersList(),
                  ],
                ),
              ),
              
              // Espaço para safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status da conexão
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tv_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _castService.connectedDevice?.name ?? 'TV',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getConnectionStatusText(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildConnectionStateIcon(),
              ],
            ),
          ),
          
          // Mídia atual (se houver)
          if (_castService.currentMediaTitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reproduzindo agora',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          _castService.currentMediaTitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Controles de reprodução
          if (_castService.connectionState == CastConnectionState.playing ||
              _castService.connectionState == CastConnectionState.paused)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _castService.stop(),
                  icon: const Icon(Icons.stop_rounded),
                  iconSize: 32,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (_castService.connectionState == CastConnectionState.playing) {
                        _castService.pause();
                      } else {
                        _castService.resume();
                      }
                    },
                    icon: Icon(
                      _castService.connectionState == CastConnectionState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    iconSize: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Botão de transmitir mídia atual (se não estiver reproduzindo)
          if (widget.mediaUrl != null && 
              _castService.connectionState == CastConnectionState.connected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _castService.playMedia(
                    url: widget.mediaUrl!,
                    title: widget.mediaTitle ?? 'Vídeo',
                    thumbnailUrl: widget.thumbnailUrl,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cast_rounded),
                label: const Text(
                  'Transmitir este vídeo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Botão de desconectar
          TextButton.icon(
            onPressed: () {
              _castService.disconnect();
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
            ),
            label: const Text('Desconectar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStateIcon() {
    switch (_castService.connectionState) {
      case CastConnectionState.playing:
        return const Icon(
          Icons.play_arrow_rounded,
          color: Colors.green,
          size: 28,
        );
      case CastConnectionState.paused:
        return const Icon(
          Icons.pause_rounded,
          color: Colors.orange,
          size: 28,
        );
      case CastConnectionState.buffering:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        );
      default:
        return const Icon(
          Icons.cast_connected_rounded,
          color: AppTheme.primaryColor,
          size: 28,
        );
    }
  }

  String _getConnectionStatusText() {
    switch (_castService.connectionState) {
      case CastConnectionState.playing:
        return 'Reproduzindo';
      case CastConnectionState.paused:
        return 'Pausado';
      case CastConnectionState.buffering:
        return 'Carregando...';
      case CastConnectionState.connected:
        return 'Conectado';
      default:
        return 'Conectado';
    }
  }

  Widget _buildDeviceList() {
    if (_castService.error != null) {
      return _buildErrorState();
    }

    if (_castService.availableDevices.isEmpty) {
      if (_castService.isScanning) {
        return _buildScanningState();
      }
      return _buildEmptyState();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _castService.availableDevices.length,
        itemBuilder: (context, index) {
          final device = _castService.availableDevices[index];
          final isConnecting = _isConnecting && _connectingDeviceId == device.id;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDeviceIcon(device.type),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              device.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              _getDeviceTypeName(device.type),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
            onTap: isConnecting
                ? null
                : () => _connectToDevice(device),
          );
        },
      ),
    );
  }

  Widget _buildExternalPlayersList() {
    final players = ExternalPlayerService.availablePlayers;
    
    if (widget.mediaUrl == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: AppTheme.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum vídeo selecionado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um vídeo no player\npara abrir em app externo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Lista de players externos
        ...players.map((player) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: player.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              player.icon,
              color: player.color,
              size: 24,
            ),
          ),
          title: Text(
            player.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            player.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          trailing: const Icon(
            Icons.open_in_new_rounded,
            color: AppTheme.textMuted,
            size: 20,
          ),
          onTap: () async {
            final result = await ExternalPlayerService.openInPlayer(
              player: player,
              videoUrl: widget.mediaUrl!,
              title: widget.mediaTitle,
            );
            
            if (!result && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    player.id == 'default' 
                        ? 'Nenhum app disponível para abrir o vídeo'
                        : '${player.name} não está instalado',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  action: player.id != 'default' ? SnackBarAction(
                    label: 'Usar outro',
                    textColor: Colors.white,
                    onPressed: () {},
                  ) : null,
                ),
              );
            } else if (mounted) {
              Navigator.pop(context);
            }
          },
        )),
        
        const Divider(
          color: AppTheme.textMuted,
          indent: 20,
          endIndent: 20,
        ),
        
        // Opção para copiar URL
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_copy_rounded,
              color: AppTheme.textMuted,
              size: 24,
            ),
          ),
          title: const Text(
            'Copiar URL',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: const Text(
            'Copiar link do vídeo para área de transferência',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.mediaUrl!));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copiada para área de transferência'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple animado
                ...List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 1500 + (index * 500)),
                    builder: (context, value, child) {
                      return Container(
                        width: 60 + (value * 40),
                        height: 60 + (value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(
                              (1 - value) * 0.5,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Ícone central
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Buscando dispositivos...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Certifique-se que sua TV está ligada\ne conectada à mesma rede WiFi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tv_off_rounded,
              color: AppTheme.textMuted,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum dispositivo encontrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique se sua Smart TV ou Chromecast\nestá ligado e na mesma rede WiFi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _castService.startDiscovery(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Buscar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Erro na busca',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _castService.error ?? 'Erro desconhecido',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _castService.startDiscovery(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(CastDeviceType type) {
    switch (type) {
      case CastDeviceType.chromecast:
        return Icons.cast_rounded;
      case CastDeviceType.dlna:
        return Icons.tv_rounded;
      case CastDeviceType.airplay:
        return Icons.airplay_rounded;
      case CastDeviceType.smartTv:
        return Icons.connected_tv_rounded;
    }
  }

  String _getDeviceTypeName(CastDeviceType type) {
    switch (type) {
      case CastDeviceType.chromecast:
        return 'Google Chromecast';
      case CastDeviceType.dlna:
        return 'DLNA/Smart TV';
      case CastDeviceType.airplay:
        return 'Apple AirPlay';
      case CastDeviceType.smartTv:
        return 'Smart TV';
    }
  }

  Future<void> _connectToDevice(CastDeviceInfo device) async {
    setState(() {
      _isConnecting = true;
      _connectingDeviceId = device.id;
    });

    final success = await _castService.connectToDevice(device);

    setState(() {
      _isConnecting = false;
      _connectingDeviceId = null;
    });

    if (success && mounted) {
      // Se tiver mídia, pergunta se quer transmitir
      if (widget.mediaUrl != null) {
        final shouldPlay = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Transmitir agora?',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              'Deseja transmitir "${widget.mediaTitle}" para ${device.name}?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Não agora'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Transmitir'),
              ),
            ],
          ),
        );

        if (shouldPlay == true) {
          _castService.playMedia(
            url: widget.mediaUrl!,
            title: widget.mediaTitle ?? 'Vídeo',
            thumbnailUrl: widget.thumbnailUrl,
          );
        }
      }
    }
  }
}

/// Botão de cast para usar no player
class CastButton extends StatelessWidget {
  final String? mediaUrl;
  final String? mediaTitle;
  final String? thumbnailUrl;
  final Color? color;
  final double? size;

  const CastButton({
    super.key,
    this.mediaUrl,
    this.mediaTitle,
    this.thumbnailUrl,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final castService = CastService();

    return ListenableBuilder(
      listenable: castService,
      builder: (context, _) {
        final isConnected = castService.isConnected;

        return IconButton(
          onPressed: () {
            CastDeviceSheet.show(
              context,
              mediaUrl: mediaUrl,
              mediaTitle: mediaTitle,
              thumbnailUrl: thumbnailUrl,
            );
          },
          icon: Icon(
            isConnected ? Icons.cast_connected_rounded : Icons.cast_rounded,
            color: isConnected ? AppTheme.primaryColor : (color ?? Colors.white),
            size: size ?? 24,
          ),
          tooltip: isConnected ? 'Conectado - Toque para controlar' : 'Transmitir para TV',
        );
      },
    );
  }
}
