import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String appointmentCodePrefix = 'MEDICARE-';

  String? get currentUserId => _client.auth.currentUser?.id;

  String buildAppointmentCode(String appointmentId) {
    return '$appointmentCodePrefix$appointmentId';
  }

  String extractAppointmentId(String code) {
    final normalizedCode = code.trim();
    if (normalizedCode.startsWith(appointmentCodePrefix)) {
      return normalizedCode.substring(appointmentCodePrefix.length);
    }
    return normalizedCode;
  }

  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('appointments')
        .select('*, doctors(*), doctor_schedules(*)')
        .eq('user_id', userId)
        .order('appointment_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUpcomingAppointments({
    int limit = 3,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client
        .from('appointments')
        .select('*, doctors(*), doctor_schedules(*)')
        .eq('user_id', userId)
        .gte('appointment_date', today)
        .inFilter('status', ['pending', 'confirmed', 'checked_in'])
        .order('appointment_date', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String scheduleId,
    required String appointmentDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final createdAppointment = await _client
        .from('appointments')
        .insert({
          'user_id': userId,
          'doctor_id': doctorId,
          'schedule_id': scheduleId,
          'appointment_date': appointmentDate,
          'status': 'pending',
        })
        .select()
        .single();

    final appointmentId = createdAppointment['id']?.toString();
    if (appointmentId == null || appointmentId.isEmpty) {
      return Map<String, dynamic>.from(createdAppointment);
    }

    return await getAppointmentById(appointmentId) ??
        Map<String, dynamic>.from(createdAppointment);
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _client
        .from('appointments')
        .update({'status': status})
        .eq('id', appointmentId)
        .eq('user_id', userId);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'cancelled');
  }

  Future<void> checkInAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'checked_in');
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String newScheduleId,
    required String newDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _client
        .from('appointments')
        .update({
          'schedule_id': newScheduleId,
          'appointment_date': newDate,
          'status': 'pending',
        })
        .eq('id', appointmentId)
        .eq('user_id', userId);
  }

  Future<void> deleteAppointment(String appointmentId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _client
        .from('appointments')
        .delete()
        .eq('id', appointmentId)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>?> getAppointmentById(String id) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('appointments')
        .select('*, doctors(*), doctor_schedules(*)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>?> findAppointmentByCode(String code) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final appointmentId = extractAppointmentId(code);
    if (appointmentId.isEmpty) return null;

    final response = await _client
        .from('appointments')
        .select('*, doctors(*), doctor_schedules(*)')
        .eq('id', appointmentId)
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }
}
