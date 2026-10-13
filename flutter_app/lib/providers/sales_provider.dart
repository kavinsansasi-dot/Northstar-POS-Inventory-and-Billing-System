import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sale_service.dart';

final salesProvider = FutureProvider.family<SalesPage, SalesFilter>(
  (ref, filter) => ref
      .watch(saleServiceProvider)
      .getSales(
        startDate: filter.startDate,
        endDate: filter.endDate,
        page: filter.page,
      ),
);

class SalesFilter {
  const SalesFilter({this.startDate, this.endDate, this.page = 1});

  final DateTime? startDate;
  final DateTime? endDate;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is SalesFilter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.page == page;

  @override
  int get hashCode => Object.hash(startDate, endDate, page);
}
