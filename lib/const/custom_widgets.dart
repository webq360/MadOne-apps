import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle fontStyle([double? size, Color? clr, FontWeight? fw]) {
  return GoogleFonts.inter(
    fontSize: size,
    color: clr,
    fontWeight: fw,
  );
}

Color productStatusColor(Map<String, dynamic>? product) {
  if (product == null) return const Color(0xff006B9C);
  if (product['is_stockout'] == 1 || product['is_stockout'] == true) return Colors.red;
  if (product['pre_order'] == 1 || product['pre_order'] == true) return Colors.orange;
  return const Color(0xff006B9C);
}

String productStatusLabel(Map<String, dynamic>? product) {
  if (product == null) return 'ADD';
  if (product['is_stockout'] == 1 || product['is_stockout'] == true) return 'Stock Out';
  if (product['pre_order'] == 1 || product['pre_order'] == true) return 'Pre Order';
  return 'ADD';
}

bool isProductAvailable(Map<String, dynamic>? product) {
  if (product == null) return true;
  if (product['is_stockout'] == 1 || product['is_stockout'] == true) return false;
  return true; // pre_order products CAN be ordered
}

bool hasStatusLabel(Map<String, dynamic>? product) => !isProductAvailable(product);
