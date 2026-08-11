import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
      });
    }
    return user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updateData = <String, dynamic>{'full_name': fullName};
    if (phone != null) updateData['phone'] = phone;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(updateData).eq('id', user.id);
  }

  Future<String> uploadAvatar(String filePath, String fileName) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.storage
        .from('avatars')
        .upload(
          '${user.id}/$fileName',
          File(filePath),
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage
        .from('avatars')
        .getPublicUrl('${user.id}/$fileName');

    return publicUrl;
  }

  String getAvatarUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://ui-avatars.com/api/?name=User&background=1976D2&color=fff';
    }
    if (path.startsWith('http')) return path;
    try {
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (_) {
      return 'https://ui-avatars.com/api/?name=User&background=1976D2&color=fff';
    }
  }
}
