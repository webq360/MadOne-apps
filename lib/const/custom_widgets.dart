import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

fontStyle([double ?size, Color ?clr, FontWeight ?fw ]){
  return GoogleFonts.inter(
    fontSize: size,
    color: clr,
    fontWeight: fw,
  );
}

