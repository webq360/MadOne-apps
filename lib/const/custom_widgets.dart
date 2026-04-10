import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle fontStyle([double? size, Color? clr, FontWeight? fw]) {
  return GoogleFonts.inter(
    fontSize: size,
    color: clr,
    fontWeight: fw,
  );
}

bool _isTrue(dynamic val) => val == 1 || val == true || val == '1';

bool _isBanned(Map<String, dynamic> p) => _isTrue(p['banned']) || _isTrue(p['is_banned']);
bool _isHidden(Map<String, dynamic> p) => _isTrue(p['hide']) || _isTrue(p['is_hide']);
bool _isNotAvailable(Map<String, dynamic> p) => _isTrue(p['not_available']);
bool _isStockout(Map<String, dynamic> p) => _isTrue(p['is_stockout']);
bool _isPreOrder(Map<String, dynamic> p) => _isTrue(p['pre_order']);

String productStatusLabel(Map<String, dynamic>? product) {
  if (product == null) return 'ADD';
  if (_isHidden(product)) return 'Hide Product';
  if (_isNotAvailable(product)) return 'Not Available';
  if (_isStockout(product)) return 'Stock Out';
  final qty = product['quantity'];
  if ((qty == 0 || qty == '0') && !_isPreOrder(product)) return 'Stock Out';
  if (_isPreOrder(product)) return 'Pre Order';
  return 'ADD';
}

Color productStatusColor(Map<String, dynamic>? product) {
  if (product == null) return const Color(0xff006B9C);
  if (_isHidden(product)) return Colors.grey;
  if (_isNotAvailable(product)) return Colors.red;
  if (_isStockout(product)) return Colors.yellow[700]!;
  final qty = product['quantity'];
  if ((qty == 0 || qty == '0') && !_isPreOrder(product)) return Colors.yellow[700]!;
  if (_isPreOrder(product)) return Colors.green;
  return const Color(0xff006B9C);
}

bool isProductAvailable(Map<String, dynamic>? product) {
  if (product == null) return true;
  if (_isHidden(product)) return false;
  if (_isNotAvailable(product)) return false;
  return true;
}

bool isProductVisible(Map<String, dynamic>? product) {
  if (product == null) return true;
  return !_isBanned(product);
}

bool hasStatusLabel(Map<String, dynamic>? product) => !isProductAvailable(product);
