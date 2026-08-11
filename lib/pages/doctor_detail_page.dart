import 'package:flutter/material.dart';
import 'package:healthmobile/pages/schedule_page.dart';
import 'package:healthmobile/services/doctor_service.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  final DoctorService _doctorService = DoctorService();

  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  bool _hasAvailableSchedule = false;

  bool _isCheckingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isCheckingSchedule = true;
      _hasAvailableSchedule = false;
    });

    try {
      // Ambil data dokter
      final doctor = await _doctorService.getDoctorById(widget.doctorId);

      if (doctor == null) {
        if (mounted) {
          setState(() {
            _doctor = null;
            _hasAvailableSchedule = false;
            _isLoading = false;
            _isCheckingSchedule = false;
          });
        }
        return;
      }

      // Status dokter
      final doctorAvailable = doctor['available'] == true;

      // Ambil semua jadwal dokter
      final schedules = await _doctorService.getAllSchedulesByDoctor(
        widget.doctorId,
      );

      // Hanya dianggap tersedia jika:
      // 1. Dokter available = true
      // 2. Ada minimal satu jadwal available = true
      final hasAvailableSchedule =
          doctorAvailable &&
          schedules.any((schedule) => schedule['available'] == true);

      if (mounted) {
        setState(() {
          _doctor = doctor;
          _hasAvailableSchedule = hasAvailableSchedule;
          _isLoading = false;
          _isCheckingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _doctor = null;
          _hasAvailableSchedule = false;
          _isLoading = false;
          _isCheckingSchedule = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data dokter: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dokter'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctor == null
          ? const Center(child: Text('Dokter tidak ditemukan'))
          : _buildDetail(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  (_doctor == null ||
                      _isCheckingSchedule ||
                      !_hasAvailableSchedule)
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SchedulePage(
                            selectedDoctorId: widget.doctorId,
                            selectedDoctorName: _doctor!['name'],
                          ),
                        ),
                      );
                    },
              icon: _isCheckingSchedule
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _hasAvailableSchedule
                          ? Icons.calendar_month
                          : Icons.event_busy,
                    ),
              label: Text(
                _isCheckingSchedule
                    ? 'Memeriksa jadwal...'
                    : _hasAvailableSchedule
                    ? 'Ambil Jadwal'
                    : 'Tidak Ada Jadwal',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final d = _doctor!;
    final photoUrl =
        d['photo_url'] ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(d['name'] ?? 'Dr')}&background=1976D2&color=fff&size=256';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
              ),
            ),
            child: Column(
              children: [
                Hero(
                  tag: 'doctor-${d['id']}',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              d['name']?[0] ?? 'D',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  d['name'] ?? 'Dokter',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d['specialty'] ?? 'Spesialis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: d['available'] == true
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: d['available'] == true
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            d['available'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: d['available'] == true
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            d['available'] == true
                                ? 'Tersedia'
                                : 'Tidak Tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Tentang'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      d['description'] ??
                          'Dokter berpengalaman di bidangnya, siap memberikan pelayanan kesehatan terbaik untuk Anda.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Kontak & Lokasi'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      if (d['phone'] != null &&
                          d['phone'].toString().isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Nomor Telepon',
                          value: d['phone'],
                        ),
                      if (d['location'] != null &&
                          d['location'].toString().isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Lokasi Praktik',
                          value: d['location'],
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Spesialisasi'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bidang Keahlian',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d['specialty'] ?? 'Umum',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 16 : 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1976D2)),
          ),
          const SizedBox(width: 16),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
