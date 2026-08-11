import 'package:supabase_flutter/supabase_flutter.dart';

class HealthService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> getHealthRecords() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login');
    }

    final response = await _client
        .from('catatan_kesehatan')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getLatestHealthRecord() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login');
    }

    final response = await _client
        .from('catatan_kesehatan')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>> createHealthRecord({
    required double berat,
    required String tekananDarah,
    required int detakJantung,
    String? catatan,
    String? fotoUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User belum login');
    }

    final insertData = <String, dynamic>{
      'user_id': user.id,
      'berat': berat,
      'tekanan_darah': tekananDarah.trim(),
      'detak_jantung': detakJantung,
      'catatan': (catatan != null && catatan.trim().isNotEmpty)
          ? catatan.trim()
          : null,
      'foto_url': fotoUrl,
    };

    final created = await _client
        .from('catatan_kesehatan')
        .insert(insertData)
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  Future<Map<String, dynamic>?> getHealthRecordById(String id) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login');
    }

    final response = await _client
        .from('catatan_kesehatan')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  Future<void> updateHealthRecord({
    required String id,
    double? berat,
    String? tekananDarah,
    int? detakJantung,
    String? catatan,
    String? fotoUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login');
    }

    final updateData = <String, dynamic>{};
    if (berat != null) updateData['berat'] = berat;
    if (tekananDarah != null) updateData['tekanan_darah'] = tekananDarah.trim();
    if (detakJantung != null) updateData['detak_jantung'] = detakJantung;
    if (catatan != null) {
      updateData['catatan'] =
          catatan.trim().isEmpty ? null : catatan.trim();
    }
    if (fotoUrl != null) updateData['foto_url'] = fotoUrl;

    if (updateData.isEmpty) return;

    await _client
        .from('catatan_kesehatan')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> deleteHealthRecord(String id) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User belum login');
    }

    await _client
        .from('catatan_kesehatan')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}
