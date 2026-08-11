import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final response = await _client
        .from('doctors')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchDoctors(String query) async {
    if (query.isEmpty) return getAllDoctors();

    final response = await _client
        .from('doctors')
        .select()
        .or('name.ilike.%$query%,specialty.ilike.%$query%')
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getDoctorById(String id) async {
    final response = await _client
        .from('doctors')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getPopularDoctors({int limit = 5}) async {
    final response = await _client
        .from('doctors')
        .select()
        .eq('available', true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllSchedulesByDoctor(
    String doctorId,
  ) async {
    final response = await _client
        .from('doctor_schedules')
        .select()
        .eq('doctor_id', doctorId)
        .order('date', ascending: true)
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    final response = await _client
        .from('doctor_schedules')
        .select('*, doctors(*)')
        .order('date', ascending: true)
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getScheduleById(String id) async {
    final response = await _client
        .from('doctor_schedules')
        .select('*, doctors(*)')
        .eq('id', id)
        .maybeSingle();
    return response;
  }
}
