import 'package:flutter/material.dart';
import 'package:healthmobile/utils/health_status.dart';
import 'package:healthmobile/services/health_service.dart';
import 'package:intl/intl.dart';

class HealthDetailPage extends StatefulWidget {
  final String recordId;
  final Map<String, dynamic>? initialData;

  const HealthDetailPage({
    super.key,
    required this.recordId,
    this.initialData,
  });

  @override
  State<HealthDetailPage> createState() => _HealthDetailPageState();
}

class _HealthDetailPageState extends State<HealthDetailPage> {
  final HealthService _healthService = HealthService();
  Map<String, dynamic>? _record;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _record = widget.initialData;
      _isLoading = false;
    } else {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await _healthService.getHealthRecordById(widget.recordId);
      if (mounted) {
        setState(() {
          _record = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _hapusCatatan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan kesehatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _healthService.deleteHealthRecord(widget.recordId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    try {
      if (value == null) return '-';
      DateTime date;
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.parse(value);
      } else {
        return value.toString();
      }
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value?.toString() ?? '-';
    }
  }

  String _formatDateTime(dynamic value) {
    try {
      if (value == null) return '-';
      DateTime date;
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.parse(value);
      } else {
        return value.toString();
      }
      return DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(date);
    } catch (_) {
      return value?.toString() ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan Kesehatan'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          if (_record != null && !_isLoading)
            IconButton(
              onPressed: _isDeleting ? null : _hapusCatatan,
              tooltip: 'Hapus',
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _record == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'Data tidak ditemukan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildDetail(),
      ),
    );
  }

  Widget _buildDetail() {
    final r = _record!;
    final berat = (r['berat'] as num?)?.toDouble();
    final tekananDarah = r['tekanan_darah']?.toString() ?? '-';
    final detakJantung = (r['detak_jantung'] as num?)?.toInt();
    final catatan = r['catatan']?.toString();

    final tdStatus = HealthStatusHelper.getTekananDarahStatus(tekananDarah);
    final djStatus = detakJantung != null
        ? HealthStatusHelper.getDetakJantungStatus(detakJantung)
        : '-';
    final beratStatus = berat != null
        ? HealthStatusHelper.getBeratStatus(berat)
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detail Pencatatan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatDate(r['tanggal'] ?? r['created_at']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Berat Badan',
                    value: berat != null ? '${berat.toStringAsFixed(1)} kg' : '-',
                    status: beratStatus,
                  ),
                  const SizedBox(height: 16),
                  _buildDataItem(
                    icon: Icons.favorite_border,
                    label: 'Tekanan Darah',
                    value: '$tekananDarah mmHg',
                    status: tdStatus,
                  ),
                  const SizedBox(height: 16),
                  _buildDataItem(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Detak Jantung',
                    value: detakJantung != null ? '$detakJantung bpm' : '-',
                    status: djStatus,
                  ),
                ],
              ),
            ),
          ),
          if (catatan != null && catatan.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notes_outlined,
                              color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        catatan,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dicatat pada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(r['created_at']),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
    required String status,
  }) {
    final statusColor = HealthStatusHelper.getStatusColor(status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
