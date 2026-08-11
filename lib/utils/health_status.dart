import 'package:flutter/material.dart';

class HealthStatusHelper {
  static String getTekananDarahStatus(String tekananDarah) {
    try {
      final parts = tekananDarah.split('/');
      if (parts.length != 2) return 'Data tercatat';

      final sistolik = int.tryParse(parts[0].trim());
      final diastolik = int.tryParse(parts[1].trim());

      if (sistolik == null || diastolik == null) return 'Data tercatat';

      if (sistolik < 90 || diastolik < 60) {
        return 'Perlu diperhatikan (Rendah)';
      } else if (sistolik <= 120 && diastolik <= 80) {
        return 'Normal';
      } else if (sistolik <= 139 || diastolik <= 89) {
        return 'Perlu diperhatikan (Pra-Hipertensi)';
      } else {
        return 'Perlu diperhatikan (Tinggi)';
      }
    } catch (_) {
      return 'Data tercatat';
    }
  }

  static String getDetakJantungStatus(int detak) {
    if (detak < 60) {
      return 'Perlu diperhatikan (Lambat)';
    } else if (detak <= 100) {
      return 'Dalam rentang normal';
    } else {
      return 'Perlu diperhatikan (Cepat)';
    }
  }

  static String getBeratStatus(double berat) {
    if (berat < 30) {
      return 'Perlu diperhatikan (Sangat Ringan)';
    } else if (berat <= 100) {
      return 'Data tercatat';
    } else {
      return 'Perlu diperhatikan';
    }
  }

  static Color getStatusColor(String status) {
    if (status.toLowerCase().contains('normal') ||
        status.toLowerCase().contains('rentang normal')) {
      return const Color(0xFF4CAF50);
    } else if (status.toLowerCase().contains('perlu diperhatikan') ||
        status.toLowerCase().contains('rendah') ||
        status.toLowerCase().contains('tinggi') ||
        status.toLowerCase().contains('lambat') ||
        status.toLowerCase().contains('cepat') ||
        status.toLowerCase().contains('ringan')) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFF1976D2);
  }
}
