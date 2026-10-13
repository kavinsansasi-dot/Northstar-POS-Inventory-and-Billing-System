// ignore_for_file: avoid_redundant_argument_values
import 'dart:math' show pi, sin, cos;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/reports.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kIndigo900 = Color(0xFF312E81);
const _kIndigo600 = Color(0xFF4F46E5);
const _kViolet500 = Color(0xFF8B5CF6);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFF43F5E);

String _formatAmount(double value) {
  if (value >= 1000000) {
    return '$kCurrency ${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '$kCurrency ${(value / 1000).toStringAsFixed(1)}K';
  }
  return '$kCurrency ${value.toStringAsFixed(0)}';
}

String _formatFull(double value) =>
    '$kCurrency ${NumberFormat('#,##0.00').format(value)}';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'GOOD MORNING';
  if (hour < 17) return 'GOOD AFTERNOON';
  return 'GOOD EVENING';
}

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _lowStockKey = GlobalKey();
  late final AnimationController _heroCircleCtrl;

  @override
  void initState() {
    super.initState();
    _heroCircleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (!_heroCircleCtrl.isAnimating) _heroCircleCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _heroCircleCtrl.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref
      ..invalidate(dailyReportProvider)
      ..invalidate(yesterdayReportProvider)
      ..invalidate(lowStockProvider)
      ..invalidate(weeklySalesProvider)
      ..invalidate(monthlySalesProvider)
      ..invalidate(recentSalesProvider);
  }

  void _scrollToLowStock() {
    final ctx = _lowStockKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    // Cashier guard – router already redirects, but belt-and-suspenders
    if (auth.user?.isAdmin != true) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go('/billing'),
      );
      return const SizedBox.shrink();
    }

    final daily = ref.watch(dailyReportProvider);
    final yesterday = ref.watch(yesterdayReportProvider);
    final weekly = ref.watch(weeklySalesProvider);
    final monthly = ref.watch(monthlySalesProvider);
    final lowStock = ref.watch(lowStockProvider);
    final recent = ref.watch(recentSalesProvider);
    final palette = context.palette;
    final userName = auth.user?.name ?? 'Admin';

    return RefreshIndicator(
      onRefresh: () async => _invalidateAll(),
      color: palette.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HeroStrip(
                circleController: _heroCircleCtrl,
                userName: userName,
                onNewBill: () => context.go('/billing'),
              ),
            ),
          ),
          // ── Stat Cards ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StatCardsRow(
                daily: daily,
                yesterday: yesterday,
                lowStock: lowStock,
                onLowStockTap: _scrollToLowStock,
              ),
            ),
          ),
          // ── Sales Chart ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _SalesChartCard(weekly: weekly, monthly: monthly),
            ),
          ),
          // ── Responsive bottom section ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  if (w >= 1000) {
                    return _wideLayout(daily, recent, lowStock);
                  }
                  if (w >= 700) {
                    return _midLayout(daily, recent, lowStock);
                  }
                  return _narrowLayout(daily, recent, lowStock);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout(
    AsyncValue<DailyReport> daily,
    AsyncValue<List<RecentSale>> recent,
    AsyncValue<List<LowStockProduct>> lowStock,
  ) =>
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _TopProductsCard(
                  daily: daily,
                  onRetry: () => ref.invalidate(dailyReportProvider),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 7,
                child: _RecentSalesCard(
                  recent: recent,
                  onRetry: () => ref.invalidate(recentSalesProvider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LowStockCard(
            key: _lowStockKey,
            lowStock: lowStock,
            onRetry: () => ref.invalidate(lowStockProvider),
          ),
        ],
      );

  Widget _midLayout(
    AsyncValue<DailyReport> daily,
    AsyncValue<List<RecentSale>> recent,
    AsyncValue<List<LowStockProduct>> lowStock,
  ) =>
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TopProductsCard(
                  daily: daily,
                  onRetry: () => ref.invalidate(dailyReportProvider),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LowStockCard(
                  key: _lowStockKey,
                  lowStock: lowStock,
                  onRetry: () => ref.invalidate(lowStockProvider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecentSalesCard(
            recent: recent,
            onRetry: () => ref.invalidate(recentSalesProvider),
          ),
        ],
      );

  Widget _narrowLayout(
    AsyncValue<DailyReport> daily,
    AsyncValue<List<RecentSale>> recent,
    AsyncValue<List<LowStockProduct>> lowStock,
  ) =>
      Column(
        children: [
          _TopProductsCard(
            daily: daily,
            onRetry: () => ref.invalidate(dailyReportProvider),
          ),
          const SizedBox(height: 16),
          _RecentSalesCard(
            recent: recent,
            onRetry: () => ref.invalidate(recentSalesProvider),
          ),
          const SizedBox(height: 16),
          _LowStockCard(
            key: _lowStockKey,
            lowStock: lowStock,
            onRetry: () => ref.invalidate(lowStockProvider),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroStrip
// ─────────────────────────────────────────────────────────────────────────────

class _HeroStrip extends StatelessWidget {
  const _HeroStrip({
    required this.circleController,
    required this.userName,
    required this.onNewBill,
  });

  final AnimationController circleController;
  final String userName;
  final VoidCallback onNewBill;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kIndigo900, _kIndigo600],
          ),
        ),
        child: Stack(
          children: [
            // Grid texture
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // Floating circles
            AnimatedBuilder(
              animation: circleController,
              builder: (context, _) {
                final t = circleController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -40 + sin(t * 2 * pi) * 10,
                      right: -50 + cos(t * 2 * pi) * 8,
                      child: _Circle(
                        size: 220,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    Positioned(
                      bottom: -60 - cos(t * 2 * pi) * 10,
                      left: -30 + sin(t * 2 * pi) * 6,
                      child: _Circle(
                        size: 180,
                        color: const Color(0xFFA5B4FC).withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroText(userName),
                        const SizedBox(height: 12),
                        _newBillBtn(onNewBill),
                        const SizedBox(height: 10),
                        _dateText(dateStr),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _heroText(userName)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _newBillBtn(onNewBill),
                          const SizedBox(height: 10),
                          _dateText(dateStr),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroText(String name) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _greeting(),
        style: GoogleFonts.inter(
          color: const Color(0xFFA5B4FC),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(
        "Here's how Northstar is doing today",
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.70),
          fontSize: 13.5,
        ),
      ),
    ],
  );

  Widget _newBillBtn(VoidCallback onTap) => FilledButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add_rounded, size: 16),
    label: const Text('New bill'),
    style: FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: _kIndigo600,
      textStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(0, 38),
    ),
  );

  Widget _dateText(String date) => Text(
    date,
    style: GoogleFonts.inter(
      color: Colors.white.withValues(alpha: 0.60),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StatCards Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({
    required this.daily,
    required this.yesterday,
    required this.lowStock,
    required this.onLowStockTap,
  });

  final AsyncValue<DailyReport> daily;
  final AsyncValue<TrendTotals> yesterday;
  final AsyncValue<List<LowStockProduct>> lowStock;
  final VoidCallback onLowStockTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final report = daily.asData?.value;
    final prev = yesterday.asData?.value;
    final stock = lowStock.asData?.value;
    final isLoading = daily.isLoading;
    final lowCount = stock?.length ?? 0;

    Widget cards(double cardWidth) => Row(
      children: [
        _StatCard(
          width: cardWidth,
          icon: Icons.payments_outlined,
          label: "Today's Sales",
          value: report == null ? null : _formatFull(report.totalSales),
          trend: _trend(report?.totalSales, prev?.totalSales),
          iconColor: _kIndigo600,
          loading: isLoading,
        ),
        const SizedBox(width: 12),
        _StatCard(
          width: cardWidth,
          icon: Icons.receipt_long_outlined,
          label: 'Bills Today',
          value: report?.numberOfBills.toString(),
          trend: _trend(
            report?.numberOfBills.toDouble(),
            prev?.numberOfBills.toDouble(),
          ),
          iconColor: const Color(0xFF8B5CF6),
          loading: isLoading,
        ),
        const SizedBox(width: 12),
        _StatCard(
          width: cardWidth,
          icon: Icons.trending_up_rounded,
          label: 'Profit',
          value: report == null ? null : _formatFull(report.profit),
          trend: _trend(report?.profit, prev?.profit),
          iconColor: _kGreen,
          loading: isLoading,
        ),
        const SizedBox(width: 12),
        _StatCard(
          width: cardWidth,
          icon: Icons.inventory_2_outlined,
          label: 'Low Stock',
          value: lowCount > 0 ? '$lowCount items' : '0',
          iconColor: lowCount > 0 ? _kAmber : _kGreen,
          loading: lowStock.isLoading,
          onTap: lowCount > 0 ? onLowStockTap : null,
          chipColor: lowCount > 0 ? _kAmber : null,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= 700) {
          final cardWidth = (w - 36) / 4;
          return cards(cardWidth);
        }
        // Narrow: horizontal scroll
        return SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StatCard(
                width: 160,
                icon: Icons.payments_outlined,
                label: "Today's Sales",
                value: report == null ? null : _formatFull(report.totalSales),
                trend: _trend(report?.totalSales, prev?.totalSales),
                iconColor: _kIndigo600,
                loading: isLoading,
              ),
              const SizedBox(width: 12),
              _StatCard(
                width: 150,
                icon: Icons.receipt_long_outlined,
                label: 'Bills Today',
                value: report?.numberOfBills.toString(),
                trend: _trend(
                  report?.numberOfBills.toDouble(),
                  prev?.numberOfBills.toDouble(),
                ),
                iconColor: const Color(0xFF8B5CF6),
                loading: isLoading,
              ),
              const SizedBox(width: 12),
              _StatCard(
                width: 150,
                icon: Icons.trending_up_rounded,
                label: 'Profit',
                value: report == null ? null : _formatFull(report.profit),
                trend: _trend(report?.profit, prev?.profit),
                iconColor: _kGreen,
                loading: isLoading,
              ),
              const SizedBox(width: 12),
              _StatCard(
                width: 140,
                icon: Icons.inventory_2_outlined,
                label: 'Low Stock',
                value: lowCount > 0 ? '$lowCount items' : '0',
                iconColor: lowCount > 0 ? _kAmber : _kGreen,
                loading: lowStock.isLoading,
                onTap: lowCount > 0 ? onLowStockTap : null,
                chipColor: lowCount > 0 ? _kAmber : null,
              ),
            ],
          ),
        );
      },
    );
  }

  _TrendData? _trend(double? today, double? yesterday) {
    if (today == null || yesterday == null || yesterday == 0) return null;
    final pct = ((today - yesterday) / yesterday) * 100;
    return _TrendData(percent: pct, up: pct >= 0);
  }
}

class _TrendData {
  const _TrendData({required this.percent, required this.up});
  final double percent;
  final bool up;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.trend,
    this.loading = false,
    this.onTap,
    this.chipColor,
  });

  final double width;
  final IconData icon;
  final String label;
  final String? value;
  final Color iconColor;
  final _TrendData? trend;
  final bool loading;
  final VoidCallback? onTap;
  final Color? chipColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final card = SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  if (chipColor != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: chipColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              if (loading)
                _ShimmerBlock(width: width * 0.6, height: 20)
              else
                Text(
                  value ?? '—',
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (trend != null) ...[
                const SizedBox(height: 4),
                _TrendBadge(data: trend!),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: card),
      );
    }
    return card
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        )
        .slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.data});
  final _TrendData data;

  @override
  Widget build(BuildContext context) {
    final color = data.up ? _kGreen : _kRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          data.up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          '${data.percent.abs().toStringAsFixed(1)}%',
          style: GoogleFonts.inter(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          'vs yesterday',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.45,
            ),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales Chart Card
// ─────────────────────────────────────────────────────────────────────────────

class _SalesChartCard extends ConsumerStatefulWidget {
  const _SalesChartCard({
    required this.weekly,
    required this.monthly,
  });

  final AsyncValue<List<WeeklySalesDay>> weekly;
  final AsyncValue<List<MonthlySalesDay>> monthly;

  @override
  ConsumerState<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends ConsumerState<_SalesChartCard> {
  bool _show7D = true;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sales · ${_show7D ? 'last 7 days' : 'last 30 days'}',
                    style: GoogleFonts.plusJakartaSans(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ToggleChip(
                  label: '7D',
                  selected: _show7D,
                  onTap: () => setState(() => _show7D = true),
                  palette: palette,
                ),
                const SizedBox(width: 6),
                _ToggleChip(
                  label: '30D',
                  selected: !_show7D,
                  onTap: () => setState(() => _show7D = false),
                  palette: palette,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: _show7D
                  ? widget.weekly.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => _InlineError(
                        message: ApiService.errorMessage(e),
                        onRetry: () => ref.invalidate(weeklySalesProvider),
                      ),
                      data: (days) => _SalesChart(
                        days: days,
                        touchedIndex: _touchedIndex,
                        onTouch: (i) => setState(() => _touchedIndex = i),
                        palette: palette,
                      ),
                    )
                  : widget.monthly.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => _InlineError(
                        message: ApiService.errorMessage(e),
                        onRetry: () => ref.invalidate(monthlySalesProvider),
                      ),
                      data: (days) => _SalesChart(
                        days: days
                            .map(
                              (d) => WeeklySalesDay(
                                date: d.date,
                                totalSales: d.totalSales,
                                numberOfBills: d.numberOfBills,
                              ),
                            )
                            .toList(),
                        touchedIndex: _touchedIndex,
                        onTouch: (i) => setState(() => _touchedIndex = i),
                        palette: palette,
                        compact: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? palette.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? palette.primary : palette.border,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: selected ? palette.primary : palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({
    required this.days,
    required this.touchedIndex,
    required this.onTouch,
    required this.palette,
    this.compact = false,
  });

  final List<WeeklySalesDay> days;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;
  final AppPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Center(
        child: Text(
          'No sales data yet.',
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final maxSales = days.fold<double>(
      0,
      (max, d) => d.totalSales > max ? d.totalSales : max,
    );
    final maxY = maxSales == 0 ? 10.0 : maxSales * 1.30;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.spot == null) {
              onTouch(null);
              return;
            }
            onTouch(response.spot!.touchedBarGroupIndex);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => palette.textPrimary.withValues(alpha: 0.92),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, _, rod, __) {
              final day = days[group.x.toInt()];
              return BarTooltipItem(
                '${DateFormat('d MMM').format(day.date)}\n',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text:
                        '${_formatFull(day.totalSales)}\n${day.numberOfBills} bill${day.numberOfBills == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            _buildBar(i, days[i], todayStr, maxY),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _formatYAxis(value),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: palette.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                final day = days[idx];
                final label = compact
                    ? DateFormat('d').format(day.date)
                    : DateFormat.E().format(day.date);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: palette.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: palette.border.withValues(alpha: 0.6),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  BarChartGroupData _buildBar(
    int index,
    WeeklySalesDay day,
    String todayStr,
    double maxY,
  ) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(day.date) == todayStr;
    final isTouched = touchedIndex == index;
    final barColor = isToday || isTouched ? _kIndigo600 : _kIndigo600;
    final barOpacity = (isTouched || isToday) ? 1.0 : 0.65;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: day.totalSales == 0 ? 0.0 : day.totalSales,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              barColor.withValues(alpha: barOpacity * 0.7),
              _kViolet500.withValues(alpha: barOpacity),
            ],
          ),
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.transparent,
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Products Card
// ─────────────────────────────────────────────────────────────────────────────

class _TopProductsCard extends ConsumerWidget {
  const _TopProductsCard({
    required this.daily,
    required this.onRetry,
  });

  final AsyncValue<DailyReport> daily;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products Today',
              style: GoogleFonts.plusJakartaSans(
                color: palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            daily.when(
              loading: () => Column(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShimmerBlock(
                      width: double.infinity,
                      height: 40,
                    ),
                  ),
                ),
              ),
              error: (e, _) => _InlineError(
                message: ApiService.errorMessage(e),
                onRetry: onRetry,
              ),
              data: (report) {
                final products = report.topProducts.take(5).toList();
                if (products.isEmpty) {
                  return _EmptyState(
                    icon: Icons.storefront_outlined,
                    message: 'No sales yet today',
                    actionLabel: 'Start billing',
                    onAction: () => context.go('/billing'),
                  );
                }
                final maxQty = products.fold<double>(
                  0,
                  (m, p) => p.quantitySold > m ? p.quantitySold : m,
                );
                return Column(
                  children: [
                    for (var i = 0; i < products.length; i++) ...[
                      _RankedRow(
                        rank: i + 1,
                        product: products[i],
                        maxQty: maxQty,
                        palette: palette,
                      ),
                      if (i < products.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 150),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
  }
}



class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.rank,
    required this.product,
    required this.maxQty,
    required this.palette,
  });

  final int rank;
  final TopProduct product;
  final double maxQty;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final progress = maxQty > 0 ? (product.quantitySold / maxQty).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    color: palette.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.name,
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${product.quantitySold.toStringAsFixed(product.quantitySold == product.quantitySold.roundToDouble() ? 0 : 1)} sold',
              style: GoogleFonts.inter(
                color: palette.textSecondary,
                fontSize: 11.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: palette.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              palette.primary.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Sales Card
// ─────────────────────────────────────────────────────────────────────────────

class _RecentSalesCard extends StatelessWidget {
  const _RecentSalesCard({
    required this.recent,
    required this.onRetry,
  });

  final AsyncValue<List<RecentSale>> recent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sales',
              style: GoogleFonts.plusJakartaSans(
                color: palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            recent.when(
              loading: () => Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ShimmerBlock(
                      width: double.infinity,
                      height: 44,
                    ),
                  ),
                ),
              ),
              error: (e, _) => _InlineError(
                message: ApiService.errorMessage(e),
                onRetry: onRetry,
              ),
              data: (sales) {
                if (sales.isEmpty) {
                  return _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No sales recorded yet',
                  );
                }
                return Column(
                  children: [
                    for (final sale in sales)
                      _SaleRow(sale: sale, palette: palette),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
  }
}

class _SaleRow extends StatefulWidget {
  const _SaleRow({required this.sale, required this.palette});
  final RecentSale sale;
  final AppPalette palette;

  @override
  State<_SaleRow> createState() => _SaleRowState();
}

class _SaleRowState extends State<_SaleRow> {
  bool _hovered = false;

  String get _shortInvoice {
    final no = widget.sale.invoiceNo;
    return no.length > 8 ? '#${no.substring(no.length - 6)}' : '#$no';
  }

  Color get _paymentColor {
    switch (widget.sale.paymentType.toLowerCase()) {
      case 'cash':
        return _kGreen;
      case 'card':
        return _kIndigo600;
      case 'upi':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _hovered
              ? palette.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  _shortInvoice,
                  style: GoogleFonts.inter(
                    color: palette.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.sale.customerName ?? 'Walk-in',
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _paymentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.sale.paymentType.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: _paymentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: Text(
                  _formatFull(widget.sale.total),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('h:mm a').format(widget.sale.date),
                style: GoogleFonts.inter(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Low Stock Card
// ─────────────────────────────────────────────────────────────────────────────

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    super.key,
    required this.lowStock,
    required this.onRetry,
  });

  final AsyncValue<List<LowStockProduct>> lowStock;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: lowStock.asData?.value.isNotEmpty == true
              ? _kAmber.withValues(alpha: 0.35)
              : palette.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (lowStock.asData?.value.isNotEmpty == true)
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: _kAmber,
                    size: 18,
                  ),
                if (lowStock.asData?.value.isNotEmpty == true)
                  const SizedBox(width: 6),
                Text(
                  'Low Stock',
                  style: GoogleFonts.plusJakartaSans(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            lowStock.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ShimmerBlock(
                      width: double.infinity,
                      height: 52,
                    ),
                  ),
                ),
              ),
              error: (e, _) => _InlineError(
                message: ApiService.errorMessage(e),
                onRetry: onRetry,
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: _kGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All products are above their minimum stock.',
                        style: GoogleFonts.inter(
                          color: _kGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 700 ? 2 : 1;
                    if (cols == 1) {
                      return Column(
                        children: products
                            .map(
                              (p) => _LowStockRow(
                                product: p,
                                palette: palette,
                              ),
                            )
                            .toList(),
                      );
                    }
                    // Two-column grid
                    final rows = <Widget>[];
                    for (var i = 0; i < products.length; i += 2) {
                      rows.add(
                        Row(
                          children: [
                            Expanded(
                              child: _LowStockRow(
                                product: products[i],
                                palette: palette,
                              ),
                            ),
                            if (i + 1 < products.length) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LowStockRow(
                                  product: products[i + 1],
                                  palette: palette,
                                ),
                              ),
                            ] else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                      if (i + 2 < products.length) {
                        rows.add(const SizedBox(height: 10));
                      }
                    }
                    return Column(children: rows);
                  },
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 250),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
  }
}

class _LowStockRow extends ConsumerWidget {
  const _LowStockRow({required this.product, required this.palette});

  final LowStockProduct product;
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAmber.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: _kAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.stock.toStringAsFixed(0)} remaining · min ${product.minStock.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: palette.textSecondary,
                    fontSize: 11.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              context.go('/products/edit/${product.id}');
            },
            style: TextButton.styleFrom(
              foregroundColor: _kAmber,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 0),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: palette.textSecondary, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.inter(
              color: palette.textSecondary,
              fontSize: 13.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: palette.danger, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              color: palette.textSecondary,
              fontSize: 12.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);
    _anim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final baseColor =
            isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
        final shineColor =
            isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
        final t = _anim.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + t * 3, 0),
              end: Alignment(-0.5 + t * 3, 0),
              colors: [baseColor, shineColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}
