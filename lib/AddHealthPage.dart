import 'package:flutter/material.dart';
import 'package:healthmobile/pages/health/health_detail_page.dart';
import 'package:healthmobile/pages/health/health_history_page.dart';
import 'package:healthmobile/services/health_service.dart';
import 'package:healthmobile/utils/health_status.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHealthPage extends StatefulWidget {
  const AddHealthPage({super.key});

  @override
  State<AddHealthPage> createState() => _AddHealthPageState();
}

class _AddHealthPageState extends State<AddHealthPage> {
  final _formKey = GlobalKey<FormState>();
  final HealthService _healthService = HealthService();

  final beratBadanController = TextEditingController();
  final tekananDarahController = TextEditingController();
  final detakJantungController = TextEditingController();
  final catatanController = TextEditingController();

  bool _isLoading = false;

  // ============================================================
  // VALIDASI BERAT BADAN
  // ============================================================

  String? _validateBerat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Berat badan wajib diisi';
    }

    final berat = double.tryParse(value.trim().replaceAll(',', '.'));

    if (berat == null) {
      return 'Berat badan harus berupa angka';
    }

    if (berat <= 0) {
      return 'Berat badan harus lebih dari 0';
    }

    if (berat < 2 || berat > 300) {
      return 'Berat badan tidak wajar (2 - 300 kg)';
    }

    return null;
  }

  // ============================================================
  // VALIDASI TEKANAN DARAH
  // ============================================================

  String? _validateTekananDarah(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tekanan darah wajib diisi';
    }

    final pattern = RegExp(r'^\d{2,3}/\d{2,3}$');

    if (!pattern.hasMatch(value.trim())) {
      return 'Format harus seperti "120/80"';
    }

    return null;
  }

  // ============================================================
  // VALIDASI DETAK JANTUNG
  // ============================================================

  String? _validateDetakJantung(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Detak jantung wajib diisi';
    }

    final detak = int.tryParse(value.trim());

    if (detak == null) {
      return 'Detak jantung harus berupa angka bulat';
    }

    if (detak <= 0) {
      return 'Detak jantung harus lebih dari 0';
    }

    if (detak < 30 || detak > 250) {
      return 'Detak jantung tidak wajar (30 - 250 bpm)';
    }

    return null;
  }

  // ============================================================
  // PARSING BERAT
  // ============================================================

  double? _parseBerat(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  // ============================================================
  // PARSING DETAK JANTUNG
  // ============================================================

  int? _parseDetakJantung(String text) {
    return int.tryParse(text.trim());
  }

  // ============================================================
  // SIMPAN DATA
  // ============================================================

  Future<void> _simpanData() async {
    final user = _healthService.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final berat = _parseBerat(beratBadanController.text);
      final detakJantung = _parseDetakJantung(detakJantungController.text);
      final catatanText = catatanController.text.trim();

      if (berat == null) {
        throw Exception('Berat badan tidak dapat diproses');
      }
      if (detakJantung == null) {
        throw Exception('Detak jantung tidak dapat diproses');
      }

      debugPrint('========================================');
      debugPrint('INSERT CATATAN KESEHATAN');
      debugPrint('========================================');
      debugPrint('user_id: ${user.id}');
      debugPrint('berat: $berat (${berat.runtimeType})');
      debugPrint('tekanan_darah: ${tekananDarahController.text.trim()}');
      debugPrint('detak_jantung: $detakJantung (${detakJantung.runtimeType})');
      debugPrint('catatan: ${catatanText.isEmpty ? 'NULL' : catatanText}');
      debugPrint('========================================');

      final createdRecord = await _healthService.createHealthRecord(
        berat: berat,
        tekananDarah: tekananDarahController.text.trim(),
        detakJantung: detakJantung,
        catatan: catatanText.isEmpty ? null : catatanText,
        fotoUrl: null,
      );

      if (!mounted) return;

      _clearForm();

      await _showResultPage(createdRecord);
    }
    // ==========================================================
    // POSTGRES ERROR
    // ==========================================================
    on PostgrestException catch (e) {
      debugPrint('========================================');

      debugPrint('POSTGRES ERROR');

      debugPrint('========================================');

      debugPrint('Message: ${e.message}');

      debugPrint('Code: ${e.code}');

      debugPrint('Details: ${e.details}');

      debugPrint('Hint: ${e.hint}');

      debugPrint('========================================');

      String pesanError;

      // --------------------------------------------------------
      // INVALID INPUT SYNTAX
      // --------------------------------------------------------

      if (e.code == '22P02') {
        pesanError =
            'Kesalahan tipe data database. '
            'Pastikan user_id bertipe UUID dan '
            'kolom lainnya sesuai dengan database.';
      }
      // --------------------------------------------------------
      // RLS
      // --------------------------------------------------------
      else if (e.code == '42501') {
        pesanError =
            'Akses ditolak oleh RLS. '
            'Pastikan policy INSERT untuk '
            'catatan_kesehatan sudah dibuat.';
      }
      // --------------------------------------------------------
      // TABLE NOT FOUND
      // --------------------------------------------------------
      else if (e.code == '42P01') {
        pesanError =
            'Tabel catatan_kesehatan tidak ditemukan '
            'di database Supabase.';
      }
      // --------------------------------------------------------
      // USER ID ERROR
      // --------------------------------------------------------
      else if (e.message.toLowerCase().contains('user_id')) {
        pesanError =
            'Kesalahan pada kolom user_id. '
            'Pastikan kolom user_id bertipe UUID.';
      }
      // --------------------------------------------------------
      // ERROR LAIN
      // --------------------------------------------------------
      else {
        pesanError = 'Database error: ${e.message}';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // ==========================================================
    // ERROR UMUM
    // ==========================================================
    catch (e) {
      debugPrint('Error umum saat menyimpan data: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // ==========================================================
    // SELESAI LOADING
    // ==========================================================
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    beratBadanController.clear();
    tekananDarahController.clear();
    detakJantungController.clear();
    catatanController.clear();
    _formKey.currentState?.reset();
  }

  Future<void> _showResultPage(Map<String, dynamic> record) async {
    final berat = (record['berat'] as num?)?.toDouble();
    final tekananDarah = record['tekanan_darah']?.toString() ?? '-';
    final detak = (record['detak_jantung'] as num?)?.toInt();
    final catatan = record['catatan']?.toString();
    final tanggal = record['tanggal'] ?? record['created_at'];

    final tdStatus = HealthStatusHelper.getTekananDarahStatus(tekananDarah);
    final tdColor = HealthStatusHelper.getStatusColor(tdStatus);
    final djStatus = detak != null
        ? HealthStatusHelper.getDetakJantungStatus(detak)
        : '-';
    final djColor = HealthStatusHelper.getStatusColor(djStatus);

    String formatTanggal(dynamic value) {
      try {
        if (value == null) return '-';
        DateTime d;
        if (value is DateTime) {
          d = value;
        } else {
          d = DateTime.parse(value.toString());
        }
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d);
      } catch (_) {
        return value?.toString() ?? '-';
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Catatan Berhasil Disimpan!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTanggal(tanggal),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultItem(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Berat Badan',
                            value: berat != null
                                ? '${berat.toStringAsFixed(1)} kg'
                                : '-',
                            status: HealthStatusHelper.getBeratStatus(
                              berat ?? 0,
                            ),
                            statusColor: HealthStatusHelper.getStatusColor(
                              HealthStatusHelper.getBeratStatus(berat ?? 0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildResultItem(
                            icon: Icons.favorite_border,
                            label: 'Tekanan Darah',
                            value: '$tekananDarah mmHg',
                            status: tdStatus,
                            statusColor: tdColor,
                          ),
                          const SizedBox(height: 16),
                          _buildResultItem(
                            icon: Icons.monitor_heart_outlined,
                            label: 'Detak Jantung',
                            value: detak != null ? '$detak bpm' : '-',
                            status: djStatus,
                            statusColor: djColor,
                          ),
                          if (catatan != null && catatan.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notes_outlined,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Catatan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    catatan,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HealthHistoryPage(),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text(
                        'Lihat Riwayat Kesehatan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'Tambah Catatan Lain',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HealthDetailPage(
                              recordId: record['id'].toString(),
                              initialData: record,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text(
                        'Buka Detail Lengkap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    beratBadanController.dispose();
    tekananDarahController.dispose();
    detakJantungController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan Kesehatan'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
                    ),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 36,
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Catat Kondisi Kesehatan',

                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Masukkan data Anda dengan '
                              'benar untuk tracking kesehatan.',

                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // BERAT BADAN
                // ==================================================
                _buildBeratField(),

                const SizedBox(height: 16),

                // ==================================================
                // TEKANAN DARAH
                // ==================================================
                _buildTekananDarahField(),

                const SizedBox(height: 16),

                // ==================================================
                // DETAK JANTUNG
                // ==================================================
                _buildDetakJantungField(),

                const SizedBox(height: 16),

                // ==================================================
                // CATATAN
                // ==================================================
                _buildCatatanField(),

                const SizedBox(height: 32),

                // ==================================================
                // TOMBOL SIMPAN
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _simpanData,

                    icon: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 22),

                    label: Text(
                      _isLoading ? 'Menyimpan...' : 'Simpan Catatan',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),

                      foregroundColor: Colors.white,

                      disabledBackgroundColor: Colors.blue.shade200,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIELD BERAT BADAN
  // ============================================================

  Widget _buildBeratField() {
    return TextFormField(
      controller: beratBadanController,

      enabled: !_isLoading,

      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),

      validator: _validateBerat,

      decoration: InputDecoration(
        labelText: 'Berat Badan',

        hintText: 'Contoh: 55.5',

        helperText:
            'Pisahkan desimal dengan titik (.) '
            'atau koma (,)',

        prefixIcon: const Icon(Icons.monitor_weight_outlined),

        suffixText: 'kg',

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      textInputAction: TextInputAction.next,
    );
  }

  // ============================================================
  // FIELD TEKANAN DARAH
  // ============================================================

  Widget _buildTekananDarahField() {
    return TextFormField(
      controller: tekananDarahController,

      enabled: !_isLoading,

      keyboardType: TextInputType.text,

      validator: _validateTekananDarah,

      decoration: InputDecoration(
        labelText: 'Tekanan Darah',

        hintText: 'Contoh: 120/80',

        helperText: 'Format: sistolik/diastolik',

        prefixIcon: const Icon(Icons.favorite_border),

        suffixText: 'mmHg',

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      textInputAction: TextInputAction.next,
    );
  }

  // ============================================================
  // FIELD DETAK JANTUNG
  // ============================================================

  Widget _buildDetakJantungField() {
    return TextFormField(
      controller: detakJantungController,

      enabled: !_isLoading,

      keyboardType: TextInputType.number,

      validator: _validateDetakJantung,

      decoration: InputDecoration(
        labelText: 'Detak Jantung',

        hintText: 'Contoh: 80',

        helperText:
            'Masukkan angka bulat '
            '(tanpa desimal)',

        prefixIcon: const Icon(Icons.monitor_heart_outlined),

        suffixText: 'bpm',

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      textInputAction: TextInputAction.next,
    );
  }

  // ============================================================
  // FIELD CATATAN
  // ============================================================

  Widget _buildCatatanField() {
    return TextFormField(
      controller: catatanController,

      enabled: !_isLoading,

      keyboardType: TextInputType.multiline,

      maxLines: 4,

      decoration: InputDecoration(
        labelText: 'Catatan (Opsional)',

        hintText:
            'Contoh: Kondisi tubuh hari ini '
            'terasa fit, tidak ada keluhan...',

        prefixIcon: const Icon(Icons.notes_outlined),

        alignLabelWithHint: true,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      textInputAction: TextInputAction.done,
    );
  }
}
