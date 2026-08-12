import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/app_city.dart';
import '../models/app_class.dart';
import '../models/app_category.dart';
import '../models/app_event.dart';
import '../models/favorite.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../models/app_notification.dart';
import '../models/user_profile.dart';
import '../models/organization.dart';
import '../models/org_photo.dart';
import '../models/org_invite.dart';
import '../models/org_member.dart';
import '../models/event_recurrence.dart';

const _baseUrl = 'https://hobbylab-api-production-84bd.up.railway.app';
const _tokenKey = 'auth_token';
const _userIdKey = 'current_user_id';

class ApiService {
  static String? _sessionToken;
  static String? _cachedUserId;
  static bool _handlingUnauthorized = false;

  static final authNotifier = ValueNotifier<bool>(true);

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<String?> getSavedToken() async {
    if (_sessionToken != null) return _sessionToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getSavedToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<String> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      _sessionToken = token;
      _handlingUnauthorized = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      // Eagerly cache user ID so chat doesn't need an extra /me call
      try {
        final profile = await getMe();
        _cachedUserId = profile.id;
        await prefs.setString(_userIdKey, profile.id);
        debugPrint('[Auth] Cached user_id: "${profile.id}"');
      } catch (e) {
        debugPrint('[Auth] Could not cache user_id after login: $e');
      }
      return token;
    }
    throw Exception('Invalid email or password');
  }

  // TODO: Backend must implement POST /auth/google-login
  // Request body:  {"id_token": "<Google ID token>"}
  // Response body: {"access_token": "<app JWT>"}
  static Future<void> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Failed to get Google ID token');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      _sessionToken = token;
      _handlingUnauthorized = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      // User ID is fetched lazily on first demand via getCurrentUserId().
      // We intentionally skip the eager getMe() call here: if getMe() were to
      // return 401 (e.g. transient backend issue for a newly created Google
      // user), _handleError would fire _onUnauthorized() which calls logout()
      // and wipes the just-saved token — breaking session persistence.
      return;
    }
    final detail = _extractDetail(response.body);
    throw Exception(
      'Google login failed (${response.statusCode})${detail != null ? ": $detail" : ""}',
    );
  }

  // TODO: Backend must implement POST /auth/facebook-login
  // Request body:  {"access_token": "<Facebook User Access Token>"}
  // Response body: {"access_token": "<app JWT>"}
  static Future<void> loginWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw Exception('Facebook sign-in cancelled');
    }
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Facebook sign-in failed: ${result.message}');
    }

    final fbToken = result.accessToken!.tokenString;

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/facebook-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': fbToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      _sessionToken = token;
      _handlingUnauthorized = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      // Skipping eager getMe() — same reasoning as loginWithGoogle().
      return;
    }
    final detail = _extractDetail(response.body);
    throw Exception(
      'Facebook login failed (${response.statusCode})${detail != null ? ": $detail" : ""}',
    );
  }

  static Future<void> loginWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Sign in with Apple is only supported on iOS/macOS');
    }

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple sign-in cancelled');
      }
      rethrow;
    }

    final identityToken = credential.identityToken;
    if (identityToken == null)
      throw Exception('Failed to get Apple identity token');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/apple-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': identityToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      _sessionToken = token;
      _handlingUnauthorized = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      // Skipping eager getMe() — same reasoning as loginWithGoogle().
      return;
    }
    final detail = _extractDetail(response.body);
    throw Exception(
      'Apple login failed (${response.statusCode})${detail != null ? ": $detail" : ""}',
    );
  }

  static Future<void> logout() async {
    _sessionToken = null;
    _cachedUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  static Future<void> _onUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    await logout();
    authNotifier.value = false;
  }

  static void _handleError(http.Response response) {
    if (response.statusCode == 401) _onUnauthorized();
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  static Future<String> uploadFile(String filePath) async {
    debugPrint('[Upload] uploading file: $filePath');
    final token = await getSavedToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    debugPrint(
      '[Upload] status: ${response.statusCode}  body: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Upload succeeded but returned empty URL');
      }
      debugPrint('[Upload] success → $url');
      return url;
    }
    if (response.statusCode == 401) _onUnauthorized();
    final detail = _extractDetail(response.body);
    throw Exception(
      'Upload failed (${response.statusCode})${detail != null ? ": $detail" : ""}',
    );
  }

  static String? _extractDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<String> getCurrentUserId() async {
    if (_cachedUserId != null) {
      debugPrint('[Auth] getCurrentUserId from cache: "$_cachedUserId"');
      return _cachedUserId!;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_userIdKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedUserId = saved;
      debugPrint('[Auth] getCurrentUserId from prefs: "$saved"');
      return saved;
    }
    debugPrint('[Auth] getCurrentUserId: fetching from /me');
    final profile = await getMe();
    _cachedUserId = profile.id;
    await prefs.setString(_userIdKey, profile.id);
    debugPrint('[Auth] getCurrentUserId from /me: "${profile.id}"');
    return profile.id;
  }

  // ── Classes ────────────────────────────────────────────────────────────────

  static Future<List<AppCity>> getCities({String? q}) async {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    final uri = Uri.parse(
      '$_baseUrl/cities/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => AppCity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<List<AppClass>> getClasses({
    int? categoryId,
    int? cityId,
    double? userLat,
    double? userLng,
  }) async {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (cityId != null) params['city_id'] = cityId.toString();
    if (userLat != null && userLng != null) {
      params['user_latitude'] = userLat.toString();
      params['user_longitude'] = userLng.toString();
      params['radius_km'] = '25';
    }
    final uri = Uri.parse(
      '$_baseUrl/classes/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => AppClass.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load classes');
  }

  static Future<List<AppClass>> searchClasses(
    String query, {
    int? categoryId,
  }) async {
    final params = <String, String>{};
    if (query.isNotEmpty) params['search'] = query;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    final uri = Uri.parse(
      '$_baseUrl/classes/search',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> items;
      if (body is Map && body.containsKey('items')) {
        items = body['items'] as List<dynamic>;
      } else if (body is List) {
        items = body;
      } else {
        return [];
      }
      return items.map((item) {
        if (item is Map<String, dynamic> && item.containsKey('class')) {
          final classData = item['class'] as Map<String, dynamic>;
          final rating = item['rating'];
          return AppClass.fromJson({
            ...classData,
            if (rating != null) 'average_rating': rating,
          });
        }
        return AppClass.fromJson(item as Map<String, dynamic>);
      }).toList();
    }
    throw Exception('Search failed');
  }

  static Future<Map<String, dynamic>> getClassDetails(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/classes/$id/details'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load class details');
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  static Future<List<AppCategory>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load categories');
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  static Future<List<AppEvent>> getEvents({
    int? cityId,
    int? categoryId,
    double? userLat,
    double? userLng,
  }) async {
    final params = <String, String>{};
    if (cityId != null) params['city_id'] = cityId.toString();
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (userLat != null && userLng != null) {
      params['user_latitude'] = userLat.toString();
      params['user_longitude'] = userLng.toString();
      params['radius_km'] = '25';
    }
    final uri = Uri.parse(
      '$_baseUrl/events/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => AppEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load events');
  }

  static Future<List<Organization>> getOrganizations({
    int? cityId,
    double? userLat,
    double? userLng,
    int? categoryId,
  }) async {
    final params = <String, String>{};
    if (cityId != null) params['city_id'] = cityId.toString();
    if (userLat != null && userLng != null) {
      params['user_latitude'] = userLat.toString();
      params['user_longitude'] = userLng.toString();
      params['radius_km'] = '25';
    }
    if (categoryId != null) params['category_id'] = categoryId.toString();
    final uri = Uri.parse(
      '$_baseUrl/organizations/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final orgs = (jsonDecode(response.body) as List<dynamic>)
          .map((e) => Organization.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort: promoted first (top > featured > highlighted), then by rating.
      int promoRank(String? type) => switch (type) {
        'top' => 3,
        'featured' => 2,
        'highlighted' => 1,
        _ => 0,
      };
      orgs.sort((a, b) {
        final pd = promoRank(b.promotionType) - promoRank(a.promotionType);
        if (pd != 0) return pd;
        return b.averageRating.compareTo(a.averageRating);
      });
      return orgs;
    }
    _handleError(response);
    throw Exception('Failed to load organizations');
  }

  // ── Favorites ──────────────────────────────────────────────────────────────

  static Future<List<Favorite>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/favorites/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load favorites');
  }

  static Future<Favorite> addFavorite(String classId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/favorites/'),
      headers: headers,
      body: jsonEncode({
        'entity_type': 'class',
        'entity_id': int.parse(classId),
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Favorite.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add favorite');
  }

  static Future<Favorite> addOrgFavorite(String orgId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/favorites/'),
      headers: headers,
      body: jsonEncode({
        'entity_type': 'organization',
        'entity_id': int.parse(orgId),
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Favorite.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add favorite');
  }

  static Future<Favorite> addEventFavorite(String eventId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/favorites/'),
      headers: headers,
      body: jsonEncode({
        'entity_type': 'event',
        'entity_id': int.parse(eventId),
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Favorite.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add favorite');
  }

  static Future<void> removeFavorite(String favoriteId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/favorites/$favoriteId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove favorite');
    }
  }

  // ── Conversations ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createConversation(
    int organizationId,
  ) async {
    final headers = await _authHeaders();
    print(
      '[API] createConversation → POST /conversations/ body: {organization_id: $organizationId}',
    );
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/'),
      headers: headers,
      body: jsonEncode({'organization_id': organizationId}),
    );
    print(
      '[API] createConversation ← status: ${response.statusCode} body: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create conversation');
  }

  static Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load conversations');
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/conversation/$conversationId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load messages');
  }

  static Future<ChatMessage> sendMessage(
    String conversationId,
    String content,
  ) async {
    final headers = await _authHeaders();
    final payload = {
      'conversation_id': int.parse(conversationId),
      'message_text': content,
    };
    print('[API] sendMessage → POST /messages/ body: $payload');
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    print(
      '[API] sendMessage ← status: ${response.statusCode} body: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChatMessage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to send message');
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  static Future<List<AppNotification>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load notifications');
  }

  static Future<void> markNotificationRead(String id) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  // ── User ───────────────────────────────────────────────────────────────────

  static Future<UserProfile> getMe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response);
    throw Exception('Failed to load profile');
  }

  static Future<UserProfile> updateMe({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final response = await http.patch(
      Uri.parse('$_baseUrl/me'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to update profile');
  }

  static Future<void> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'password': password,
        'provider': 'email',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception((body['detail'] ?? 'Registration failed').toString());
    }
  }

  // ── Organizations ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getOrganization(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$id'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load organization');
  }

  static Future<List<Map<String, dynamic>>> getMyOrganizations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/my'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load organizations');
  }

  /// Probes the invite-codes endpoint to determine admin access.
  /// Returns true (owner/admin), false (member), or null (network/auth error).
  static Future<bool?> checkIsAdminOrOwner(String orgId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/organizations/$orgId/invite-codes'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) return true;
      if (response.statusCode == 403) return false;
      _handleError(response);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Organization members ──────────────────────────────────────────────────────

  static Future<List<OrgMember>> getOrgMembers(String orgId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$orgId/members'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => OrgMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load members');
  }

  static Future<void> updateMemberRole(
    String orgId,
    int userId,
    String role,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/organizations/$orgId/members/$userId/role'),
      headers: await _authHeaders(),
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode == 200) return;
    _handleError(response);
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Failed to update member role');
  }

  static Future<void> removeMember(String orgId, int userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/organizations/$orgId/members/$userId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return;
    _handleError(response);
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Failed to remove member');
  }

  static Future<List<Map<String, dynamic>>> getOrgClasses(String orgId) async {
    final uri = Uri.parse(
      '$_baseUrl/classes/',
    ).replace(queryParameters: {'organization_id': orgId});
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load org classes');
  }

  static Future<List<Map<String, dynamic>>> getOrgEvents(String orgId) async {
    final uri = Uri.parse(
      '$_baseUrl/events/',
    ).replace(queryParameters: {'organization_id': orgId, 'include_past': 'true'});
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load org events');
  }

  static Future<List<Map<String, dynamic>>> getPublicOrgEvents(String orgId) async {
    final uri = Uri.parse(
      '$_baseUrl/events/',
    ).replace(queryParameters: {'organization_id': orgId});
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load org events');
  }

  static Future<List<Map<String, dynamic>>> getSeriesOccurrences(
    int seriesId, {
    int? organizationId,
    bool includePast = false,
  }) async {
    final params = <String, String>{'series_id': seriesId.toString()};
    if (organizationId != null) params['organization_id'] = organizationId.toString();
    if (includePast) params['include_past'] = 'true';
    final uri = Uri.parse('$_baseUrl/events/').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load series occurrences');
  }

  static Future<List<Map<String, dynamic>>> getAllGroups() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load groups');
  }

  static Future<List<Map<String, dynamic>>> getGroupsByClass(
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/class/$classId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load groups');
  }

  static Future<List<Map<String, dynamic>>> getGroupSchedules(
    String groupId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/group-schedules/group/$groupId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load schedules');
  }

  // ── Create class / group / schedule ────────────────────────────────────────

  static Future<Map<String, dynamic>> createClass({
    required int organizationId,
    List<int>? categoryIds,
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'organization_id': organizationId,
      'name': name,
    };
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['category_ids'] = categoryIds;
    }
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    final response = await http.post(
      Uri.parse('$_baseUrl/classes/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create class');
  }

  static Future<Map<String, dynamic>> createGroup({
    required int classId,
    required String name,
    int? ageFrom,
    int? ageTo,
    int? capacity,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'class_id': classId, 'name': name};
    if (ageFrom != null) body['age_from'] = ageFrom;
    if (ageTo != null) body['age_to'] = ageTo;
    if (capacity != null) body['capacity'] = capacity;
    final response = await http.post(
      Uri.parse('$_baseUrl/groups/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create group');
  }

  static Future<void> createGroupSchedule({
    required int groupId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'group_id': groupId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
    final response = await http.post(
      Uri.parse('$_baseUrl/group-schedules/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create schedule');
    }
  }

  static Future<Map<String, dynamic>> createOrganization({
    required String name,
    String? description,
    String? phone,
    String? email,
    String? website,
    String? address,
    int? cityId,
    List<int>? categoryIds,
    String? instagramUrl,
    String? facebookUrl,
    String? telegramUrl,
    String? youtubeUrl,
    String? tiktokUrl,
    String? whatsappUrl,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'name': name};
    if (categoryIds != null && categoryIds.isNotEmpty)
      body['category_ids'] = categoryIds;
    if (description != null && description.isNotEmpty)
      body['description'] = description;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (website != null && website.isNotEmpty) body['website'] = website;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (cityId != null) body['city_id'] = cityId;
    if (instagramUrl != null && instagramUrl.isNotEmpty)
      body['instagram_url'] = instagramUrl;
    if (facebookUrl != null && facebookUrl.isNotEmpty)
      body['facebook_url'] = facebookUrl;
    if (telegramUrl != null && telegramUrl.isNotEmpty)
      body['telegram_url'] = telegramUrl;
    if (youtubeUrl != null && youtubeUrl.isNotEmpty)
      body['youtube_url'] = youtubeUrl;
    if (tiktokUrl != null && tiktokUrl.isNotEmpty)
      body['tiktok_url'] = tiktokUrl;
    if (whatsappUrl != null && whatsappUrl.isNotEmpty)
      body['whatsapp_url'] = whatsappUrl;
    final response = await http.post(
      Uri.parse('$_baseUrl/organizations/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create organization');
  }

  static Future<Map<String, dynamic>> updateClass({
    required int classId,
    String? name,
    String? description,
    List<int>? categoryIds,
    String? imageUrl,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['category_ids'] = categoryIds;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    final response = await http.put(
      Uri.parse('$_baseUrl/classes/$classId'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update class');
  }

  static Future<void> deleteClass(int classId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/classes/$classId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete class');
    }
  }

  static Future<Map<String, dynamic>> updateEvent(
    int eventId, {
    String? title,
    String? description,
    String? startDatetime,
    int? categoryId,
    List<int>? categoryIds,
    int? minAge,
    int? maxAge,
    int? capacity,
    String? address,
    int? cityId,
    bool? isNationwide,
    double? price,
    String? priceComment,
    String? imageUrl,
    String? scope,
    RecurrenceInput? recurrence,
    bool removeRecurrence = false,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (startDatetime != null) body['start_datetime'] = startDatetime;
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['category_ids'] = categoryIds;
    } else if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (minAge != null) body['min_age'] = minAge;
    if (maxAge != null) body['max_age'] = maxAge;
    if (capacity != null) body['capacity'] = capacity;
    if (address != null) body['address'] = address;
    if (cityId != null) body['city_id'] = cityId;
    if (isNationwide != null) body['is_nationwide'] = isNationwide;
    if (price != null) body['price'] = price;
    if (priceComment != null) body['price_comment'] = priceComment;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    if (recurrence != null) {
      body['recurrence'] = recurrence.toJson();
    } else if (removeRecurrence) {
      body['recurrence'] = null; // explicit null tells backend to remove recurrence
    }
    final uri = Uri.parse(
      '$_baseUrl/events/$eventId',
    ).replace(queryParameters: scope != null ? {'scope': scope} : null);
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update event');
  }

  static Future<void> deleteEvent(int eventId, {String? scope}) async {
    final uri = Uri.parse(
      '$_baseUrl/events/$eventId',
    ).replace(queryParameters: scope != null ? {'scope': scope} : null);
    final response = await http.delete(uri, headers: await _authHeaders());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }

  static Future<Map<String, dynamic>> createReview({
    required int organizationId,
    required int rating,
    String? comment,
    List<String>? photoUrls,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'organization_id': organizationId,
      'rating': rating,
    };
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    if (photoUrls != null && photoUrls.isNotEmpty)
      body['photo_urls'] = photoUrls;
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 400) {
      throw Exception('already_reviewed');
    }
    throw Exception('Failed to submit review');
  }

  static Future<AppEvent> getEvent(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/events/$id'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return AppEvent.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load event');
  }

  static Future<List<Map<String, dynamic>>> getReviews(
    int organizationId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/organization/$organizationId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('Failed to load reviews');
  }

  static Future<Map<String, dynamic>> updateOrganization(
    int id, {
    String? name,
    String? description,
    String? email,
    String? phone,
    String? website,
    String? address,
    int? cityId,
    List<int>? categoryIds,
    String? instagramUrl,
    String? facebookUrl,
    String? telegramUrl,
    String? youtubeUrl,
    String? tiktokUrl,
    String? whatsappUrl,
    String? logoUrl,
    String? bannerUrl,
    bool? trialLessonAvailable,
    double? trialLessonPrice,
    String? trialLessonComment,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (categoryIds != null && categoryIds.isNotEmpty)
      body['category_ids'] = categoryIds;
    if (description != null) body['description'] = description;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (website != null) body['website'] = website;
    if (address != null) body['address'] = address;
    if (cityId != null) body['city_id'] = cityId;
    if (instagramUrl != null) body['instagram_url'] = instagramUrl;
    if (facebookUrl != null) body['facebook_url'] = facebookUrl;
    if (telegramUrl != null) body['telegram_url'] = telegramUrl;
    if (youtubeUrl != null) body['youtube_url'] = youtubeUrl;
    if (tiktokUrl != null) body['tiktok_url'] = tiktokUrl;
    if (whatsappUrl != null) body['whatsapp_url'] = whatsappUrl;
    if (logoUrl != null) body['logo_url'] = logoUrl;
    if (bannerUrl != null) body['banner_url'] = bannerUrl;
    if (trialLessonAvailable != null)
      body['trial_lesson_available'] = trialLessonAvailable;
    if (trialLessonPrice != null) body['trial_lesson_price'] = trialLessonPrice;
    if (trialLessonComment != null)
      body['trial_lesson_comment'] = trialLessonComment;
    final response = await http.put(
      Uri.parse('$_baseUrl/organizations/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update organization');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 400) {
      final detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail'];
      throw Exception(detail?.toString() ?? 'Failed to change password');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to change password');
    }
  }

  // ── Organization photos ────────────────────────────────────────────────────

  static Future<List<OrgPhoto>> getOrgPhotos(String orgId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$orgId/photos'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => OrgPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load photos');
  }

  static Future<OrgPhoto> addOrgPhoto(String orgId, String photoUrl) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/organizations/$orgId/photos'),
      headers: headers,
      body: jsonEncode({'photo_url': photoUrl}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrgPhoto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add photo');
  }

  static Future<void> deleteOrgPhoto(String orgId, String photoId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/organizations/$orgId/photos/$photoId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete photo');
    }
  }

  static Future<void> deleteOrganization(String orgId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/organizations/$orgId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete organization');
    }
  }

  // ── Organization invites ──────────────────────────────────────────────────────

  static Future<InviteCodeResolveResult> resolveInviteCode(String code) async {
    final uri = Uri.parse(
      '$_baseUrl/invite-codes/resolve',
    ).replace(queryParameters: {'code': code});
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return InviteCodeResolveResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response);
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Invalid invite code');
  }

  static Future<List<OrgInviteCode>> getInviteCodes(String orgId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$orgId/invite-codes'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => OrgInviteCode.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load invite codes');
  }

  static Future<OrgInviteCode> createInviteCode(
    String orgId, {
    String defaultRole = 'member',
    bool requiresApproval = true,
    DateTime? expiresAt,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'default_role': defaultRole,
      'requires_approval': requiresApproval,
    };
    if (expiresAt != null)
      body['expires_at'] = expiresAt.toUtc().toIso8601String();
    final response = await http.post(
      Uri.parse('$_baseUrl/organizations/$orgId/invite-codes'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrgInviteCode.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response);
    throw Exception('Failed to create invite code');
  }

  static Future<OrgInviteCode> deactivateInviteCode(
    String orgId,
    int codeId,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/organizations/$orgId/invite-codes/$codeId/deactivate',
      ),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return OrgInviteCode.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response);
    throw Exception('Failed to deactivate invite code');
  }

  static Future<JoinResult> submitJoinRequest(String orgId, String code) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/organizations/$orgId/join-requests'),
      headers: headers,
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return JoinResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response);
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Failed to submit join request');
  }

  static Future<List<OrgJoinRequest>> getJoinRequests(String orgId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/organizations/$orgId/join-requests'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => OrgJoinRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _handleError(response);
    throw Exception('Failed to load join requests');
  }

  static Future<void> approveJoinRequest(String orgId, int requestId) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/organizations/$orgId/join-requests/$requestId/approve',
      ),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleError(response);
      throw Exception('Failed to approve join request');
    }
  }

  static Future<void> rejectJoinRequest(String orgId, int requestId) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/organizations/$orgId/join-requests/$requestId/reject',
      ),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleError(response);
      throw Exception('Failed to reject join request');
    }
  }

  static Future<Map<String, dynamic>> createEvent({
    required int organizationId,
    required String title,
    required String startDatetime,
    int? categoryId,
    List<int>? categoryIds,
    String? description,
    int? minAge,
    int? maxAge,
    int? capacity,
    String? address,
    int? cityId,
    bool isNationwide = false,
    double? price,
    String? priceComment,
    String? imageUrl,
    RecurrenceInput? recurrence,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'organization_id': organizationId,
      'title': title,
      'start_datetime': startDatetime,
      'is_nationwide': isNationwide,
    };
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['category_ids'] = categoryIds;
    } else if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (description != null && description.isNotEmpty)
      body['description'] = description;
    if (minAge != null && minAge > 0) body['min_age'] = minAge;
    if (maxAge != null && maxAge < 99) body['max_age'] = maxAge;
    if (capacity != null) body['capacity'] = capacity;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (cityId != null) body['city_id'] = cityId;
    if (price != null) body['price'] = price;
    if (priceComment != null && priceComment.isNotEmpty)
      body['price_comment'] = priceComment;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
    if (recurrence != null) body['recurrence'] = recurrence.toJson();
    final response = await http.post(
      Uri.parse('$_baseUrl/events/'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create event');
  }
}
