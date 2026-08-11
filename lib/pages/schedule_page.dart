import 'package:flutter/material.dart';
import 'package:healthmobile/pages/appointment_qr_page.dart';
import 'package:healthmobile/services/doctor_service.dart';
import 'package:healthmobile/services/appointment_service.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  final String? selectedDoctorId;
  final String? selectedDoctorName;

  const SchedulePage({
    super.key,
    this.selectedDoctorId,
    this.selectedDoctorName,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();

  late TabController _tabController;

  List<Map<String, dynamic>> _myAppointments = [];
  List<Map<String, dynamic>> _allSchedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  String? _selectedDoctorId;

  bool _isLoadingAppointments = true;
  bool _isLoadingSchedules = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDoctorId = widget.selectedDoctorId;
    _loadAppointments();
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoadingAppointments = true);
    try {
      final appointments = await _appointmentService.getUserAppointments();
      if (mounted) {
        setState(() {
          _myAppointments = appointments;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAppointments = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat jadwal: $e')));
      }
    }
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      List<Map<String, dynamic>> schedules;
      if (_selectedDoctorId != null) {
        schedules = await _doctorService.getAllSchedulesByDoctor(
          _selectedDoctorId!,
        );
        final doctor = await _doctorService.getDoctorById(_selectedDoctorId!);
        schedules = schedules.map((s) {
          return {...s, 'doctors': doctor};
        }).toList();
      } else {
        schedules = await _doctorService.getAllSchedules();
      }
      if (mounted) {
        setState(() {
          _allSchedules = schedules;
          _filteredSchedules = schedules;
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat jadwal: $e')));
      }
    }
  }

  Future<void> _createAppointment(Map<String, dynamic> schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Jadwal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dokter: ${schedule['doctors']?['name'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Spesialis: ${schedule['doctors']?['specialty'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatDate(schedule['date'])}'),
            const SizedBox(height: 8),
            Text(
              'Jam: ${schedule['start_time']?.toString().substring(0, 5)} - '
              '${schedule['end_time']?.toString().substring(0, 5)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ambil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCreating = true);
    try {
      final appointment = await _appointmentService.createAppointment(
        doctorId: schedule['doctor_id'],
        scheduleId: schedule['id'],
        appointmentDate: schedule['date'],
      );
      if (!mounted) return;
      await _loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil diambil!'),
          backgroundColor: Colors.green,
        ),
      );
      await _openAppointmentQr(appointment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil jadwal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _openAppointmentQr(Map<String, dynamic> appointment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentQrPage(appointment: appointment),
      ),
    );
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Janji Temu'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan janji temu ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appointmentService.cancelAppointment(appointment['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji temu berhasil dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membatalkan: $e')));
    }
  }

  Future<void> _deleteAppointment(Map<String, dynamic> appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Janji Temu'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus janji temu ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appointmentService.deleteAppointment(appointment['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Janji temu berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedDoctorName != null
              ? 'Jadwal ${widget.selectedDoctorName}'
              : 'Jadwal Dokter',
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Jadwal Saya'),
            Tab(text: 'Jadwal Tersedia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyAppointments(), _buildAvailableSchedules()],
      ),
    );
  }

  Widget _buildMyAppointments() {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada janji temu',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add),
                label: const Text('Buat Janji Temu'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myAppointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(_myAppointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final doctor = apt['doctors'] as Map<String, dynamic>?;
    final schedule = apt['doctor_schedules'] as Map<String, dynamic>?;
    final status = apt['status'];
    final appointmentCode = _appointmentService.buildAppointmentCode(
      apt['id'].toString(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor?['name'] ?? 'Dokter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor?['specialty'] ?? 'Spesialis',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(apt['appointment_date']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${schedule?['start_time']?.toString().substring(0, 5) ?? '-'} WIB',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Kode Appointment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    appointmentCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAppointmentQr(apt),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Lihat QR'),
              ),
            ),
            if (status == 'pending' || status == 'confirmed') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelAppointment(apt),
                      icon: const Icon(Icons.cancel, color: Colors.orange),
                      label: const Text(
                        'Batalkan',
                        style: TextStyle(color: Colors.orange),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRescheduleDialog(apt),
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Ubah Jadwal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () => _deleteAppointment(apt),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRescheduleDialog(Map<String, dynamic> oldApt) async {
    final doctorId = oldApt['doctor_id'];
    final availableSchedules = await _doctorService.getAllSchedulesByDoctor(
      doctorId,
    );

    if (!mounted) return;

    final selectedSchedule = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Jadwal Baru'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableSchedules.isEmpty
              ? const Text('Tidak ada jadwal tersedia')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableSchedules.length,
                  itemBuilder: (context, index) {
                    final s = availableSchedules[index];
                    return ListTile(
                      title: Text(_formatDate(s['date'])),
                      subtitle: Text(
                        '${s['start_time']?.toString().substring(0, 5)} - '
                        '${s['end_time']?.toString().substring(0, 5)}',
                      ),
                      trailing: s['available'] == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                      enabled: s['available'] == true,
                      onTap: s['available'] == true
                          ? () => Navigator.pop(context, s)
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (selectedSchedule == null) return;

    try {
      await _appointmentService.rescheduleAppointment(
        appointmentId: oldApt['id'],
        newScheduleId: selectedSchedule['id'],
        newDate: selectedSchedule['date'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil diubah'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah jadwal: $e')));
    }
  }

  Widget _buildAvailableSchedules() {
    return Column(
      children: [
        if (_selectedDoctorId == null && !_isLoadingSchedules)
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String?>(
              value: null,
              hint: const Text('Filter berdasarkan dokter (opsional)'),
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.filter_alt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Semua Dokter'),
                ),
                ..._getUniqueDoctors().map((d) {
                  return DropdownMenuItem(
                    value: d['id'],
                    child: Text('${d['name']} - ${d['specialty']}'),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    _filteredSchedules = _allSchedules;
                  } else {
                    _filteredSchedules = _allSchedules
                        .where((s) => s['doctor_id'] == val)
                        .toList();
                  }
                });
              },
            ),
          ),
        Expanded(
          child: _isLoadingSchedules
              ? const Center(child: CircularProgressIndicator())
              : _filteredSchedules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada jadwal tersedia',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSchedules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSchedules.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(_filteredSchedules[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getUniqueDoctors() {
    final seen = <String>{};
    return _allSchedules
        .where((s) {
          final doctor = s['doctors'] as Map<String, dynamic>?;
          if (doctor == null) return false;
          final id = doctor['id'] as String?;
          if (id == null) return false;
          if (seen.contains(id)) return false;
          seen.add(id);
          return true;
        })
        .map((s) => s['doctors'] as Map<String, dynamic>)
        .toList();
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final doctor = schedule['doctors'] as Map<String, dynamic>?;
    final rawAvailable = schedule['available'];
    final isAvailable = rawAvailable == true;

    debugPrint(
      'SCHEDULE DEBUG => '
      'id=${schedule['id']} | '
      'date=${schedule['date']} | '
      'available=$rawAvailable | '
      'type=${rawAvailable.runtimeType}',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF1976D2)),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
                      Text(
                        doctor?['specialty'] ?? 'Spesialis',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(schedule['date']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${schedule['start_time']?.toString().substring(0, 5)} - '
                        '${schedule['end_time']?.toString().substring(0, 5)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Tersedia' : 'Penuh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: (isAvailable && !_isCreating)
                        ? () => _createAppointment(schedule)
                        : null,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: Text(
                      _isCreating ? 'Memproses...' : 'Ambil',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
