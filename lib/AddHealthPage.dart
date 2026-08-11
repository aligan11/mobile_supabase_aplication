import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHealthPage extends StatefulWidget {
  const AddHealthPage({super.key});

  @override
  State<AddHealthPage> createState() => _AddHealthPageState();
}

class _AddHealthPageState extends State<AddHealthPage> {
  final beratBadanController = TextEditingController();
  final tekananDarahController = TextEditingController();
  final detakJantungController = TextEditingController();
  final catatanController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool isLoading = false;

  Future<void> simpanData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan Login Terlebih Dahulu')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.from('healt_records').insert({
        'user_id': user.id,
        'tanggal': DateTime.now().toIso8601String().split('T')[0],
        'berat': double.tryParse(beratBadanController.text),
        'tekanan_darah': tekananDarahController.text,
        'detak_jantung': int.tryParse(detakJantungController.text),
        'catatan': catatanController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data Berhasil Disimpan!')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal Menyimpan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    beratBadanController.dispose();
    tekananDarahController.dispose();
    detakJantungController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Data')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 15),
            TextField(
              controller: beratBadanController,
              decoration: InputDecoration(
                labelText: 'Berat Badan (kg)',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: tekananDarahController,
              decoration: InputDecoration(
                labelText: 'Tekanan Darah',
                hintText: 'Contoh 120/80',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: detakJantungController,
              decoration: InputDecoration(
                labelText: 'Detak Jantung (bpm)',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: (isLoading ? null : simpanData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
