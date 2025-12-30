import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../main.dart';

/// Tela de Cadastro premium
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showErrorSnackBar('Você precisa aceitar os termos de uso');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } else if (mounted && authProvider.error != null) {
      _showErrorSnackBar(authProvider.error!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F18),
              AppTheme.backgroundColor,
              const Color(0xFF0A1F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botão voltar
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
                      
                      const SizedBox(height: 24),
                      
                      // Logo pequeno
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.neonGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF87).withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Título
                      const Center(
                        child: Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Junte-se ao CineFlow',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Campo Nome
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: _buildInputDecoration(
                          label: 'Nome',
                          hint: 'Seu nome completo',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite seu nome';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: _buildInputDecoration(
                          label: 'Email',
                          hint: 'seu@email.com',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite seu email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: _buildInputDecoration(
                          label: 'Senha',
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite uma senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo Confirmar Senha
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: _buildInputDecoration(
                          label: 'Confirmar Senha',
                          hint: 'Digite a senha novamente',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme sua senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Checkbox de termos
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() => _agreedToTerms = value ?? false);
                              },
                              activeColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                                children: [
                                  const TextSpan(text: 'Eu concordo com os '),
                                  TextSpan(
                                    text: 'Termos de Uso',
                                    style: TextStyle(
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' e '),
                                  TextSpan(
                                    text: 'Política de Privacidade',
                                    style: TextStyle(
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botão de Cadastro
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: auth.isLoading
                                      ? null
                                      : AppTheme.neonGradient,
                                  color: auth.isLoading
                                      ? AppTheme.surfaceColor
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: auth.isLoading
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF00FF87).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.textMuted,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person_add_rounded, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text(
                                              'Criar Conta',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Link para login
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Já tem uma conta? ',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Entrar',
                                style: TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppTheme.textMuted),
      hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppTheme.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00FF87), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
