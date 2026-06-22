import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

/// Типы ошибок сервиса
enum ServiceErrorType {
  network,
  notFound,
  serverError,
  unknown,
}

class ServiceError {
  final ServiceErrorType type;
  final String message;

  ServiceError(this.type, this.message);

  @override
  String toString() => message;
}

class GoogleDriveService {
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbzc87eJ06ULddphi6My81KuHtCGwl7UO8EjJfVAX4_vh8Qm7pylgRpyVZOCOKG3RW3C/exec';

  Future<void> initialize() async {
    // Apps Script backend — no OAuth needed
  }

  // ─── ПОЛЬЗОВАТЕЛИ ───────────────────────────────────────────

  Future<User?> getUserFromSheet(String userId) async {
    try {
      final users = await listUsers();
      if (users == null) return null;
      try {
        return users.firstWhere((u) => u.id == userId);
      } catch (_) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Получить пользователя по email.
  /// Возвращает User или бросает ServiceError.
  Future<User> getUserByEmail(String email) async {
    try {
      // Пробуем прямой запрос
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'getUserByEmail',
          'email': email,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body.isNotEmpty && !body.startsWith('error')) {
        try {
          final jsonData = jsonDecode(body);
          if (jsonData is Map<String, dynamic>) {
            return User.fromJson(jsonData);
          }
        } catch (_) {
          // Невалидный JSON — пробуем fallback
        }
      }

      // Fallback: загрузить всех и найти по email
      final users = await listUsers();
      if (users != null) {
        final normalizedEmail = email.trim().toLowerCase();
        try {
          return users.firstWhere(
            (u) => u.email.trim().toLowerCase() == normalizedEmail,
          );
        } catch (_) {
          throw ServiceError(ServiceErrorType.notFound, 'Пользователь не найден');
        }
      }

      throw ServiceError(ServiceErrorType.notFound, 'Пользователь не найден');
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw ServiceError(ServiceErrorType.network, 'Ошибка сети. Проверьте подключение.');
    }
  }

  Future<List<User>?> listUsers() async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {'action': 'listUsers'},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body.isNotEmpty) {
        final jsonData = jsonDecode(body);
        if (jsonData is List) {
          return jsonData
              .whereType<Map<String, dynamic>>()
              .map((e) => User.fromJson(e))
              .toList();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Регистрация нового пользователя.
  /// Возвращает true или бросает ServiceError.
  Future<bool> saveUserToSheet(User user, String password) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'saveUser',
          'email': user.email,
          'name': user.fullName ?? '',
          'description': user.description ?? '',
          'password': password,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200) {
        if (body == 'success') return true;
        if (body == 'exists') {
          throw ServiceError(ServiceErrorType.serverError, 'Пользователь с таким email уже существует');
        }
        if (body.startsWith('error')) {
          throw ServiceError(ServiceErrorType.serverError, 'Ошибка сервера: $body');
        }
      }

      throw ServiceError(ServiceErrorType.serverError, 'Не удалось сохранить пользователя');
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw ServiceError(ServiceErrorType.network, 'Ошибка сети. Проверьте подключение.');
    }
  }

  /// Обновление профиля (name + description).
  Future<bool> updateUserProfile(User user) async {
    final actions = ['updateUser', 'updateuser', 'updateProfile', 'update_profile'];

    for (final action in actions) {
      try {
        final uri = Uri.parse(_scriptUrl).replace(
          queryParameters: {
            'action': action,
            'email': user.email,
            'name': user.fullName ?? '',
            'description': user.description ?? '',
          },
        );

        final response = await http.get(uri).timeout(const Duration(seconds: 15));
        final body = response.body.trim();

        if (response.statusCode == 200 && body == 'success') return true;
        if (response.statusCode == 200 && body.contains('unknown action')) continue;
        if (response.statusCode == 200 && body == 'exists') return false;
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  /// Смена пароля.
  Future<bool> changePassword(String email, String newPasswordHash) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'changePassword',
          'email': email,
          'passwordHash': newPasswordHash,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body == 'success') return true;

      // Fallback: если бэкенд не поддерживает changePassword,
      // обновляем профиль с новым хэшем через updateUser
      final fallbackActions = ['updatePassword', 'updatepassword'];
      for (final action in fallbackActions) {
        final fallbackUri = Uri.parse(_scriptUrl).replace(
          queryParameters: {
            'action': action,
            'email': email,
            'passwordHash': newPasswordHash,
          },
        );
        final fallbackResponse = await http.get(fallbackUri).timeout(const Duration(seconds: 15));
        if (fallbackResponse.statusCode == 200 && fallbackResponse.body.trim() == 'success') {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Удаление аккаунта.
  Future<bool> deleteAccount(String email) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'deleteUser',
          'email': email,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body == 'success') return true;

      // Fallback actions
      final fallbackActions = ['deleteuser', 'removeUser', 'removeuser'];
      for (final action in fallbackActions) {
        final fallbackUri = Uri.parse(_scriptUrl).replace(
          queryParameters: {
            'action': action,
            'email': email,
          },
        );
        final fallbackResponse = await http.get(fallbackUri).timeout(const Duration(seconds: 15));
        if (fallbackResponse.statusCode == 200 && fallbackResponse.body.trim() == 'success') {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── ДАННЫЕ ПОЛЬЗОВАТЕЛЯ ───────────────────────────────────

  Future<bool> addDataToSheet(String userId, List<String> data) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'addData',
          'userId': userId,
          'data': data.join('|'),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body == 'success') return true;

      // Fallback actions
      final fallbackActions = ['adddata', 'saveData', 'savedata'];
      for (final action in fallbackActions) {
        final fallbackUri = Uri.parse(_scriptUrl).replace(
          queryParameters: {
            'action': action,
            'userId': userId,
            'data': data.join('|'),
          },
        );
        final fallbackResponse = await http.get(fallbackUri).timeout(const Duration(seconds: 15));
        if (fallbackResponse.statusCode == 200 && fallbackResponse.body.trim() == 'success') {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<List<dynamic>>?> getUserData(String userId) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'getUserData',
          'userId': userId,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = response.body.trim();

      if (response.statusCode == 200 && body.isNotEmpty) {
        final jsonData = jsonDecode(body);
        if (jsonData is List) {
          return jsonData.map((row) => (row as List).toList()).toList();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteData(String userId, int rowIndex) async {
    try {
      final uri = Uri.parse(_scriptUrl).replace(
        queryParameters: {
          'action': 'deleteData',
          'userId': userId,
          'rowIndex': rowIndex.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 && response.body.trim() == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    // Nothing to do for Apps Script backend
  }
}
