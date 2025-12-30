import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _preferredQuality = StorageService.getPreferredQuality();
      _showAdultContent = StorageService.showAdultContent();
    });
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
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // Perfil
              SliverToBoxAdapter(
                child: _buildProfileCard(),
              ),
              
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
                          context.read<ChannelProvider>().updateAdultContentVisibility();
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
                    _buildInfoItem('Versão', '1.0.0'),
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
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Espaço no final
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
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
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
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
              border: Border.all(
                color: AppTheme.textMuted.withOpacity(0.1),
              ),
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
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: qualities.map((quality) {
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
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
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
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
