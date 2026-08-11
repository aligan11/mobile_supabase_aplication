import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:healthmobile/services/appointment_service.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppointmentQrPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentQrPage({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentQrPage> createState() => _AppointmentQrPageState();
}

class _AppointmentQrPageState extends State<AppointmentQrPage> {
  final AppointmentService _appointmentService = AppointmentService();
  bool _isSaving = false;

  String get _appointmentId => widget.appointment['id'].toString();

  String get _qrCode => _appointmentService.buildAppointmentCode(_appointmentId);

  Future<Uint8List> _buildQrBytes() async {
    final painter = QrPainter(
      data: _qrCode,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF1976D2),
      emptyColor: Colors.white,
    );

    final byteData = await painter.toImageData(1024);
    if (byteData == null) {
      throw Exception('Gagal membuat QR PNG');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _saveQrAsPng() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final pngBytes = await _buildQrBytes();
      final fileName = 'medicare_qr_${_appointmentId.substring(0, 8)}';

      try {
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: pngBytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
      } catch (_) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: pngBytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR berhasil disimpan sebagai PNG'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.appointment['doctors'] as Map<String, dynamic>?;
    final schedule =
        widget.appointment['doctor_schedules'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Appointment'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1976D2), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: _qrCode,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1976D2),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tunjukkan QR ini saat check-in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appointment berhasil dibuat dan QR siap digunakan di halaman scan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kode QR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SelectableText(
                          _qrCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Detail Appointment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Dokter', doctor?['name'] ?? '-'),
                      _buildDetailRow('Spesialis', doctor?['specialty'] ?? '-'),
                      _buildDetailRow(
                        'Tanggal',
                        _formatDate(widget.appointment['appointment_date']),
                      ),
                      _buildDetailRow(
                        'Jam',
                        '${schedule?['start_time']?.toString().substring(0, 5) ?? '-'} - '
                            '${schedule?['end_time']?.toString().substring(0, 5) ?? '-'} WIB',
                      ),
                      _buildDetailRow(
                        'Status',
                        _formatStatus(widget.appointment['status']?.toString()),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQrAsPng,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Download QR PNG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  String _formatStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'checked_in':
        return 'Check-in';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Batal';
      default:
        return status ?? '-';
    }
  }
}
