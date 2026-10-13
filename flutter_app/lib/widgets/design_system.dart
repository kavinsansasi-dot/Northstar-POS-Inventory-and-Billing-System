import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hovered = _hovered && !reduceMotion;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: hovered ? 28 : 24,
              offset: Offset(0, hovered ? 7 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.positive = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final bool positive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (loading)
                  const ShimmerSkeleton(width: 108, height: 24)
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (trend != null) ...[
                  const SizedBox(height: 8),
                  _TrendBadge(text: trend!, positive: positive),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = positive ? palette.accent : palette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const ShimmerSkeleton(width: 18, height: 18, borderRadius: 9)
          : Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.tune, size: 18),
      label: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.delete_outline,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: palette.danger,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const ShimmerSkeleton(width: 18, height: 18, borderRadius: 9)
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.autofillHints,
    this.textInputAction,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    obscureText: obscureText,
    onChanged: onChanged,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon:
          suffixIcon ??
          (controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear $label',
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null),
    ),
  );
}

class SearchBarField extends StatelessWidget {
  const SearchBarField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: controller.clear,
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

enum ProductStatus { inStock, lowStock, outOfStock }

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final ProductStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (label, color, icon) = switch (status) {
      ProductStatus.inStock => ('In stock', palette.accent, Icons.check_circle),
      ProductStatus.lowStock => (
        'Low stock',
        palette.warning,
        Icons.warning_amber_rounded,
      ),
      ProductStatus.outOfStock => (
        'Out of stock',
        palette.danger,
        Icons.remove_circle_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ProductStatus.lowStock)
            PulseDot(color: color, size: 14)
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: palette.primary, size: 28),
            ),
            if (title != null) ...[
              const SizedBox(height: 18),
              Text(title!, style: Theme.of(context).textTheme.titleLarge),
            ],
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.border,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _controller.value, 0),
            end: Alignment(1 + 2 * _controller.value, 0),
            colors: [palette.border, palette.surface, palette.border],
          ),
        ),
      ),
    );
  }
}

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.minWidth = 720,
    super.key,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 72,
        horizontalMargin: 20,
        columnSpacing: 24,
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border.all(color: context.palette.border),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        headingTextStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        dataTextStyle: Theme.of(context).textTheme.bodyMedium,
        headingRowColor: WidgetStatePropertyAll(
          context.palette.background.withValues(alpha: 0.65),
        ),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? context.palette.primarySoft.withValues(alpha: 0.45)
              : null,
        ),
        rows: rows,
        columns: columns,
      ),
    ),
  );
}

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    super.key,
  });

  final double value;
  final String Function(double value) formatter;
  final Duration duration;
  final TextStyle? style;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    final wasReduced = _reduceMotion == true;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (wasReduced) {
      _animateTo(widget.value);
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _reduceMotion != true) {
      _animateTo(widget.value);
    }
  }

  void _animateTo(double value) {
    final current = _animation.value;
    _controller
      ..duration = widget.duration
      ..reset();
    _animation = Tween<double>(
      begin: current,
      end: value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.formatter(widget.value), style: widget.style);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) =>
          Text(widget.formatter(_animation.value), style: widget.style),
    );
  }
}

class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.accent;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0.75, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, color: color, size: size * 0.58),
      ),
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({
    required this.child,
    this.onTap,
    this.borderRadius = AppRadii.card,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final lifted = _hovered && !reduceMotion;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: lifted
              ? [
                  BoxShadow(
                    color: context.palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({this.color, this.size = 8, super.key});

  final Color? color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final color = widget.color ?? context.palette.warning;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = reduceMotion ? 0.0 : _controller.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18 + pulse * 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.isDestructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: isDestructive
            ? FilledButton.styleFrom(backgroundColor: context.palette.danger)
            : null,
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(confirmLabel),
      ),
    ],
  );
}

void showAppToast(
  BuildContext context, {
  required String message,
  bool isError = false,
}) => AppToast.show(context, message: message, isError: isError);

class AppToast {
  const AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final palette = context.palette;
    final color = isError ? palette.danger : palette.accent;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: palette.surface,
          margin: const EdgeInsets.all(AppSpacing.md),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
