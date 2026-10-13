import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _DampedShakeCurve extends Curve {
  const _DampedShakeCurve();

  @override
  double transformInternal(double t) => sin(t * 3 * 2 * pi) * (1 - t);
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _keepMeSignedIn = true;

  late final AnimationController _formAnimController;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  late final AnimationController _featureAnimController;
  late final AnimationController _circleController;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _formFade = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOut,
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _featureAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: const _DampedShakeCurve(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _formAnimController.value = 1.0;
      _featureAnimController.value = 1.0;
      _circleController.stop();
    } else {
      if (!_formAnimController.isAnimating && _formAnimController.value == 0) {
        _formAnimController.forward();
      }
      if (!_featureAnimController.isAnimating &&
          _featureAnimController.value == 0) {
        _featureAnimController.forward();
      }
      if (!_circleController.isAnimating) {
        _circleController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _formAnimController.dispose();
    _featureAnimController.dispose();
    _circleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;

    if (!success) {
      final err = ref.read(authProvider).error ?? 'Invalid email or password.';
      setState(() {
        _loading = false;
        _error = err;
      });

      if (!MediaQuery.disableAnimationsOf(context)) {
        _shakeController.forward(from: 0.0);
      }

      final palette = context.palette;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: palette.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_keepMeSignedIn) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(authTokenKey);
      if (token != null && token.isNotEmpty) {
        ref.read(apiServiceProvider).dio.options.headers['Authorization'] =
            'Bearer $token';
      }
      await prefs.remove(authTokenKey);
      await prefs.remove(authUserKey);
    }

    if (!mounted) return;

    setState(() => _loading = false);

    final isAdmin = ref.read(authProvider).user?.isAdmin == true;
    context.go(isAdmin ? '/dashboard' : '/billing');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSplitScreen = constraints.maxWidth >= 900;

          if (isSplitScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.45,
                  child: _BrandPanel(
                    palette: palette,
                    circleController: _circleController,
                    featureAnimController: _featureAnimController,
                    screenWidth: constraints.maxWidth,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: palette.surface,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 40,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _buildFormCard(context, palette),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile / Tablet layout (< 900px)
          return Column(
            children: [
              _MobileBrandHeader(palette: palette),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildFormCard(context, palette),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, AppPalette palette) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeAnimation.value;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _formAnimController,
        builder: (context, child) {
          return Transform.translate(
            offset: _formSlide.value,
            child: Opacity(
              opacity: _formFade.value,
              child: child,
            ),
          );
        },
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your store',
                style: GoogleFonts.plusJakartaSans(
                  color: palette.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your details to continue to Northstar.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your email.';
                  }
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(value.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 16),
              _AuthTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                suffix: TextButton(
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(
                    _obscurePassword ? 'Show' : 'Hide',
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : null,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _keepMeSignedIn,
                      onChanged: (v) => setState(
                        () => _keepMeSignedIn = v ?? true,
                      ),
                      activeColor: palette.primary,
                      checkColor: palette.brandOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: palette.border, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _keepMeSignedIn = !_keepMeSignedIn,
                      ),
                      child: Text(
                        'Keep me signed in',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.danger.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: palette.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: palette.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _PrimaryButton(
                label: 'Sign in',
                loading: _loading,
                onPressed: _submit,
                palette: palette,
              ),
              const SizedBox(height: 24),
              Text(
                'Need help? Contact your store admin.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.palette,
    required this.circleController,
    required this.featureAnimController,
    required this.screenWidth,
  });

  final AppPalette palette;
  final AnimationController circleController;
  final AnimationController featureAnimController;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final headlineSize = screenWidth >= 1200 ? 56.0 : 42.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.brandGradientStart,
            palette.brandGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridTexturePainter(
                lineColor: palette.brandOnPrimary.withValues(alpha: 0.045),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: circleController,
            builder: (context, _) {
              final value = circleController.value;
              final dy1 = sin(value * 2 * pi) * 14;
              final dx1 = cos(value * 2 * pi) * 12;
              final dy2 = -cos(value * 2 * pi) * 14;
              final dx2 = -sin(value * 2 * pi) * 10;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + dy1,
                    right: -40 + dx1,
                    child: _TranslucentCircle(
                      size: 340,
                      color: palette.brandOnPrimary.withValues(alpha: 0.09),
                    ),
                  ),
                  Positioned(
                    bottom: 40 + dy2,
                    left: -60 + dx2,
                    child: _TranslucentCircle(
                      size: 280,
                      color: palette.brandAccentLight.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              );
            },
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandLogoTile(palette: palette),
                const SizedBox(height: 36),
                _PillBadge(palette: palette),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headlineSize,
                      height: 64 / 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'Run your store.\n',
                        style: TextStyle(color: palette.brandOnPrimary),
                      ),
                      TextSpan(
                        text: 'Know every number.',
                        style: TextStyle(color: palette.brandAccentLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Billing, stock and daily insights, everything your shop needs, '
                  'together in one simple place.',
                  style: TextStyle(
                    color: palette.brandOnPrimary.withValues(alpha: 0.82),
                    fontSize: 15.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: featureAnimController,
                  builder: (context, _) {
                    final p = featureAnimController.value;
                    final row1Progress = (p / 0.65).clamp(0.0, 1.0);
                    final row2Progress = ((p - 0.16) / 0.66).clamp(0.0, 1.0);
                    final row3Progress = ((p - 0.32) / 0.68).clamp(0.0, 1.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureRow(
                          icon: Icons.point_of_sale_rounded,
                          title: 'Faster checkout',
                          subtitle: 'Quick billing with cash, card and UPI',
                          palette: palette,
                          opacity: row1Progress,
                          translateY: (1 - row1Progress) * 10,
                        ),
                        const SizedBox(height: 20),
                        _FeatureRow(
                          icon: Icons.inventory_2_outlined,
                          title: 'Smarter inventory',
                          subtitle:
                              "Know what's selling and what's running low",
                          palette: palette,
                          opacity: row2Progress,
                          translateY: (1 - row2Progress) * 10,
                        ),
                        const SizedBox(height: 20),
                        _FeatureRow(
                          icon: Icons.trending_up_rounded,
                          title: 'Clear insights',
                          subtitle:
                              'Understand sales, profit and growth at a glance',
                          palette: palette,
                          opacity: row3Progress,
                          translateY: (1 - row3Progress) * 10,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.brandGradientStart,
            palette.brandGradientEnd,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.brandOnPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'N',
                style: GoogleFonts.plusJakartaSans(
                  color: palette.brandGradientStart,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Northstar',
                  style: GoogleFonts.plusJakartaSans(
                    color: palette.brandOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'POINT OF SALE',
                  style: TextStyle(
                    color: palette.brandAccentLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoTile extends StatelessWidget {
  const _BrandLogoTile({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.brandOnPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'N',
              style: GoogleFonts.plusJakartaSans(
                color: palette.brandGradientStart,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Northstar',
              style: GoogleFonts.plusJakartaSans(
                color: palette.brandOnPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'POINT OF SALE',
              style: TextStyle(
                color: palette.brandAccentLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: palette.brandOnPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: palette.brandOnPrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.65),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Built for growing local businesses',
              style: TextStyle(
                color: palette.brandOnPrimary.withValues(alpha: 0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.opacity,
    required this.translateY,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppPalette palette;
  final double opacity;
  final double translateY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Opacity(
        opacity: opacity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.brandOnPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.brandOnPrimary.withValues(alpha: 0.14),
                ),
              ),
              child: Icon(
                icon,
                color: palette.brandOnPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.brandOnPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.brandAccentLight.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? hint;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          autofocus: autofocus,
          autofillHints: autofillHints,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: palette.textSecondary.withValues(alpha: 0.65),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: palette.textSecondary,
              size: 20,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: palette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.palette,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.brandOnPrimary,
          disabledBackgroundColor: palette.primary.withValues(alpha: 0.7),
          disabledForegroundColor: palette.brandOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    palette.brandOnPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.brandOnPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: palette.brandOnPrimary,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TranslucentCircle extends StatelessWidget {
  const _TranslucentCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _GridTexturePainter extends CustomPainter {
  const _GridTexturePainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.75;

    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridTexturePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
