import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// Tela de Perfil do usuário
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F18),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<app_auth.AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user;
              
              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                  
                  // Avatar e info do usuário
                  SliverToBoxAdapter(
                    child: _buildUserInfo(user),
                  ),
                  
                  // Estatísticas
                  SliverToBoxAdapter(
                    child: _buildStats(),
                  ),
                  
                  // Menu de opções
                  SliverToBoxAdapter(
                    child: _buildMenuSection(context, auth),
                  ),
                  
                  // Espaço no final
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          const Text(
            'Meu Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User? user) {
    final displayName = user?.displayName ?? 'Usuário';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 48,
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
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          
          const SizedBox(height: 20),
          
          // Nome
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Email
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Badge Premium (opcional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF87).withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Membro Premium',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('12', 'Favoritos', Icons.favorite_rounded, AppTheme.accentColor),
            _buildDivider(),
            _buildStatItem('47', 'Assistidos', Icons.play_circle_rounded, AppTheme.primaryColor),
            _buildDivider(),
            _buildStatItem('8h', 'Tempo', Icons.timer_rounded, AppTheme.secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppTheme.textMuted.withOpacity(0.2),
    );
  }

  Widget _buildMenuSection(BuildContext context, app_auth.AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Configurações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Editar Perfil',
            subtitle: 'Alterar nome e foto',
            color: AppTheme.primaryColor,
            onTap: () {
              // TODO: Implementar edição de perfil
            },
          ),
          
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Gerenciar alertas',
            color: AppTheme.secondaryColor,
            onTap: () {},
          ),
          
          _buildMenuItem(
            icon: Icons.download_outlined,
            title: 'Downloads',
            subtitle: 'Conteúdo offline',
            color: const Color(0xFF00FF87),
            onTap: () {},
          ),
          
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Ajuda',
            subtitle: 'Central de suporte',
            color: Colors.orange,
            onTap: () {},
          ),
          
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Sobre',
            subtitle: 'Versão 1.0.0',
            color: AppTheme.textMuted,
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Botão de Logout
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // Confirmação
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Sair da conta',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: const Text(
                      'Tem certeza que deseja sair?',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Sair',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    'Sair da Conta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
