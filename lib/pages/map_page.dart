import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:healthmobile/services/health_facility_service.dart';

/// Titik pusat Pangkalpinang, Bangka Belitung (FALLBACK jika GPS tidak aktif)
const LatLng _pangkalpinangCenter = LatLng(-2.1200, 106.1000);

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final HealthFacilityService _facilityService = HealthFacilityService();

  /// Variabel Lokasi User
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  /// Variabel Daftar Puskesmas (dari Supabase + sudah dihitung jaraknya)
  List<Map<String, dynamic>> _facilitiesWithDistance = [];
  bool _isLoadingFacilities = true;
  String? _facilitiesError;

  /// Marker di Google Maps
  final Set<Marker> _markers = {};

  /// Marker yang saat ini dipilih (untuk bottom sheet)
  Map<String, dynamic>? _selectedFacility;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _getCurrentLocation();
    _loadFacilities();
  }

  // ========================================================================
  // 1. AMBIL DATA PUSKESMAS DARI SUPABASE (TANPA GPS pun bisa)
  // ========================================================================
  Future<void> _loadFacilities() async {
    setState(() {
      _isLoadingFacilities = true;
      _facilitiesError = null;
    });
    try {
      final list = await _facilityService.getAllFacilities();
      _addFacilityMarkers(list);
      setState(() {
        _isLoadingFacilities = false;
      });
    } catch (e) {
      setState(() {
        _facilitiesError = 'Gagal memuat data Puskesmas: $e';
        _isLoadingFacilities = false;
      });
    }
  }

  // ========================================================================
  // 2. GPS - MENDAPATKAN LOKASI USER
  // ========================================================================
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // --- Cek Layanan GPS ---
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError =
              'Layanan GPS tidak aktif. Mohon aktifkan GPS di HP Anda.';
          _isLoadingLocation = false;
        });
        // Meskipun GPS tidak aktif, kita tetap hitung jarak (pakai titik Pangkalpinang)
        _recalculateDistances(
          _pangkalpinangCenter.latitude,
          _pangkalpinangCenter.longitude,
        );
        return;
      }

      // --- Cek Izin Lokasi ---
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak.';
            _isLoadingLocation = false;
          });
          _recalculateDistances(
            _pangkalpinangCenter.latitude,
            _pangkalpinangCenter.longitude,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Izin lokasi ditolak permanen. Mohon aktifkan di Pengaturan > Aplikasi.';
          _isLoadingLocation = false;
        });
        _recalculateDistances(
          _pangkalpinangCenter.latitude,
          _pangkalpinangCenter.longitude,
        );
        return;
      }

      // --- DAPATKAN KOORDINAT LATITUDE LONGITUDE DARI GPS ---
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      setState(() {
        _currentPosition = LatLng(lat, lng);

        // Tambahkan Marker Lokasi User (hijau)
        _markers.add(
          Marker(
            markerId: const MarkerId('user'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'Lokasi Anda'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            zIndex: 10,
          ),
        );
        _isLoadingLocation = false;
      });

      // Hitung jarak puskesmas berdasarkan lokasi user SEBENARNYA
      _recalculateDistances(lat, lng);

      // Pusatkan kamera ke lokasi user
      _moveCamera(_currentPosition!);
    } catch (e) {
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: $e';
        _isLoadingLocation = false;
      });
      _recalculateDistances(
        _pangkalpinangCenter.latitude,
        _pangkalpinangCenter.longitude,
      );
    }
  }

  // ========================================================================
  // 3. HITUNG JARAK USER KE SETIAP PUSKESMAS & URUTKAN TERDEKAT
  // ========================================================================
  Future<void> _recalculateDistances(double lat, double lng) async {
    try {
      final sorted = await _facilityService.getFacilitiesSortedByDistance(
        userLat: lat,
        userLng: lng,
      );
      if (mounted) {
        setState(() {
          _facilitiesWithDistance = sorted;
        });
      }
    } catch (_) {
      // abaikan
    }
  }

  // ========================================================================
  // 4. TAMBAHKAN MARKER PUSKESMAS KE MAP (dari Supabase)
  // ========================================================================
  void _addFacilityMarkers(List<Map<String, dynamic>> facilities) {
    final Set<Marker> newMarkers = {};
    for (var f in facilities) {
      final lat = (f['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (f['longitude'] as num?)?.toDouble() ?? 0;
      final isRS = (f['type'] ?? '').toString().toLowerCase() == 'rumah_sakit';

      newMarkers.add(
        Marker(
          markerId: MarkerId('f-${f['id']}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: f['name'] as String? ?? 'Fasilitas',
            snippet: f['address'] as String? ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isRS ? BitmapDescriptor.hueRose : BitmapDescriptor.hueBlue,
          ),
          onTap: () {
            // Tambahkan field distance_km jika ada, untuk ditampilkan di detail
            final match = _facilitiesWithDistance.firstWhere(
              (e) => e['id'] == f['id'],
              orElse: () => {...f, 'distance_km': null as dynamic},
            );
            setState(() {
              _selectedFacility = match;
            });
            _showFacilityBottomSheet(match);
          },
        ),
      );
    }

    // Gabung dengan marker user (jika sudah ada)
    setState(() {
      _markers
        ..removeWhere((m) => m.markerId.value.startsWith('f-'))
        ..addAll(newMarkers);
    });
  }

  // ========================================================================
  // 5. PUSATKAN KAMERA KE TITIK TERTENTU
  // ========================================================================
  Future<void> _moveCamera(LatLng target, {double zoom = 14}) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  // ========================================================================
  // 6. BUKA GOOGLE MAPS UNTUK PETUNJUK ARAH NAVIGASI
  // ========================================================================
  Future<void> _launchDirections(Map<String, dynamic> facility) async {
    final lat = (facility['latitude'] as num?)?.toDouble();
    final lng = (facility['longitude'] as num?)?.toDouble();
    final name = Uri.encodeComponent(facility['name'] as String? ?? '');

    if (lat == null || lng == null) return;

    // URL Google Maps Directions (jika ada aplikasi Google Maps akan langsung terbuka navigasinya)
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=&dir_action=navigate&query=$name';

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ========================================================================
  // 7. BOTTOM SHEET JIKA MARKER PUSKESMAS DIKLIK
  // ========================================================================
  void _showFacilityBottomSheet(Map<String, dynamic> facility) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final distanceKm = facility['distance_km'] as double?;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF1976D2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility['name'] as String? ?? 'Puskesmas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (distanceKm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on_outlined,
                'Alamat',
                facility['address'] as String? ?? '-',
              ),
              if (facility['phone'] != null &&
                  (facility['phone'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Telepon',
                  facility['phone'] as String,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final lat = (facility['latitude'] as num?)?.toDouble();
                        final lng = (facility['longitude'] as num?)?.toDouble();
                        if (lat != null && lng != null) {
                          _moveCamera(LatLng(lat, lng), zoom: 17);
                        }
                      },
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Lihat Detail'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        foregroundColor: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchDirections(facility);
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('Petunjuk Arah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Puskesmas'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // ============== GOOGLE MAPS ==============
          GoogleMap(
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            initialCameraPosition: const CameraPosition(
              target: _pangkalpinangCenter,
              zoom: 12.5,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          ),

          // ============== CARD KOORDINAT USER (DI ATAS KIRI) ==============
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📍 Lokasi Anda',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingLocation)
                      const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Mendapatkan koordinat GPS...'),
                        ],
                      )
                    else if (_currentPosition != null)
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}   |   '
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                        ),
                      )
                    else if (_locationError != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_locationError != null && _currentPosition == null) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Default: Lokasi pusat Pangkalpinang',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ============== FLOATING BUTTON LOKASI SAYA ==============
          Positioned(
            right: 12,
            bottom: 280,
            child: FloatingActionButton.extended(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1976D2),
              elevation: 4,
              icon: const Icon(Icons.my_location, size: 22),
              label: Text(
                _isLoadingLocation ? 'Loading...' : 'Lokasi Saya',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ============== BOTTOM PANEL: PUSKESMAS TERDEKAT ==============
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.20,
            maxChildSize: 0.70,
            snapSizes: const [0.34, 0.7],
            snap: true,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Puskesmas Terdekat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isLoadingLocation || _isLoadingFacilities)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_facilitiesError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _facilitiesError!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_facilitiesWithDistance.isEmpty &&
                        !_isLoadingFacilities)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada data. Jalankan SQL SUPABASE_PUSKESMAS.sql\ndi Supabase dashboard Anda.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_facilitiesWithDistance.isNotEmpty)
                      ..._facilitiesWithDistance.asMap().entries.map((entry) {
                        final i = entry.key;
                        final f = entry.value;
                        final distanceKm = f['distance_km'] as double?;

                        final isFirst = i == 0;
                        final typeColor =
                            (f['type'] ?? 'puskesmas') == 'rumah_sakit'
                            ? Colors.pink
                            : Colors.blue;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showFacilityBottomSheet(f),
                            child: Card(
                              elevation: isFirst ? 2 : 0,
                              margin: EdgeInsets.zero,
                              color: isFirst
                                  ? const Color(0xFFE3F2FD).withOpacity(0.7)
                                  : Colors.grey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isFirst
                                      ? Colors.blue.shade200
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: typeColor.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isFirst
                                            ? Icons.star_rounded
                                            : Icons.local_hospital_outlined,
                                        color: typeColor,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (isFirst)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1976D2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'PALING DEKAT',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            f['name'] as String? ?? 'Puskesmas',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isFirst
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            f['address'] as String? ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          distanceKm != null
                                              ? '${distanceKm.toStringAsFixed(1)} km'
                                              : '-',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                distanceKm != null &&
                                                    distanceKm < 2
                                                ? const Color(0xFF4CAF50)
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
