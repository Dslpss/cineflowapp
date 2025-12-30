import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card com efeito glassmorphism
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AppTheme.borderRadiusMedium,
    this.blur = 10,
    this.borderColor,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient ?? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Card animado com hover effect
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.borderRadiusMedium,
    this.gradient,
    this.boxShadow,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.boxShadow ?? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(_isPressed ? 0.3 : 0.1),
                    blurRadius: _isPressed ? 30 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Badge de qualidade
class QualityBadge extends StatelessWidget {
  final String quality;
  final double fontSize;

  const QualityBadge({
    super.key,
    required this.quality,
    this.fontSize = 10,
  });

  Color get _color {
    switch (quality.toUpperCase()) {
      case '4K':
        return const Color(0xFFFFD700);
      case 'FHD':
        return const Color(0xFF00FF87);
      case 'HD':
        return const Color(0xFF00D9FF);
      case 'SD':
        return const Color(0xFFFF6B9D);
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (quality.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        quality,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = AppTheme.borderRadiusMedium,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF1A1A24),
                Color(0xFF2A2A34),
                Color(0xFF1A1A24),
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Botão com gradiente
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.width,
    this.height,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 56,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Search bar customizada
class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Buscar canais...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.7)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textMuted,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
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
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
