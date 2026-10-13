import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reports.dart';
import 'api_service.dart';

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.read(apiServiceProvider)),
);

class ReportService {
  ReportService(this._api);
  final ApiService _api;

  Future<DailyReport> getDailyReport() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/reports/daily');
    return DailyReport.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Returns totals for yesterday — used for trend badges.
  Future<TrendTotals> getYesterdayReport() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/reports/yesterday',
    );
    return TrendTotals.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<LowStockProduct>> getLowStockProducts() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/reports/low-stock',
    );
    return (response.data?['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LowStockProduct.fromJson)
        .toList();
  }

  Future<List<WeeklySalesDay>> getWeeklySales() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/reports/weekly',
    );
    return (response.data?['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WeeklySalesDay.fromJson)
        .toList();
  }

  /// Returns the last 30 days of daily sales totals for the chart toggle.
  Future<List<MonthlySalesDay>> getMonthlySales() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/reports/monthly',
    );
    return (response.data?['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MonthlySalesDay.fromJson)
        .toList();
  }

  /// Returns the most recent [limit] sales for the dashboard table.
  Future<List<RecentSale>> getRecentSales({int limit = 8}) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/reports/recent-sales',
      queryParameters: {'limit': limit},
    );
    return (response.data?['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RecentSale.fromJson)
        .toList();
  }
}
