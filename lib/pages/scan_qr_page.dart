import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:healthmobile/services/appointment_service.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final MobileScannerController _controller = MobileScannerController();
  final AppointmentService _appointmentService = AppointmentService();

  bool _isScanning = true;
  String? _lastScanned;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (!_isScanning || _isProcessing) return;
    setState(() {
      _isScanning = false;
      _lastScanned = code;
      _isProcessing = true;
    });

    await _processQR(code);

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processQR(String code) async {
    final appointment = await _appointmentService.findAppointmentByCode(code);

    if (!mounted) return;

    if (appointment != null) {
      final doctor = appointment['doctors'] as Map<String, dynamic>?;
      final schedule = appointment['doctor_schedules'] as Map<String, dynamic>?;
      final currentStatus = appointment['status'];

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('QR Berhasil Dipindai!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode: $code',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detail Janji Temu:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Dokter', doctor?['name'] ?? '-'),
              _buildDetailRow('Spesialis', doctor?['specialty'] ?? '-'),
              _buildDetailRow(
                'Tanggal',
                appointment['appointment_date'] ?? '-',
              ),
              _buildDetailRow(
                'Jam',
                '${schedule?['start_time']?.toString().substring(0, 5) ?? '-'} WIB',
              ),
              _buildDetailRow('Status', currentStatus ?? '-'),
            ],
          ),
          actions: [
            if (currentStatus != 'checked_in' &&
                currentStatus != 'completed' &&
                currentStatus != 'cancelled')
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tutup'),
              ),
            if (currentStatus != 'checked_in' &&
                currentStatus != 'completed' &&
                currentStatus != 'cancelled')
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Check-in'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (currentStatus == 'checked_in')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sudah Check-in',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await _appointmentService.checkInAppointment(appointment['id']);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in berhasil! Selamat berkunjung.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal check-in: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Hasil Scan QR')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR tidak terdaftar di sistem appointment.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan format kode: ${AppointmentService.appointmentCodePrefix}{appointment_id}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _lastScanned = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Check-in'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                }
              }
            },
          ),
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Arahkan kamera ke QR Code',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final squareSize = size.width * 0.7;
                final left = (size.width - squareSize) / 2;
                final top = (size.height - squareSize) / 2;

                return Stack(
                  children: [_buildScanOverlay(left, top, squareSize, size)],
                );
              },
            ),
          ),
          if (!_isScanning)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'QR Terdeteksi!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _lastScanned ?? '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Memproses...'),
                      ],
                      if (!_isProcessing) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScanQRPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Scan Ulang'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Kembali'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(
    double left,
    double top,
    double size,
    Size screenSize,
  ) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.5),
                width: 0,
              ),
            ),
            child: CustomPaint(
              size: screenSize,
              painter: _ScannerOverlayPainter(
                cutOutRect: Rect.fromLTWH(left, top, size, size),
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildCorner(Colors.white, true, true),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCorner(Colors.white, false, true),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCorner(Colors.white, true, false),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCorner(Colors.white, false, false),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 3, color: const Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Color color, bool isLeft, bool isTop) {
    const length = 24.0;
    const thickness = 4.0;
    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: isLeft
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          top: isTop
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect cutOutRect;

  _ScannerOverlayPainter({required this.cutOutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
