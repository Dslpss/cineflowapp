import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import '../services/content_sync_service.dart';
import '../widgets/cast_device_sheet.dart';
import '../theme/app_theme.dart';
import '../providers/channel_provider.dart';

/// Tela de configurações
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _preferredQuality = 'FHD';
  bool _showAdultContent = false;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  void _loadSettings() {
    setState(() {
      _preferredQuality = StorageService.getPreferredQuality();
      _showAdultContent = StorageService.showAdultContent();
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Perfil
            SliverToBoxAdapter(child: _buildProfileCard()),

            // Seção de reprodução
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Reprodução',
                icon: Icons.play_circle_outline_rounded,
                children: [
                  _buildQualitySelector(),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingSwitch(
                    title: 'Reprodução automática',
                    subtitle: 'Iniciar reprodução ao selecionar',
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),

            // Seção de conteúdo
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Conteúdo',
                icon: Icons.filter_list_rounded,
                children: [
                  _buildSettingSwitch(
                    title: 'Mostrar conteúdo adulto',
                    subtitle: 'Exibir categoria de conteúdo +18',
                    value: _showAdultContent,
                    onChanged: (value) async {
                      await StorageService.setShowAdultContent(value);
                      setState(() {
                        _showAdultContent = value;
                      });

                      // Notifica o provider para atualizar a lista
                      if (mounted) {
                        context
                            .read<ChannelProvider>()
                            .updateAdultContentVisibility();
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingSwitch(
                    title: 'Remover duplicados',
                    subtitle: 'Mostrar apenas canais com melhor qualidade',
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),

            // Seção de Sincronização de Conteúdo
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Sincronização',
                icon: Icons.sync_rounded,
                children: [
                  _buildSyncStatus(),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingAction(
                    title: 'Atualizar conteúdo',
                    subtitle: 'Buscar novos canais e filmes do servidor',
                    icon: Icons.cloud_download_rounded,
                    onTap: () => _syncContent(),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingAction(
                    title: 'Limpar cache de conteúdo',
                    subtitle: 'Remove dados baixados e força novo download',
                    icon: Icons.cached_rounded,
                    onTap: () => _clearContentCache(),
                  ),
                ],
              ),
            ),

            // Seção de Cast/TV
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Transmitir para TV',
                icon: Icons.cast_rounded,
                children: [
                  _buildCastStatus(),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingAction(
                    title: 'Gerenciar dispositivos',
                    subtitle: 'Conectar ou desconectar da TV',
                    icon: Icons.settings_remote_rounded,
                    onTap: () {
                      CastDeviceSheet.show(context);
                    },
                  ),
                ],
              ),
            ),

            // Seção de armazenamento
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Armazenamento',
                icon: Icons.storage_rounded,
                children: [
                  _buildSettingAction(
                    title: 'Limpar histórico',
                    subtitle: 'Remove canais assistidos recentemente',
                    icon: Icons.history_rounded,
                    onTap: () async {
                      await StorageService.clearRecents();
                      _showSnackBar('Histórico limpo com sucesso!');
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingAction(
                    title: 'Limpar todos os dados',
                    subtitle: 'Remove favoritos, histórico e configurações',
                    icon: Icons.delete_forever_rounded,
                    isDestructive: true,
                    onTap: () => _showClearDataDialog(),
                  ),
                ],
              ),
            ),

            // Seção sobre
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Sobre',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildInfoItem('Versão', _appVersion),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildInfoItem('Desenvolvido por', 'CineFlow Team'),
                  const Divider(height: 1, color: AppTheme.surfaceColor),
                  _buildSettingAction(
                    title: 'Licenças de código aberto',
                    subtitle: 'Ver bibliotecas utilizadas',
                    icon: Icons.code_rounded,
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'CineFlow',
                        applicationVersion: _appVersion,
                        applicationLegalese:
                            '© ${DateTime.now().year} CineFlow',
                      );
                    },
                  ),
                ],
              ),
            ),

            // Espaço no final
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF845EC2), Color(0xFF2C73D2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF845EC2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Personalize sua experiência',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuário Premium',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppTheme.secondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Assinatura ativa',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    final qualities = ['SD', 'HD', 'FHD', '4K'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qualidade preferida',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecione a qualidade padrão de reprodução',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children:
                qualities.map((quality) {
                  final isSelected = _preferredQuality == quality;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await StorageService.setPreferredQuality(quality);
                        setState(() {
                          _preferredQuality = quality;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppTheme.primaryGradient : null,
                          color: isSelected ? null : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.transparent
                                    : AppTheme.textMuted.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            quality,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : AppTheme.primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastStatus() {
    final castService = CastService();

    return ListenableBuilder(
      listenable: castService,
      builder: (context, _) {
        final isConnected = castService.isConnected;
        final deviceName = castService.connectedDevice?.name;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isConnected ? Colors.green : AppTheme.primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isConnected
                      ? Icons.cast_connected_rounded
                      : Icons.cast_rounded,
                  size: 20,
                  color: isConnected ? Colors.green : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Conectado' : 'Desconectado',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? 'Transmitindo para $deviceName'
                          : 'Nenhum dispositivo conectado',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'Limpar dados',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            content: const Text(
              'Tem certeza que deseja limpar todos os dados? Esta ação não pode ser desfeita.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await StorageService.clearAll();
                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar('Todos os dados foram limpos!');
                    _loadSettings();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Limpar'),
              ),
            ],
          ),
    );
  }

  // ===== MÉTODOS DE SINCRONIZAÇÃO =====

  Widget _buildSyncStatus() {
    return FutureBuilder<CacheInfo>(
      future: ContentSyncService.getCacheInfo(),
      builder: (context, snapshot) {
        final cacheInfo = snapshot.data;
        final provider = context.watch<ChannelProvider>();

        String statusText;
        String subtitleText;
        IconData statusIcon;
        Color statusColor;

        if (provider.isSyncing) {
          statusText = 'Sincronizando...';
          subtitleText = 'Buscando novos conteúdos';
          statusIcon = Icons.sync;
          statusColor = AppTheme.secondaryColor;
        } else if (cacheInfo?.hasCache == true) {
          statusText = 'Conteúdo atualizado';
          subtitleText =
              'Última sincronização: ${cacheInfo!.lastSyncFormatted}';
          statusIcon = Icons.cloud_done_rounded;
          statusColor = Colors.green;
        } else {
          statusText = 'Usando conteúdo local';
          subtitleText = 'Nenhuma sincronização realizada';
          statusIcon = Icons.cloud_off_rounded;
          statusColor = AppTheme.textMuted;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    provider.isSyncing
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        )
                        : Icon(statusIcon, size: 20, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (cacheInfo?.version.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${cacheInfo!.version}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncContent() async {
    final provider = context.read<ChannelProvider>();

    if (provider.isSyncing) {
      _showSnackBar('Sincronização já em andamento...');
      return;
    }

    _showSnackBar('Iniciando sincronização...');

    final result = await provider.refreshContent();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor:
              result.success
                  ? Colors.green.withOpacity(0.9)
                  : Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Força rebuild para atualizar o status
      setState(() {});
    }
  }

  Future<void> _clearContentCache() async {
    final provider = context.read<ChannelProvider>();

    await provider.clearContentCache();

    if (mounted) {
      setState(() {});
      _showSnackBar('Cache de conteúdo limpo!');
    }
  }
}
