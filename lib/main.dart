import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/channel_provider.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'services/app_check_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/series_list_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/update_card.dart';

// Versão atual do app (atualizar a cada release)
const String appVersion = '1.0.0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp();
  
  // Configura a barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Inicializa o serviço de armazenamento
  await StorageService.init();
  
  runApp(const CineFlowApp());
}

class CineFlowApp extends StatelessWidget {
  const CineFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'CineFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Widget que decide se mostra Login ou MainNavigation baseado no estado de auth
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Mostra splash enquanto verifica autenticação
        if (auth.status == AuthStatus.uninitialized) {
          return SplashScreen(
            nextScreen: const MainNavigation(),
          );
        }
        
        // Se autenticado, vai para o app
        if (auth.isAuthenticated) {
          return SplashScreen(
            nextScreen: const MainNavigation(),
          );
        }
        
        // Se não autenticado, vai para login
        return const LoginScreen();
      },
    );
  }
}

/// Navegação principal com bottom bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  
  // Controle de atualização
  bool _showUpdateCard = false;
  AppVersionInfo? _updateInfo;

  final List<Widget> _screens = const [
    HomeScreen(),
    MoviesScreen(),
    SeriesListScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    // Verifica atualizações e status do usuário
    _checkForUpdate();
    _checkUserStatus();
  }
  
  Future<void> _checkUserStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      // Sincroniza dados básicos
      AppCheckService.syncUserData(user);
      
      // Verifica bloqueio
      final status = await AppCheckService.checkUserStatus(user.uid);
      
      if (status.isBlocked && mounted) {
        // Mostra alerta e desloga
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Acesso Bloqueado'),
            content: Text(status.blockedReason.isNotEmpty 
              ? 'Motivo: ${status.blockedReason}' 
              : 'Sua conta foi bloqueada pelo administrador.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authProvider.signOut();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Garante logout se o dialog for fechado de outra forma
        if (authProvider.isAuthenticated) {
          authProvider.signOut();
        }
      }
    }
  }
  
  Future<void> _checkForUpdate() async {
    try {
      final versionInfo = await AppCheckService.checkAppVersion();
      
      // Verifica se a versão atual é menor que a mínima exigida
      if (AppCheckService.isVersionOutdated(appVersion, versionInfo.minVersion)) {
        setState(() {
          _updateInfo = versionInfo;
          _showUpdateCard = true;
        });
        
        // Se for atualização forçada, mostra dialog bloqueante
        if (versionInfo.forceUpdate && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ForceUpdateDialog(versionInfo: versionInfo),
          );
        }
      }
    } catch (e) {
      // Se der erro, ignora e continua normalmente
      debugPrint('Erro ao verificar atualização: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo principal
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          
          // Card de atualização (se houver e não for forçada)
          if (_showUpdateCard && _updateInfo != null && !_updateInfo!.forceUpdate)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: UpdateCard(
                versionInfo: _updateInfo!,
                onDismiss: () {
                  setState(() {
                    _showUpdateCard = false;
                  });
                },
              ),
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppTheme.textMuted.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                iconOutlined: Icons.home_outlined,
                label: 'Início',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.movie_rounded,
                iconOutlined: Icons.movie_outlined,
                label: 'Filmes',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.video_library_rounded,
                iconOutlined: Icons.video_library_outlined,
                label: 'Séries',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.favorite_rounded,
                iconOutlined: Icons.favorite_outline_rounded,
                label: 'Favoritos',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                iconOutlined: Icons.settings_outlined,
                label: 'Config',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData iconOutlined,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? icon : iconOutlined,
                key: ValueKey(isSelected),
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const SearchScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.search_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
