import 'package:flutter/material.dart';
import 'package:healthmobile/AddHealthPage.dart';
import 'package:healthmobile/pages/doctor_page.dart';
import 'package:healthmobile/pages/doctor_detail_page.dart';
import 'package:healthmobile/pages/health/health_history_page.dart';
import 'package:healthmobile/pages/schedule_page.dart';
import 'package:healthmobile/pages/map_page.dart';
import 'package:healthmobile/pages/scan_qr_page.dart';
import 'package:healthmobile/services/auth_service.dart';
import 'package:healthmobile/services/doctor_service.dart';
import 'package:healthmobile/services/appointment_service.dart';
import 'package:healthmobile/services/health_service.dart';
import 'package:healthmobile/utils/health_status.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();
  final HealthService _healthService = HealthService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _popularDoctors = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  Map<String, dynamic>? _latestHealth;
  bool _isLoading = true;
  bool _healthError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _healthError = false;
    try {
      final profile = await _authService.getProfile();
      final doctors = await _doctorService.getPopularDoctors();
      final appointments = await _appointmentService.getUpcomingAppointments();
      Map<String, dynamic>? latestHealth;
      try {
        latestHealth = await _healthService.getLatestHealthRecord();
      } catch (e) {
        debugPrint('Error load latest health (ignore): $e');
        _healthError = true;
        latestHealth = null;
      }
      if (mounted) {
        setState(() {
          _profile = profile;
          _popularDoctors = doctors;
          _upcomingAppointments = appointments;
          _latestHealth = latestHealth;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name'] ?? 'Pengguna';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final avatarUrl = _authService.getAvatarUrl(_profile?['avatar_url']);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(avatarUrl),
                                child: _profile?['avatar_url'] == null
                                    ? Text(
                                        firstLetter,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                        ),
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_getGreeting()},',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Selamat Datang di MediCare',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Pelayanan kesehatan terpercaya untuk Anda',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShortcuts(),
                    const SizedBox(height: 32),
                    _buildHealthSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Dokter Populer'),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildPopularDoctors(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Jadwal Terdekat'),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildUpcomingAppointments(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcuts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildShortcutItem(
                icon: Icons.people_alt_rounded,
                label: 'Dokter',
                color: const Color(0xFF1976D2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorPage()),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildShortcutItem(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchedulePage(),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: _buildShortcutItem(
                icon: Icons.location_on_rounded,
                label: 'Map',
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPage()),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildShortcutItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanQRPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Kondisi Kesehatan Terakhir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Card(
                child: SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _latestHealth != null
            ? _buildHealthCard()
            : _healthError
            ? _buildHealthErrorCard()
            : _buildHealthEmptyCard(),
      ],
    );
  }

  String _formatHealthDate(dynamic value) {
    try {
      if (value == null) return '-';
      DateTime d;
      if (value is DateTime) {
        d = value;
      } else {
        d = DateTime.parse(value.toString());
      }
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return value?.toString() ?? '-';
    }
  }

  Widget _buildHealthCard() {
    final r = _latestHealth!;
    final berat = (r['berat'] as num?)?.toDouble();
    final tekanan = r['tekanan_darah']?.toString() ?? '-';
    final detak = (r['detak_jantung'] as num?)?.toInt();
    final tanggal = r['tanggal'] ?? r['created_at'];

    final tdStatus = HealthStatusHelper.getTekananDarahStatus(tekanan);
    final tdColor = HealthStatusHelper.getStatusColor(tdStatus);
    final djStatus = detak != null
        ? HealthStatusHelper.getDetakJantungStatus(detak)
        : '-';
    final djColor = HealthStatusHelper.getStatusColor(djStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthHistoryPage()),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pencatatan Terbaru',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatHealthDate(tanggal),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Riwayat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.monitor_weight_outlined,
                            color: Color(0xFF1976D2),
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            berat != null
                                ? '${berat.toStringAsFixed(1)} kg'
                                : '-',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Berat',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: tdColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, color: tdColor, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            tekanan,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tdColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tekanan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: djColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: djColor,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detak != null ? '$detak bpm' : '-',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: djColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Detak',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthEmptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 56,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada catatan kesehatan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mulai catat kesehatan Anda untuk monitoring rutin.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddHealthPage(),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Catatan Pertama'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            const Text(
              'Fitur kesehatan perlu diaktifkan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Jalankan SQL Migration tabel catatan_kesehatan & RLS di Supabase SQL Editor.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tetap coba tambah data ↓',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddHealthPage(),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Coba Tambah Catatan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPopularDoctors() {
    if (_popularDoctors.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada data dokter',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 4),
        itemCount: _popularDoctors.length,
        itemBuilder: (context, index) {
          return _buildDoctorCard(_popularDoctors[index]);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final photoUrl =
        doctor['photo_url'] ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(doctor['name'] ?? 'Dr')}&background=1976D2&color=fff';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailPage(doctorId: doctor['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 150,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min, // TAMBAHKAN INI
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // TAMBAHKAN INI
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Dokter',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        doctor['specialty'] ?? 'Spesialis',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: doctor['available'] == true
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Flexible(
                            child: Text(
                              doctor['available'] == true
                                  ? 'Tersedia'
                                  : 'Penuh',
                              style: TextStyle(
                                fontSize: 11,
                                color: doctor['available'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada jadwal konsultasi',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SchedulePage(),
                        ),
                      );
                    },
                    child: const Text('Buat Jadwal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _upcomingAppointments.map((apt) {
        final doctor = apt['doctors'] as Map<String, dynamic>?;
        final schedule = apt['doctor_schedules'] as Map<String, dynamic>?;
        final date = apt['appointment_date'];
        final status = apt['status'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF1976D2),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor?['name'] ?? 'Dokter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor?['specialty'] ?? 'Spesialis',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule?['start_time']?.toString().substring(
                                  0,
                                  5,
                                ) ??
                                '-',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Dikonfirmasi';
        break;
      case 'checked_in':
        color = Colors.green;
        text = 'Check-in';
        break;
      case 'completed':
        color = Colors.grey;
        text = 'Selesai';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Batal';
        break;
      default:
        color = Colors.grey;
        text = status ?? '-';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
