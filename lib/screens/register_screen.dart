import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/password_utils.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Необходимо принять условия'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
      fullName: _fullNameController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Аккаунт создан! Добро пожаловать!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(authService.error ?? 'Ошибка регистрации')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Назад
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Создать аккаунт',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Заполните данные для регистрации',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email
                      CustomTextField(
                        label: 'Email',
                        hint: 'example@mail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Email не может быть пустым';
                          }
                          if (!PasswordUtils.isValidEmail(value!.trim())) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),

                      // Имя
                      CustomTextField(
                        label: 'Полное имя',
                        hint: 'Введите ваше имя',
                        controller: _fullNameController,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),

                      // Пароль
                      CustomTextField(
                        label: 'Пароль',
                        hint: 'Минимум 6 символов',
                        controller: _passwordController,
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Пароль не может быть пустым';
                          }
                          if (!PasswordUtils.isValidPassword(value!.trim())) {
                            return 'Пароль должен быть минимум 6 символов';
                          }
                          return null;
                        },
                      ),

                      // Подтверждение
                      CustomTextField(
                        label: 'Подтвердите пароль',
                        hint: 'Повторите пароль',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Подтвердите пароль';
                          }
                          if (value!.trim() != _passwordController.text.trim()) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // Принять условия
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                              child: Text(
                                'Я принимаю условия использования',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Кнопка
                      Consumer<AuthService>(
                        builder: (context, authService, _) {
                          return CustomButton(
                            text: 'Создать аккаунт',
                            isLoading: authService.isLoading,
                            onPressed: () => _handleRegister(context),
                            backgroundColor: Colors.blue.shade600,
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Логин
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: TextSpan(
                              text: 'Уже есть аккаунт? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Войти',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
