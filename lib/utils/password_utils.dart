import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordUtils {
  /// Хэширование пароля (SHA-256)
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Проверка пароля (сравнение хешей)
  static bool verifyPassword(String password, String hash) {
    final computed = hashPassword(password);
    return computed == hash;
  }

  /// Валидация пароля (минимум 6 символов)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Валидация email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
