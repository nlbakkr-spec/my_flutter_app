import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/password_utils.dart';
import 'google_drive_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  final GoogleDriveService _driveService = GoogleDriveService();

  // ─── ИНИЦИАЛИЗАЦИЯ ───────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driveService.initialize();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final user = await _driveService.getUserFromSheet(userId);
        if (user != null) {
          _currentUser = user;
        } else {
          await prefs.remove('userId');
        }
      }

      _isInitialized = true;
    } catch (e) {
      _error = 'Ошибка инициализации';
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── РЕГИСТРАЦИЯ ────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Валидация
      if (!PasswordUtils.isValidEmail(email)) {
        throw 'Некорректный email';
      }
      if (!PasswordUtils.isValidPassword(password)) {
        throw 'Пароль должен быть минимум 6 символов';
      }
      if (password != confirmPassword) {
        throw 'Пароли не совпадают';
      }

      final userId = const Uuid().v4();
      final passwordHash = PasswordUtils.hashPassword(password);

      final newUser = User(
        id: userId,
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
        createdAt: DateTime.now(),
        fullName: fullName?.trim().isNotEmpty == true ? fullName!.trim() : null,
        description: null,
      );

      final saved = await _driveService.saveUserToSheet(newUser, password);
      if (!saved) {
        throw 'Ошибка при сохранении пользователя';
      }

      _currentUser = newUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── ЛОГИН ──────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!PasswordUtils.isValidEmail(email)) {
        throw 'Некорректный email';
      }

      final user = await _driveService.getUserByEmail(email.trim());

      // Проверка пароля
      if (!PasswordUtils.verifyPassword(password, user.passwordHash)) {
        throw 'Неверный email или пароль';
      }

      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Единое сообщение чтобы не было перебора
      if (e.toString().contains('сети') || e.toString().contains('network')) {
        _error = 'Ошибка сети. Проверьте подключение к интернету.';
      } else {
        _error = 'Неверный email или пароль';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── ОБНОВЛЕНИЕ ПРОФИЛЯ ────────────────────────────────────

  Future<bool> updateProfile({String? fullName, String? description}) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        description: description,
        clearFullName: fullName != null && fullName.trim().isEmpty,
        clearDescription: description != null && description.trim().isEmpty,
      );

      final success = await _driveService.updateUserProfile(updatedUser);
      if (!success) {
        throw 'Не удалось сохранить профиль';
      }

      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── СМЕНА ПАРОЛЯ ──────────────────────────────────────────

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Проверяем текущий пароль
      if (!PasswordUtils.verifyPassword(currentPassword, _currentUser!.passwordHash)) {
        throw 'Текущий пароль неверный';
      }

      if (!PasswordUtils.isValidPassword(newPassword)) {
        throw 'Новый пароль должен быть минимум 6 символов';
      }

      if (newPassword != confirmNewPassword) {
        throw 'Пароли не совпадают';
      }

      final newHash = PasswordUtils.hashPassword(newPassword);
      final success = await _driveService.changePassword(_currentUser!.email, newHash);

      if (!success) {
        throw 'Не удалось сменить пароль';
      }

      // Обновляем хэш локально
      _currentUser = _currentUser!.copyWith(passwordHash: newHash);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── УДАЛЕНИЕ АККАУНТА ─────────────────────────────────────

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _driveService.deleteAccount(_currentUser!.email);
      if (!success) {
        throw 'Не удалось удалить аккаунт';
      }

      await logout();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── ЛОГАУТ ─────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    try {
      await _driveService.signOut();
    } catch (_) {}

    notifyListeners();
  }

  // ─── ОЧИСТКА ОШИБКИ ────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
