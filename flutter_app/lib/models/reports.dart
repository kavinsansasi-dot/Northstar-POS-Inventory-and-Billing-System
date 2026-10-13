import '../models/sale.dart';

class DailyReport {
  const DailyReport({
    required this.date,
    required this.totalSales,
    required this.numberOfBills,
    required this.topProducts,
    this.profit = 0,
  });

  final String date;
  final double totalSales;
  final int numberOfBills;
  final List<TopProduct> topProducts;
  final double profit;

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    date: json['date'] as String? ?? '',
    totalSales: _number(json['totalSales']),
    numberOfBills: (json['numberOfBills'] as num?)?.toInt() ?? 0,
    topProducts: (json['topProducts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TopProduct.fromJson)
        .toList(),
    profit: _number(json['profit']),
  );
}

/// Minimal totals used for the "yesterday" trend comparison.
class TrendTotals {
  const TrendTotals({
    required this.totalSales,
    required this.numberOfBills,
    required this.profit,
  });

  final double totalSales;
  final int numberOfBills;
  final double profit;

  factory TrendTotals.fromJson(Map<String, dynamic> json) => TrendTotals(
    totalSales: _number(json['totalSales']),
    numberOfBills: (json['numberOfBills'] as num?)?.toInt() ?? 0,
    profit: _number(json['profit']),
  );
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.quantitySold,
    required this.salesAmount,
  });

  final String name;
  final double quantitySold;
  final double salesAmount;

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
    name: json['name'] as String? ?? '',
    quantitySold: _number(json['quantitySold']),
    salesAmount: _number(json['salesAmount']),
  );
}

class LowStockProduct {
  const LowStockProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.stock,
    required this.minStock,
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double stock;
  final double minStock;

  factory LowStockProduct.fromJson(Map<String, dynamic> json) =>
      LowStockProduct(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        category: json['category'] as String? ?? '',
        stock: _number(json['stock']),
        minStock: _number(json['minStock']),
      );
}

class WeeklySalesDay {
  const WeeklySalesDay({
    required this.date,
    required this.totalSales,
    required this.numberOfBills,
  });

  final DateTime date;
  final double totalSales;
  final int numberOfBills;

  factory WeeklySalesDay.fromJson(Map<String, dynamic> json) => WeeklySalesDay(
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    totalSales: _number(json['totalSales']),
    numberOfBills: (json['numberOfBills'] as num?)?.toInt() ?? 0,
  );
}

/// One day in the 30-day monthly series.
class MonthlySalesDay {
  const MonthlySalesDay({
    required this.date,
    required this.totalSales,
    required this.numberOfBills,
  });

  final DateTime date;
  final double totalSales;
  final int numberOfBills;

  factory MonthlySalesDay.fromJson(Map<String, dynamic> json) =>
      MonthlySalesDay(
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        totalSales: _number(json['totalSales']),
        numberOfBills: (json['numberOfBills'] as num?)?.toInt() ?? 0,
      );
}

/// Lightweight recent sale row for the dashboard table.
class RecentSale {
  const RecentSale({
    required this.id,
    required this.invoiceNo,
    required this.total,
    required this.paymentType,
    required this.date,
    this.customerName,
  });

  final String id;
  final String invoiceNo;
  final double total;
  final String paymentType;
  final DateTime date;
  final String? customerName;

  factory RecentSale.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return RecentSale(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      invoiceNo: json['invoiceNo'] as String? ?? '',
      total: _number(json['total']),
      paymentType: json['paymentType'] as String? ?? '',
      date:
          DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      customerName: customer is Map<String, dynamic>
          ? customer['name'] as String?
          : null,
    );
  }

  /// Adapts a full [Sale] to a lightweight [RecentSale].
  factory RecentSale.fromSale(Sale sale) => RecentSale(
    id: sale.id,
    invoiceNo: sale.invoiceNo,
    total: sale.total,
    paymentType: sale.paymentType,
    date: sale.date,
    customerName: sale.customerName,
  );
}

double _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
