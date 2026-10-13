import 'package:flutter/foundation.dart';

const String baseUrl = kIsWeb
    ? 'http://localhost:5000'
    : 'http://10.0.2.2:5000';

const String authTokenKey = 'pos_auth_token';
const String authUserKey = 'pos_auth_user';

const String kCurrency = 'Rs.';

class ShopInfo {
  const ShopInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.footerNote,
    this.logoAsset,
  });

  final String name;
  final String address;
  final String phone;
  final String footerNote;
  final String? logoAsset;
}

const ShopInfo kShopInfo = ShopInfo(
  name: 'Northstar Retail',
  address: '12 Main Street, Colombo',
  phone: '+94 77 123 4567',
  footerNote: 'Returns accepted within 7 days with this receipt.',
);
