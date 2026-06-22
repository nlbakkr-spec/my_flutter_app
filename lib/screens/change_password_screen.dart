import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/password_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text.trim(),
      confirmNewPassword: _confirmPasswordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Пароль успешно изменён'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error = authService.error ?? 'Ошибка при смене пароля';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        elevation: 0,
        title: Text(
          'Смена пароля',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Введите текущий пароль и задайте новый (минимум 6 символов)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Форма
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Текущий пароль',
                      hint: 'Введите текущий пароль',
                      controller: _currentPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Введите текущий пароль';
                        }
                        return null;
                      },
                    ),

                    CustomTextField(
                      label: 'Новый пароль',
                      hint: 'Минимум 6 символов',
                      controller: _newPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Введите новый пароль';
                        }
                        if (!PasswordUtils.isValidPassword(value!.trim())) {
                          return 'Пароль должен быть минимум 6 символов';
                        }
                        return null;
                      },
                    ),

                    CustomTextField(
                      label: 'Подтвердите новый пароль',
                      hint: 'Повторите новый пароль',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Подтвердите пароль';
                        }
                        if (value!.trim() != _newPasswordController.text.trim()) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Consumer<AuthService>(
                      builder: (context, authService, _) {
                        return CustomButton(
                          text: 'Сменить пароль',
                          isLoading: _isLoading,
                          onPressed: _handleChangePassword,
                          backgroundColor: Colors.blue.shade600,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
