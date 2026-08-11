import 'package:flutter/material.dart';
import 'package:healthmobile/AddHealthPage.dart';
import 'package:healthmobile/pages/health/health_detail_page.dart';
import 'package:healthmobile/services/health_service.dart';
import 'package:healthmobile/utils/health_status.dart';
import 'package:intl/intl.dart';

class HealthHistoryPage extends StatefulWidget {
  const HealthHistoryPage({super.key});

  @override
  State<HealthHistoryPage> createState() => _HealthHistoryPageState();
}

class _HealthHistoryPageState extends State<HealthHistoryPage> {
  final HealthService _healthService = HealthService();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await _healthService.getHealthRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error load health records: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _tambahCatatan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHealthPage()),
    );
    if (result == true) {
      _loadRecords();
    }
  }

  void _bukaDetail(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthDetailPage(
          recordId: record['id'].toString(),
          initialData: record,
        ),
      ),
    ).then((_) => _loadRecords());
  }

  String _formatTanggal(dynamic value) {
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

  String _formatTanggalSingkat(dynamic value) {
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
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value?.toString() ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kesehatan'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahCatatan,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecords,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  size: 56,
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum Ada Catatan Kesehatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Mulai catat kondisi kesehatan Anda untuk monitoring rutin.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _tambahCatatan,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Catatan Pertama'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final berat = (record['berat'] as num?)?.toDouble();
    final tekanan = record['tekanan_darah']?.toString() ?? '-';
    final detak = (record['detak_jantung'] as num?)?.toInt();
    final catatan = record['catatan']?.toString();
    final tanggal = record['tanggal'] ?? record['created_at'];

    final tdStatus = HealthStatusHelper.getTekananDarahStatus(tekanan);
    final tdColor = HealthStatusHelper.getStatusColor(tdStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _bukaDetail(record),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTanggal(tanggal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTanggalSingkat(record['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Berat',
                        value:
                            berat != null ? '${berat.toStringAsFixed(1)} kg' : '-',
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.favorite_border,
                        label: 'Tekanan',
                        value: tekanan,
                        color: tdColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.monitor_heart_outlined,
                        label: 'Detak',
                        value: detak != null ? '$detak bpm' : '-',
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
                if (catatan != null && catatan.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            catatan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
