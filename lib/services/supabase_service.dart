import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SupabaseService {
  static SupabaseClient? _client;
  
  static Future<void> initialize() async {
    try {
      await dotenv.load();
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      developer.log('Initializing Supabase with URL: $url');
      
      if (url == null || anonKey == null) {
        throw Exception('Missing Supabase configuration. Please check your .env file.');
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true,
      );
      _client = Supabase.instance.client;
      developer.log('Supabase initialized successfully');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize Supabase', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Did you call initialize()?');
    }
    return _client!;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      developer.log('Attempting to sign up user: $email');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      developer.log('Sign up response received: ${response.user != null}');
      
      if (response.user != null && userData != null) {
        developer.log('Creating profile for user: ${response.user!.id}');
        await client.from('profiles').insert({
          'id': response.user!.id,
          ...userData,
        });
        developer.log('Profile created successfully');
      }
      
      return response;
    } catch (e, stackTrace) {
      developer.log('Sign up failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
} 