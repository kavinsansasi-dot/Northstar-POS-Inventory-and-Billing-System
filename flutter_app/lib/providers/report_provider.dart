import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reports.dart';
import '../services/report_service.dart';

final dailyReportProvider = FutureProvider<DailyReport>(
  (ref) => ref.watch(reportServiceProvider).getDailyReport(),
);
final yesterdayReportProvider = FutureProvider<TrendTotals>(
  (ref) => ref.watch(reportServiceProvider).getYesterdayReport(),
);
final lowStockProvider = FutureProvider<List<LowStockProduct>>(
  (ref) => ref.watch(reportServiceProvider).getLowStockProducts(),
);
final weeklySalesProvider = FutureProvider<List<WeeklySalesDay>>(
  (ref) => ref.watch(reportServiceProvider).getWeeklySales(),
);
final monthlySalesProvider = FutureProvider<List<MonthlySalesDay>>(
  (ref) => ref.watch(reportServiceProvider).getMonthlySales(),
);
final recentSalesProvider = FutureProvider<List<RecentSale>>(
  (ref) => ref.watch(reportServiceProvider).getRecentSales(),
);
