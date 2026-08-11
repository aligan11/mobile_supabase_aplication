import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HealthFacilityService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Model sederhana untuk menampung data puskesmas + jaraknya
  final List<Map<String, dynamic>> _allFacilities = [];

  /// Ambil SEMUA data Puskesmas dari Supabase
  Future<List<Map<String, dynamic>>> getAllFacilities({String? type}) async {
    dynamic query = _client.from('health_facilities').select();

    if (type != null) {
      query = query.eq('type', type);
    }

    query = query.order('name', ascending: true);

    final response = await query as List;
    final list = List<Map<String, dynamic>>.from(response);
    _allFacilities
      ..clear()
      ..addAll(list);
    return list;
  }

  /// Hitung jarak (dalam KM) user ke satu fasilitas kesehatan
  /// Rumus Haversine via Geolocator.distanceBetween (meter) -> dibagi 1000 jadi KM
  static double calculateDistanceInKm({
    required double userLat,
    required double userLng,
    required double facilityLat,
    required double facilityLng,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      facilityLat,
      facilityLng,
    );
    return distanceInMeters / 1000; // diubah ke kilometer
  }

  /// Mengembalikan list Puskesmas SUDAH DIURUTKAN dari jarak TERDEKAT
  /// Setiap item ditambah field 'distance_km' (jarak dalam kilometer)
  Future<List<Map<String, dynamic>>> getFacilitiesSortedByDistance({
    required double userLat,
    required double userLng,
    String? type,
  }) async {
    final facilities = _allFacilities.isEmpty
        ? await getAllFacilities(type: type)
        : _allFacilities
              .where((e) => type == null ? true : e['type'] == type)
              .toList();

    for (var f in facilities) {
      final lat = (f['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (f['longitude'] as num?)?.toDouble() ?? 0;
      final distanceKm = calculateDistanceInKm(
        userLat: userLat,
        userLng: userLng,
        facilityLat: lat,
        facilityLng: lng,
      );
      f['distance_km'] = distanceKm;
    }

    facilities.sort(
      (a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double),
    );

    return facilities;
  }
}
